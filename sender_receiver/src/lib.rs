use std::net;
use pnet::datalink;
use pnet::packet::ip::IpNextHeaderProtocols;
use pnet::packet::ipv4;
use std::error::Error;
use std::thread;
use pnet::packet::ethernet;
use pnet::util::MacAddr;
use rand::prelude::*;
use std::time::{Duration, Instant};
use std::env;
use std::fs::OpenOptions;
use std::io::{Write, BufReader};
use std::time;
use toml::Value;
use std::fs::File;

// Constants used by the program
const MTU: usize = 1500;
const EMPTY_PKT: [u8; MTU] = [0; MTU];
const SAFETY_BUFFER: f64 = 0.0;
const ETH_HEADER_LEN: usize = 14;
const IP_HEADER_LEN: usize = 20;
const MIN_PAYLOAD_LEN: usize = 9; // Seq number (8 bytes) + flow (1 byte)
const VPN_HEADER_LEN: usize = 80;
const IP_SRC_ADDR_OFFSET: usize = 12;
const IP_DST_ADDR_OFFSET: usize = 16;
const IP_ADDR_LEN: usize = 4;
const IP_VERSION: u8 = 4;
const TOFINO_OVERHEAD: usize = 100;
const MAX_PAD_LEN: usize = 254;
const AVG_CAIDA_LEN: f64 = 900.0;
const AVG_VIDEO_LEN: f64 = 190.0;
const AVG_WEB_LEN: f64 = 1064.0;
const FACTOR_MEGABITS: f64 = 1e6;
const BITS_PER_BYTE: f64 = 8.0;
const WRAP_AND_WIREGUARD_OVERHAD: f64 = 100.0;

/// Struct to hold the necessary channel information for the different threads.
/// A channel for sending, a channel for receiving, and a mac address to filter traffic.
pub struct ChannelCustom {
    pub tx: Box<dyn datalink::DataLinkSender>,
    pub rx: Box<dyn datalink::DataLinkReceiver>,
    pub mac_addr: Option<pnet::util::MacAddr>,
}

/// Struct to hold the necessary channel information for the sender thread.
/// Packets per second, addresses, number of packets, whether to save, the flow number, the dataset to use, as well as the minimum and maximum packet length.
struct SenderConfig {
    pps: f64,
    ip_src: [u8;4], 
    ip_dst: [u8;4], 
    num_pkts: usize, 
    save_data: bool, 
    flow: u8, 
    dataset: String, 
    min_pkt_length: usize, 
    max_pkt_length: usize,
}

/// Struct to hold the necessary channel information for the receiver thread.
/// Source addresses, and whether to save the data.
struct ReceiverConfig {
    ip_src: [u8;4], 
    save_data: bool, 
}


