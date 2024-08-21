use pnet::packet::ipv4;
use pnet::packet::ip::IpNextHeaderProtocols;
use pnet::packet::Packet;
use crossbeam::queue::ArrayQueue;
use crate::pattern;

// If the queus gets larger packets will be dropped
// Trade-off between memory requirement, latency, and packet losses
const MAX_Q_LEN: usize = 1024;

/// Implementation of a priority queue to pad packets to a given length and send them or a chaff packet to the network.
pub struct PriorityQueue {
    // It might be more efficient to hard code a queue length in an array
    pub queue: ArrayQueue<Vec<u8>>,
    pub length: usize,
    src: [u8;4],
    dst: [u8;4],
    chaff: Vec<u8>,
}

impl PriorityQueue {
    /// Create a new queue for packets of a given length
    /// Src and dst address needed to generate valid IP headers
    /// Generate a chaff packet and reuse it all the time for this queue
    pub fn new(length: usize, src: [u8;4], dst: [u8;4]) -> Self{
        let chaff = get_chaff(length, src, dst);
        PriorityQueue{queue: ArrayQueue::new(MAX_Q_LEN), length, src, dst, chaff}
    }

    /// Push a packet onto the queue
    /// Pad when you push to be more efficient when you pop
    pub fn push(&self, packet: Vec<u8>) {
        let wrapped_packet = self.wrap_in_ipv4(packet);
        let padded_data = pad(wrapped_packet, self.length + pattern::IP_HEADER_LEN);
        if let Err(_) = self.queue.push(padded_data) {
            // println!("Queue {} full, length = {}, error pushing", self.length, self.queue.len());
        }
    }

    /// Get the next packet in the queue
    pub fn pop(&self) -> Vec<u8> {
        let packet = match self.queue.pop() {
           Some(pkt) => {
            pkt.to_vec()
           },
           None => {
            self.chaff.to_vec()
           }
        };
       packet
    }

    // Wraps a packet in a ip header. Done before pushing and before padding.
    // The length in the IP header will be used to determine the length of the original packet when deobfuscating.
    fn wrap_in_ipv4(&self, data: Vec<u8>) -> Vec<u8> {
        let initial_len = data.len();
        let mut data = data;
        
        data.resize(initial_len + pattern::IP_HEADER_LEN, 0);
        data.rotate_right(pattern::IP_HEADER_LEN);
        let mut packet = ipv4::MutableIpv4Packet::new(&mut data).unwrap();
    
        // Set the IP header fields
        packet.set_version(pattern::IP_VERSION);
        packet.set_header_length((pattern::IP_HEADER_LEN/4) as u8);
        packet.set_total_length(((initial_len + pattern::IP_HEADER_LEN)) as u16); // Set the total length of the packet
        packet.set_ttl(64);
        packet.set_next_level_protocol(IpNextHeaderProtocols::IpIp); 
        packet.set_source(self.src.into());
        packet.set_destination(self.dst.into());
        packet.set_checksum(pnet::packet::ipv4::checksum(&packet.to_immutable()));
        
        packet.packet().to_vec()
    }
}

// Resize a packet and add 0 bytes for padding
fn pad(data: Vec<u8>, target_length: usize) -> Vec<u8> {
    let mut padded_data = data;
    padded_data.resize(target_length, 0);
    padded_data
}

// Generates the model chaf packet for the queue and wraps it in a IP header before returning it.
fn get_chaff(length: usize, src_addr: [u8;4], dst_addr: [u8;4]) -> Vec<u8> {
    let mut data = pattern::CHAFF.to_vec();
    
    data.resize(length + pattern::IP_HEADER_LEN, 0);
    data.rotate_right(pattern::IP_HEADER_LEN);
    let mut packet = ipv4::MutableIpv4Packet::new(&mut data).unwrap();

    // Set the IP header fields
    packet.set_version(pattern::IP_VERSION);
    packet.set_header_length((pattern::IP_HEADER_LEN/4) as u8);
    packet.set_total_length(((length + pattern::IP_HEADER_LEN)) as u16); // Set the total length of the packet
    packet.set_ttl(64);
    packet.set_next_level_protocol(IpNextHeaderProtocols::IpIp); 
    packet.set_source(src_addr.into());
    packet.set_destination(dst_addr.into());

    packet.set_checksum(pnet::packet::ipv4::checksum(&packet.to_immutable()));
    
    packet.packet().to_vec()
}




 