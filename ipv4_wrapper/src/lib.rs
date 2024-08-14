use pnet::datalink;
use pnet::datalink::Channel::Ethernet;
use std::thread;
use std::error::Error;

// Constants used for the program. Set the network interfaces here
const OBF_INTERFACE: &str = "veth_d";   // Interface used to receive obfuscated packets
const DEOBF_INTERFACE: &str = "ens39";  // Interface used for sending unwrapped packets
const WG_INTERFACE: &str = "wg3";       // Interface used to send wrapped packets
pub const IP_HEADER_LEN: usize = 20;
pub const IP_DST_ADDR_OFFSET: usize = 16;
pub const IP_ADDR_LEN: usize = 4;
// From Zurich to Lausanne with checksum set to 0
// Could be computed dynamically, but that is slower
pub const IP_HDR: [u8; IP_HEADER_LEN] = [69, 0, 0, 0, 0, 0, 0, 0, 64, 94, 0, 0, 10, 7, 0, 2, 10, 7, 0, 3];

/// Custom channel that holds the sending or receiving channel associated with a network interface.
pub struct ChannelCustom {
    pub tx: Box<dyn datalink::DataLinkSender>,
    pub rx: Box<dyn datalink::DataLinkReceiver>,
}

/// Main entry point of the program that starts the threads to wrap or unwrap packets in IP headers. 
/// Listen on obf interface, send on wg interface, and deobf if the packet is at destination dest.
pub fn run(ip_src: [u8;4]) -> Result<(), Box<dyn Error>> {

    // Core isolation is set here
    let is_wrap_isolated = true;
    let is_unwrap_isolated = true;

    // Spawn thread for wrapping packets on the obf interface
    let wrap_handle = thread::spawn(move || {
        if is_wrap_isolated {
            unsafe {
                let mut cpuset: libc::cpu_set_t = std::mem::zeroed();
                libc::CPU_SET(2, &mut cpuset);
                libc::sched_setaffinity(0, std::mem::size_of_val(&cpuset), &cpuset);

                let thread =  libc::pthread_self();
                let param = libc::sched_param { sched_priority: 99 };
                let result = libc::pthread_setschedparam(thread, libc::SCHED_FIFO, &param as *const libc::sched_param);
                if result != 0 {
                    panic!("Failed to set thread priority");
                }
            }
        }
        wrap_and_forward();
    });

    // Spawn thread for sending unwrapped packets
    let unwrap_handle = thread::spawn(move || {
        if is_unwrap_isolated {
            unsafe {
                let mut cpuset: libc::cpu_set_t = std::mem::zeroed();
                libc::CPU_SET(3, &mut cpuset);
                libc::sched_setaffinity(0, std::mem::size_of_val(&cpuset), &cpuset);

                let thread =  libc::pthread_self();
                let param = libc::sched_param { sched_priority: 99 };
                let result = libc::pthread_setschedparam(thread, libc::SCHED_FIFO, &param as *const libc::sched_param);
                if result != 0 {
                    panic!("Failed to set thread priority");
                }
            }
        }
        unwrap_and_forward(ip_src);
    });

    wrap_handle.join().expect("Wrapping thread panicked");
    unwrap_handle.join().expect("Unwrapping thread panicked");

    Ok(())
}

// Custom channel that returns the sending or receiving channel associated with a network interface.
fn get_channel(interface_name: &str) -> Result<ChannelCustom, &'static str>{
    // Retrieve the network interface
    let interfaces = datalink::interfaces();
    let interface = match interfaces
        .into_iter()
        .find(|iface| iface.name == interface_name) {
            Some(inter) => inter,
            None => return Err("Failed to find network interface"),
        };

    // Create a channel to receive Ethernet frames
    let (tx, rx) = match datalink::channel(&interface, Default::default()) {
        Ok(Ethernet(tx, rx)) => (tx, rx),
        Ok(_) => return Err("Unknown channel type"),
        Err(e) => panic!("Failed to create channel {e}"),
    };

    let ch = ChannelCustom{ 
        tx, 
        rx,
    };

    Ok(ch)
}

// Wrap packets on the obf interface in a IP header and forwards them to the wireguard (wg) interface.
fn wrap_and_forward() {
    // Get the channel to receive obfuscated packets
    let mut ch_rx = match get_channel(OBF_INTERFACE) {
        Ok(rx) => rx,
        Err(error) => panic!("Error getting channel: {error}"),
    };

    // Get the channel to send wrapped packets
    let mut ch_wg = match get_channel(WG_INTERFACE) {
        Ok(tx) => tx,
        Err(error) => panic!("Error getting channel: {error}"),
    };

    // Process received Ethernet frames
    loop {
        match ch_rx.rx.next() {
            Ok(packet) =>  {
                let ip_pkt = wrap_in_ipv4(packet);
                ch_wg.tx.send_to(&ip_pkt, None);
            },
            Err(e) => {
                eprintln!("Error receiving frame: {}", e);
                continue;
            }
        };
    }
}

// Unwrap packets on the wg interface (remove IP header) and forwards them to the deobf interface.
fn unwrap_and_forward(ip_src: [u8;4]) {
    // Get the channel to send unwrapped packets to
    let mut ch_rx = match get_channel(DEOBF_INTERFACE) {
        Ok(rx) => rx,
        Err(error) => panic!("Error getting channel: {error}"),
    };

    // Get the channel to receive wrapped packets on
    let mut ch_wg = match get_channel(WG_INTERFACE) {
        Ok(tx) => tx,
        Err(error) => panic!("Error getting channel: {error}"),
    };

    // Process received Ethernet frames
    loop {
        match ch_wg.rx.next() {
            Ok(packet) =>  {
                // Only unwrap if the packet is at destination
                if packet[IP_DST_ADDR_OFFSET..IP_DST_ADDR_OFFSET+IP_ADDR_LEN] == ip_src {
                    ch_rx.tx.send_to(&packet[IP_HEADER_LEN..], None);
                }
            },
            Err(e) => {
                eprintln!("Error receiving frame: {}", e);
                continue;
            }
        };
    }
}

// Utility function to wrap a packet in a constant ipv4 header. 
fn wrap_in_ipv4(data: &[u8]) -> Vec<u8> {
    let total_len = data.len() + IP_HEADER_LEN;    
    let mut buffer = Vec::with_capacity(total_len);

    // Add IP header
    buffer.extend_from_slice(&IP_HDR);

    // Set total length in header (bytes 2,3) dynamically
    buffer[2..4].copy_from_slice(&(total_len as u16).to_be_bytes());

    // Add the original data to the wrapped packet
    buffer.extend_from_slice(&data);
    buffer
}