/// Main entry point of the program. Starts all thread and functions necessary for running a sender or a receiver.
pub fn run(settings: Value) -> Result<(), Box<dyn Error>> {
    // Flow is 0 if none specified
    let flow = match get_env_var_f64("FLOW") {
        Ok(f) => f as u8,
        Err(_) => 0_u8,
    };

    // Get configuration from toml file
    let rate = settings["general"]["rate"].as_float().expect("Rate setting not found");
    let sending_time = settings["general"]["time"].as_float().expect("Sending time setting not found");
    let save_data = settings["general"]["save"].as_bool().expect("Save setting not found");
    let is_sender = settings["general"]["send"].as_bool().expect("Send setting not found");
    let is_receiver = settings["general"]["receive"].as_bool().expect("Receive setting not found");
    let is_log = settings["general"]["log"].as_bool().expect("Is log setting not found");
    let dataset = settings["general"]["dataset"].as_str().expect("Dataset setting not found").to_string();

    // Get length constraints on the packets to be sent
    let avg_len;
    let min_pkt_length = settings["general"]["min_pkt_length"].as_integer().expect("Min pkt length setting not found") as usize;
    let max_pkt_length = settings["general"]["max_pkt_length"].as_integer().expect("Max pkt length setting not found") as usize;

    // Get the average packet length based on the dataset used
    if dataset == "" {
        // Uniformly distributed data
        let max_len = (MTU - IP_HEADER_LEN - VPN_HEADER_LEN) as f64;
        let min_len = (IP_HEADER_LEN + MIN_PAYLOAD_LEN) as f64;
        avg_len = (max_len + min_len) / 2.0 + WRAP_AND_WIREGUARD_OVERHAD;  
        println!("Average packet length of {}B", avg_len);
    } else if dataset == "caida" {
        avg_len = AVG_CAIDA_LEN + WRAP_AND_WIREGUARD_OVERHAD;
    } else if dataset == "video" {
        avg_len = AVG_VIDEO_LEN + WRAP_AND_WIREGUARD_OVERHAD;
    } else if dataset == "web" {
        avg_len = AVG_WEB_LEN + WRAP_AND_WIREGUARD_OVERHAD;
    }else {
        panic!("Could not set average length");
    }

    // Compute the number of packets per second needed based on the rate and the average packet length
    let pps = rate / avg_len * FACTOR_MEGABITS / BITS_PER_BYTE;
    let num_pkts = (pps * sending_time) as usize;
    println!("Sending {}pkts at {}pps", num_pkts, pps);

    // Get source and destination address
    let ip_src = parse_ip(settings["ip"]["src"].as_str().expect("Src ip address not found").to_string());
    let ip_dst = parse_ip(settings["ip"]["dst"].as_str().expect("Dst ip address not found").to_string());
    
    // Get isolation information
    let is_send_isolated = settings["isolation"]["isolate_sender"].as_bool().expect("Isolate send setting not found");  
    let core_id_send = settings["isolation"]["core_sender"].as_integer().expect("Core send setting not found") as usize;
    let is_receive_isolated = settings["isolation"]["isolate_receiver"].as_bool().expect("Isolate receive setting not found");     
    let core_id_receive = settings["isolation"]["core_receiver"].as_integer().expect("Core receive setting not found") as usize;
    let priority = settings["isolation"]["priority"].as_integer().expect("Thread priority setting not found") as i32; 
    let input = settings["interface"]["input"].as_str().expect("Input interface setting not found").to_string(); 
    let output = settings["interface"]["output"].as_str().expect("Output interface setting not found").to_string(); 

    // Show more debug information if needed
    if is_log {
        println!("Sending Ethernet frames on interface {}...", input);
        println!("Receiving Ethernet frames on interface {}...", output);
        println!("Sending on specific cores = {}", is_send_isolated);    
    }
    
    // Spawn thread for receiving packets
    if is_receiver && rate > 0.0 {
        let recv_handle = thread::spawn(move || {
            if is_receive_isolated {
                unsafe {
                    let mut cpuset: libc::cpu_set_t = std::mem::zeroed();
                    libc::CPU_SET(core_id_receive, &mut cpuset);
                    libc::sched_setaffinity(0, std::mem::size_of_val(&cpuset), &cpuset);

                    let thread =  libc::pthread_self();
                    let param = libc::sched_param { sched_priority: priority };
                    let result = libc::pthread_setschedparam(thread, libc::SCHED_FIFO, &param as *const libc::sched_param);
                    if result != 0 {
                        panic!("Failed to set thread priority");
                    }
                }
            }
            let config = ReceiverConfig {
                ip_src, 
                save_data, 
            };
            receive(&output, config);
        });

        recv_handle.join().expect("Receiving thread panicked");
    }

    // Spawn thread for sending packets
    if is_sender && rate > 0.0 {
        let send_handle = thread::spawn(move || {
            if is_send_isolated {
                unsafe {
                    let mut cpuset: libc::cpu_set_t = std::mem::zeroed();
                    libc::CPU_SET(core_id_send, &mut cpuset);
                    libc::sched_setaffinity(0, std::mem::size_of_val(&cpuset), &cpuset);

                    let thread =  libc::pthread_self();
                    let param = libc::sched_param { sched_priority: priority };
                    let result = libc::pthread_setschedparam(thread, libc::SCHED_FIFO, &param as *const libc::sched_param);
                    if result != 0 {
                        panic!("Failed to set thread priority");
                    }
                }
            }

            let config = SenderConfig {
                pps,
                ip_src, 
                ip_dst, 
                num_pkts, 
                save_data, 
                flow, 
                dataset, 
                min_pkt_length, 
                max_pkt_length,
            };

            send(&input, config);
        });
        // Wait 1s before starting to send to make sure the receiver starts first if both are being run
        thread::sleep(Duration::new(1, 0));
        send_handle.join().expect("Sending thread panicked");
    }

    Ok(())
}

