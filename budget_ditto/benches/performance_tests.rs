use budget_ditto::{self, pattern};
use budget_ditto::queues::round_robin;
use std::time::{Duration, Instant};
use std::thread;
use pnet::packet::ethernet;
use pnet::util::MacAddr;
use rand::prelude::*;
use criterion::{black_box, criterion_group, criterion_main, Criterion};
use std::arch::asm;

// Constants used to call the tests
const NUM_PACKETS: f64 = 1e3;
const MIN_ETH_LEN: i32 = 64;
const MTU: usize = 1500;
const EMPTY_PKT: [u8; MTU] = [0; MTU];
const SRC_IP_ADDR: [u8;4] = [10, 9, 0, 2];
const DST_IP_ADDR: [u8;4] = [10, 9, 0, 1];

fn send(input: &str) {
    /// Sends packets to test Ditto.
    let mut ch_tx = match budget_ditto::get_channel(input) {
        Ok(tx) => tx,
        Err(error) => panic!("Error getting channel: {error}"),
    };

    let packets = get_eth_frames();
    for i in 0..NUM_PACKETS as usize {
        match ch_tx.tx.send_to(&packets[i], None) {
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
    }
}

fn receive(output: &str) {
    /// Receives Ditto packets in a thread.
    let mut ch_rx = match budget_ditto::get_channel(output) {
        Ok(rx) => rx,
        Err(error) => panic!("Error getting channel: {error}"),
    };

    thread::spawn(move || {
        for _ in 0..NUM_PACKETS as usize {
            match ch_rx.rx.next() {
                Ok(_) =>  {
                    //println!("Received length = {}", packet.len());
                },
                Err(e) => {
                    eprintln!("Error receiving frame: {}", e);
                    continue;
                }
            };
        }
    });
}

fn get_eth_frames() -> Vec<Vec<u8>>{
    /// Get ethernet frames used for tests.
    let src_mac = MacAddr::new(0x05, 0x04, 0x03, 0x02, 0x01, 0x00);
    let dst_mac = MacAddr::new(0x00, 0x01, 0x02, 0x03, 0x04, 0x05);
    let mut frame_buff: Vec<Vec<u8>> = Vec::new();
    // Construct the frames
    for _ in 0..NUM_PACKETS as i32 {
        let length = get_random_pkt_len() as usize;
        let mut eth_buff = EMPTY_PKT[0..length].to_vec();
        let mut eth_pkt = ethernet::MutableEthernetPacket::new(&mut eth_buff).unwrap();
        eth_pkt.set_source(src_mac);
        eth_pkt.set_destination(dst_mac);
        eth_pkt.set_ethertype(ethernet::EtherType::new(length as u16));
        frame_buff.push(eth_buff);
    }
    frame_buff
}

fn get_random_pkt_len() -> i32 {
    /// Get a random length that can be used to sample from a distribution of packet lengths.
    let mut rng = rand::thread_rng();
    rng.gen_range(MIN_ETH_LEN..=MTU as i32)
}

fn rr_pop() {
    /// Pop empty queues.
    let rrs = round_robin::RoundRobinScheduler::new(budget_ditto::pattern::PATTERN.len(), 1e6, SRC_IP_ADDR, DST_IP_ADDR);
    rrs.pop(pattern::PATTERN.len()-1); // Pop from last q (currently longest so worst case scenario. Be careful about this)
}

fn thread_timer() {
    /// Test the most efficient method to make a thread sleep.
    let interval = Duration::from_nanos(1e3 as u64);
    let t = Instant::now();
    // Calculate time to sleep
    let elapsed_time = t.elapsed();
    // Sleep for the remaining time until the next iteration
    for _ in 0..1000 {
        unsafe {
            asm! ("nop") 
        }
    }

    if elapsed_time > interval {
        println!("Ran out of time processing {:?}", elapsed_time);
    }
}


fn bench_send(c: &mut Criterion) {
    /// Benchmark sending packets.
    let input = "eth1";
    c.bench_function("send", |b| b.iter(|| send(black_box(input))));
}

fn bench_get_pkts(c: &mut Criterion) {
    /// Benchmark getting packets.
    c.bench_function("get_eth_frames", |b| b.iter(|| get_eth_frames()));
}

fn bench_get_channel(c: &mut Criterion) {
    /// Benchmark getting a channel.
    let input = "eth1";
    c.bench_function("get_channel", |b| b.iter(|| budget_ditto::get_channel(black_box(input))));
}

fn bench_receive(c: &mut Criterion) {
    /// Benchmark receiving packets.
    let input = "eth3";
    c.bench_function("receive", |b| b.iter(|| receive(black_box(input))));
}

fn bench_rr_pop(c: &mut Criterion) {
    /// Benchmark popping packets from the round robbin queue.
    c.bench_function("rr_pop", |b| b.iter(|| rr_pop()));
}

fn bench_thread_timer(c: &mut Criterion) {
    /// Benchmark different ways to make threads sleep.
    c.bench_function("thread_timer", |b| b.iter(|| thread_timer()));
}

// Before running this need to setup virtual eth 1,2,3
// And to urn ditto in another window with command
// sudo -E cargo run eth1 eth2 eth2 eth3
// to run it all on same device
criterion_group!(tx, bench_send);
criterion_group!(gen, bench_get_pkts); // 8 micro sec
criterion_group!(ch, bench_channel);
criterion_group!(rx, bench_receive);
criterion_group!(get_ch, bench_get_channel);
criterion_group!(pop, bench_rr_pop);
criterion_group!(tt, bench_thread_timer);
// criterion_main!(get_ch, gen, tx, ch, rx, push);
criterion_main!(tt);