// Retrieve the network interface and its mac address.
fn get_channel(interface_name: &str) -> Result<ChannelCustom, &'static str>{
    // Retrieve the network interface
    let interfaces = datalink::interfaces();
    let interface = match interfaces
        .into_iter()
        .find(|iface| iface.name == interface_name) {
            Some(inter) => inter,
            None => return Err("Failed to find network interface"),
        };

    let mac_addr = interface.mac;

    // Create a channel to receive Ethernet frames
    let (tx, rx) = match datalink::channel(&interface, Default::default()) {
        Ok(datalink::Channel::Ethernet(tx, rx)) => (tx, rx),
        Ok(_) => return Err("Unknown channel type"),
        Err(e) => panic!("Failed to create channel {e}"),
    };

    let ch = ChannelCustom{ 
        tx, 
        rx,
        mac_addr,
    };

    Ok(ch)
}

// Function to send packets on the network.
fn send(input: &str, config: SenderConfig) {
    // Get the channel to transmit on and its mac address
    let mut ch_tx = match get_channel(input) {
        Ok(tx) => tx,
        Err(error) => panic!("Error getting channel: {error}"),
    };
    let mac_addr = ch_tx.mac_addr.unwrap();

    // File to save data in if needed. The file is reset when new data needs to be saved
    let mut file = OpenOptions::new()
        .write(true)
        .truncate(config.save_data) // Overwrite
        .create(true)
        .open(format!("tx_data_{}.csv", config.flow))
        .expect("Could not open file");

    if config.save_data {
        writeln!(file, "Seq,Time,Flow").expect("Failed to write to file");
    }

    // Get the lengths of the packets and prepare data structures to store the timestamps at which the packets are sent
    // How to determine the packet lengths depends on the dataset used
    let mut count: usize = 0;
    let delays = vec![0; 1e6 as usize];
    let lengths;
    if config.dataset == "caida" {
        let filename = "../traces/caida_lengths.csv";
        lengths = get_lengths_from_file(filename, config.num_pkts);
    } else if config.dataset == "video" {
        let filename = "../traces/video_lengths.csv";
        lengths = get_lengths_from_file(filename, config.num_pkts);
    } else if config.dataset == "web" {
        let filename = "../traces/web_lengths.csv";
        lengths = get_lengths_from_file(filename, config.num_pkts);
    } else {
        lengths = get_random_pkt_lengths(config.num_pkts, config.min_pkt_length, config.max_pkt_length);
    }

    println!("Sending...");
    let interval = Duration::from_nanos((1e9/config.pps + SAFETY_BUFFER) as u64);
    println!("Sending packets in intervals of {:?}", interval);
    let mut last_iteration_time = Instant::now();

    // Whether packets should be generated and logged on the fly or if they should be generated in advance and logged to a file after being sent
    // When running the sender over 100 Mbps this should be set to true
    let precompute_pkts = true;

    if precompute_pkts {
        let frames = get_all_pkts(config.num_pkts, config.ip_src, config.ip_dst, config.flow, lengths, mac_addr);
        let mut times = Vec::with_capacity(config.num_pkts);
        let mut last_iteration_time = Instant::now();
        for frame in frames {
            match ch_tx.tx.send_to(&frame, None) {
                Some(res) => {
                    match res {
                        Ok(_) => (),
                        Err(e) => eprintln!("Error sending frame: {}", e),
                    }
                }
                None => {
                    eprintln!("No packets to send");
                }
            }

            if config.save_data {
                // Since precomputing, only save to file after done sending to reduce delay
                if count < delays.len() {
                    let current_time = time::SystemTime::now().duration_since(time::UNIX_EPOCH).unwrap();
                    times.push(current_time);
                }
                count += 1;
            } 
            
            // Calculate time to sleep
            let elapsed_time = last_iteration_time.elapsed();
            let sleep_time = if elapsed_time < interval {
                interval - elapsed_time
            } else {
                Duration::new(0, 0)
            };
            // Sleep for the remaining time until the next iteration
            thread::sleep(sleep_time);
            if elapsed_time > interval {
                // println!("Ran out of time processing {:?} at pkt {}", elapsed_time, count);
            }
            last_iteration_time = last_iteration_time + interval;
        }

        count = 1;
        // Save timestamps to file
        for t in times {
            writeln!(file, "{},{},{}", count, t.as_nanos(), config.flow).expect("Failed to write to file");
            count += 1;
        }
    } else {
        while count < config.num_pkts {
            // Get packets on the fly
            let pkt = &mut get_ipv4_packet(config.ip_src, config.ip_dst, config.flow, lengths[count] as usize);
            let frame = &mut get_eth_frame(pkt.to_vec(), mac_addr);
            encode_sequence_num(frame, count+1);
            match ch_tx.tx.send_to(&frame, None) {
                Some(res) => {
                    match res {
                        Ok(_) => (),
                        Err(e) => eprintln!("Error sending frame: {}", e),
                    }
                }
                None => {
                    eprintln!("No packets to send");
                }
            }

            if config.save_data {
                // Log to file
                if count < delays.len() {
                    let current_time = time::SystemTime::now().duration_since(time::UNIX_EPOCH).unwrap();
                    writeln!(file, "{},{},{}", count+1, current_time.as_nanos(), config.flow).expect("Failed to write to file");
                }
                count += 1;
            } else {
                count = (count+1) % config.num_pkts;
            }
            
            // Calculate time to sleep
            let elapsed_time = last_iteration_time.elapsed();
            let sleep_time = if elapsed_time < interval {
                interval - elapsed_time
            } else {
                Duration::new(0, 0)
            };
            // Sleep for the remaining time until the next iteration
            thread::sleep(sleep_time);
            if elapsed_time > interval {
                // println!("Ran out of time processing {:?} at pkt {}", elapsed_time, count);
            }
            last_iteration_time = last_iteration_time + interval;
        }
    }
}

// Function to receive packets from the network
fn receive(output: &str, config: ReceiverConfig) {
    // Channel from which to listen to packets
    let mut ch_rx = match get_channel(output) {
        Ok(rx) => rx,
        Err(error) => panic!("Error getting channel: {error}"),
    };

    // File to save data into. Reset the file at each new run
    let mut file = OpenOptions::new()
        .write(true)
        .truncate(config.save_data) // Overwrite
        .create(true)
        .open("rx_data.csv")
        .expect("Could not open file");

    if config.save_data {
        writeln!(file, "Seq,Time,Flow").expect("Failed to write to file");
    }

    println!("Receiving...");
    loop {
        match ch_rx.rx.next() {
            Ok(pkt) =>  {
                if is_ip_addr_matching(pkt, config.ip_src ,true) { 
                    decode_pkt(pkt, config.save_data, &mut file);
                } else if pkt.len() > MAX_PAD_LEN + ETH_HEADER_LEN+IP_DST_ADDR_OFFSET+IP_ADDR_LEN && 
                is_ip_addr_matching(&pkt[MAX_PAD_LEN..], config.ip_src ,true) {
                    // For hardware recirculated packets do not work so well and this needed to be added to look ahead if the recirculation failed
                    // This should never get triggered if running in software
                    decode_pkt(&pkt[MAX_PAD_LEN..], config.save_data, &mut file);
                }
            },
            Err(e) => {
                eprintln!("Error receiving frame: {}", e);
                continue;
            }
        };
    }
}

// Get an Ethernet frame with the specified source mac address
fn get_eth_frame(mut eth_buff: Vec<u8>, mac_addr: MacAddr) -> Vec<u8> {
    eth_buff.resize(eth_buff.len() + ETH_HEADER_LEN, 0);
    eth_buff.rotate_right(ETH_HEADER_LEN);

    let mut eth_pkt = ethernet::MutableEthernetPacket::new(&mut eth_buff).unwrap();
    eth_pkt.set_source(mac_addr);
    eth_pkt.set_destination(pnet::util::MacAddr(0x0,0x1,0x2,0x3,0x4,0x5));
    eth_pkt.set_ethertype(ethernet::EtherTypes::Ipv4);

    eth_buff
}

// Get an ipv4 packet from a source, and destination address as well as a flow number and a length
fn get_ipv4_packet( ip_src: [u8;4], ip_dst: [u8;4], flow: u8, pkt_len: usize) -> Vec<u8> {
    let mut ip_buff = EMPTY_PKT[0..pkt_len].to_vec();
    let mut packet = ipv4::MutableIpv4Packet::new(&mut ip_buff).unwrap();

    // Set the IP header fields
    packet.set_version(IP_VERSION);
    packet.set_header_length((IP_HEADER_LEN/4) as u8);
    packet.set_total_length(pkt_len as u16); // Set the total length of the packet
    packet.set_ttl(64);
    packet.set_next_level_protocol(IpNextHeaderProtocols::Udp); 
    packet.set_source(ip_src.into());
    packet.set_destination(ip_dst.into());
    packet.set_checksum(pnet::packet::ipv4::checksum(&packet.to_immutable()));

    // Encode flow in last byte
    ip_buff[pkt_len-1] = flow;

    ip_buff
    
}

// Sampe packet lengths at random from a uniform distribution
fn get_random_pkt_lengths(num_pkts: usize, min_pkt_length: usize, max_pkt_length: usize) -> Vec<i32> {
    // Set the minimum length to be sampled due to headers and minimum payload length
    let mut min_len = min_pkt_length;
    if min_pkt_length < IP_HEADER_LEN+MIN_PAYLOAD_LEN || min_pkt_length == 0 {
        min_len = IP_HEADER_LEN+MIN_PAYLOAD_LEN;
    }
    println!("Min pkt length is {} bytes", min_len);

    // Set the maximum length to be sampled due to overhead and MTU
    let mut max_len = max_pkt_length;
    if max_pkt_length > MTU-IP_HEADER_LEN-VPN_HEADER_LEN-ETH_HEADER_LEN || max_pkt_length == 0 {
        max_len = MTU-IP_HEADER_LEN-VPN_HEADER_LEN-ETH_HEADER_LEN;
    }
    println!("Max pkt length is {} bytes", max_len);

    assert!(min_len <= max_len);
    let mut rng = rand::thread_rng();
    let mut pkt_lengths = Vec::with_capacity(num_pkts);

    // Sample the lengths
    for _ in 0..num_pkts {
        pkt_lengths.push(rng.gen_range(min_len as i32..=max_len as i32));
    }
    
    pkt_lengths
}

// Get lengths from a file. The file should be a csv with one column consisting of packet lengths
fn get_lengths_from_file(filename: &str, num_pkts: usize) -> Vec<i32> {
    let file = File::open(filename).expect("Error opening video length file");
    let reader = BufReader::new(file);

    let mut pkt_lengths = Vec::with_capacity(num_pkts);

    // Get the csv file
    let mut csv_reader = csv::ReaderBuilder::new()
        .has_headers(true)
        .from_reader(reader);

    let mut count = 0;
    let mut total_len=0;
    // Read the lengths and make sure they are in the acceptable range
    for result in csv_reader.records() {
        let record = result.expect("Could not read line in file");
        if count >= num_pkts {
            break; 
        }

        // Record the packet lengths
        if let Some(field) = record.get(0) {
            if let Ok(length) = field.parse::<i32>() {
                if length > (MTU-IP_HEADER_LEN-VPN_HEADER_LEN-ETH_HEADER_LEN - TOFINO_OVERHEAD) as i32 {
                    pkt_lengths.push((MTU-IP_HEADER_LEN-VPN_HEADER_LEN-ETH_HEADER_LEN - TOFINO_OVERHEAD) as i32);
                    total_len += MTU-IP_HEADER_LEN-VPN_HEADER_LEN - TOFINO_OVERHEAD;
                    count += 1;
                } else if length > (ETH_HEADER_LEN + IP_HEADER_LEN + MIN_PAYLOAD_LEN) as i32 {
                    pkt_lengths.push(length-ETH_HEADER_LEN as i32);
                    total_len += length as usize;
                    count += 1;
                }
            } else {
                println!("Error: Failed to parse i32");
            }
        } else {
            println!("Error: Missing csv field");
        }
    }
    println!("Avg pkt len = {}B", total_len/count);
    pkt_lengths
}

// Encode the sequence number of the packets as a 64 bit integer
fn encode_sequence_num(arr: &mut Vec<u8>, seq: usize) {
    // Encode as 64 bit integer -> 8 bytes
    arr[ETH_HEADER_LEN+IP_HEADER_LEN] = ((seq >> 56) & 0xFF) as u8;
    arr[ETH_HEADER_LEN+IP_HEADER_LEN+1] = ((seq >> 48) & 0xFF) as u8;
    arr[ETH_HEADER_LEN+IP_HEADER_LEN+2] = ((seq >> 40) & 0xFF) as u8;
    arr[ETH_HEADER_LEN+IP_HEADER_LEN+3] = ((seq >> 32) & 0xFF) as u8;
    arr[ETH_HEADER_LEN+IP_HEADER_LEN+4] = ((seq >> 24) & 0xFF) as u8;
    arr[ETH_HEADER_LEN+IP_HEADER_LEN+5] = ((seq >> 16) & 0xFF) as u8;
    arr[ETH_HEADER_LEN+IP_HEADER_LEN+6] = ((seq >> 8) & 0xFF) as u8;
    arr[ETH_HEADER_LEN+IP_HEADER_LEN+7] = (seq & 0xFF) as u8;
}

// Decode the sequence number of the packets as a 64 bit integer
fn decode_sequence_num(arr: &[u8]) -> usize {
    if arr.len() < ETH_HEADER_LEN+IP_HEADER_LEN+8 {
        println!("Failed to decode seq number in pkt of length {}B", arr.len());
        return 0;
    }
    // Encode as 64 bit integer -> 8 bytes
    let seq = (arr[ETH_HEADER_LEN+IP_HEADER_LEN] as i64) << 56 |
                    (arr[ETH_HEADER_LEN+IP_HEADER_LEN+1] as i64) << 48 |
                    (arr[ETH_HEADER_LEN+IP_HEADER_LEN+2] as i64) << 40 |
                    (arr[ETH_HEADER_LEN+IP_HEADER_LEN+3] as i64) << 32 |
                    (arr[ETH_HEADER_LEN+IP_HEADER_LEN+4] as i64) << 24 |
                    (arr[ETH_HEADER_LEN+IP_HEADER_LEN+5] as i64) << 16 |
                    (arr[ETH_HEADER_LEN+IP_HEADER_LEN+6] as i64) << 8 |
                    arr[ETH_HEADER_LEN+IP_HEADER_LEN+7] as i64;
    seq as usize
}

// Before accepting a received packet, we first make sure that it is destined for this receiver by looking at the ip destination address
fn is_ip_addr_matching(buff: &[u8], ip_addr: [u8;4], is_dest: bool) -> bool {
    if is_dest {
        // The receiver should be the destination
        buff[ETH_HEADER_LEN+IP_DST_ADDR_OFFSET..ETH_HEADER_LEN+IP_DST_ADDR_OFFSET+IP_ADDR_LEN] == ip_addr
    } else {
        // The receiver should be the source (for local tests only)
        buff[ETH_HEADER_LEN+IP_SRC_ADDR_OFFSET..ETH_HEADER_LEN+IP_SRC_ADDR_OFFSET+IP_ADDR_LEN] == ip_addr
    }
}

// Read an environment variable. The flow is set as an environment variable and should be read with this.
pub fn get_env_var_f64(name: &str) -> Result<f64, &'static str> {
    let var = match env::var(name) {
        Ok(var) => {
            match var.parse::<f64>() {
                Ok(var) => {
                    var
                },
                Err(_) => {
                    return Err("Error parsing env variable string");
                }
            }
        },
        Err(_) => {
            return Err("Error getting env vairable");
        },
    };
    Ok(var)
}

// Parse an ip address in the format xxx.xxx.xxx.xxx into 4 bytes.
fn parse_ip(ip_str: String) -> [u8;4] {
    let ip_addr = match ip_str.parse::<net::Ipv4Addr>() {
        Ok(addr) => addr,
        Err(e) => {
            panic!("Failed to parse IP address: {}", e);
        }
    };
    ip_addr.octets()
}

// Generate all packets in advance with the given parameters. Returns a vector of packets.
fn get_all_pkts(num_pkts: usize, ip_src: [u8;4], ip_dst: [u8;4], flow: u8, lengths: Vec<i32>, mac_addr: pnet::util::MacAddr) -> Vec<Vec<u8>> {
    let mut frames = Vec::with_capacity(num_pkts);
    let mut count = 0;
    while count < num_pkts {
        let pkt = get_ipv4_packet(ip_src, ip_dst, flow, lengths[count] as usize);
        let mut frame = get_eth_frame(pkt.to_vec(), mac_addr);
        encode_sequence_num(&mut frame, count+1);

        frames.push(frame);
        count += 1;
    }
    frames
}

// Decode the sequence number of the packet and log the information to a file. Useful when receiving.
fn decode_pkt(pkt: &[u8], save_data: bool, file: &mut std::fs::File) {
    let seq = decode_sequence_num(pkt);

    if save_data {
        // Log to file
        let rx_time = time::SystemTime::now().duration_since(time::UNIX_EPOCH).unwrap().as_nanos();
        let rx_flow = pkt[pkt.len()-1];
        writeln!(file, "{},{},{}", seq, rx_time, rx_flow).expect("Failed to write to file");
    }
}