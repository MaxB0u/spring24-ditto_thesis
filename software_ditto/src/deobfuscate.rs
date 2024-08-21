use pnet::packet::ipv4;
use crate::pattern;
use crate::hardware_obf;

enum PacketType {
    Chaff,          // Chaff -> All zeros. Look at byte after addresses (byte 13)
    Obfuscated,     // Obfuscated -> Other
    // Normal,         // Normal -> N/A Only ditto traffic supported for now
}

// Get the type of packet, can be one of 3 options.
// Chaff, Obfuscated, or Normal.
// Normal not supported for now (assumes all valid packets are obfuscated)
fn get_packet_type(packet: &[u8]) -> PacketType {
    // Ethertype or id is never 0 byte except in chaff packets
    if packet[pattern::IP_HEADER_LEN + 2] == 0_u8 && packet[pattern::IP_HEADER_LEN + 3] == 0_u8 {
        return PacketType::Chaff;
    } else {
        return PacketType::Obfuscated;
    }
}

/// Process a packet to determine if it should be dropped (chaff) or deobfuscated (valid packets).
pub fn process_packet(packet: &[u8], ip_src: [u8;4], is_local: bool, is_hw_obfuscation: bool) -> Option<&[u8]> {
    if (packet[pattern::IP_SRC_ADDR_OFFSET..pattern::IP_SRC_ADDR_OFFSET+pattern::IP_ADDR_LEN] != ip_src && !is_local) 
        || (packet[pattern::IP_SRC_ADDR_OFFSET..pattern::IP_SRC_ADDR_OFFSET+pattern::IP_ADDR_LEN] == ip_src && is_local) {
        // Src ip is the same if local and different if not

        assert!(packet.len() >= pattern::IP_HEADER_LEN, "Packet length must be at least {} bytes", pattern::IP_HEADER_LEN); 
        match get_packet_type(packet) {
            PacketType::Chaff => None,
            PacketType::Obfuscated => Some(deobfuscate(packet, is_hw_obfuscation)),
            //_ => None
        }
    } else {
        // Outgoing packet, do nothing
        None
    }
}

// Deobfuscate a packet by looking at its length from the IP header.
// It also removes the extra IP header that was added during obfuscation.
// It also supports obfuscation by adding Ethernet headers when receiving from a tofino switch.
fn deobfuscate(packet: &[u8], is_hw_obfuscation: bool) -> &[u8] {
    // Or else it would be an invalid packet anyway
    assert!(packet.len() >= pattern::IP_HEADER_LEN, "Packet length must be at least {} bytes", pattern::IP_HEADER_LEN); 

    // Try to get length, only support IP packets
    let pkt = ipv4::Ipv4Packet::new(packet).unwrap();
    let length= pkt.get_total_length();

    if length <= packet.len() as u16 && length > pattern::IP_HEADER_LEN as u16 {
        if is_hw_obfuscation {
            // Packet has been obfuscated by tofino
            // Remove padding ethernet headers 
            hardware_obf::deobfuscate_tofino(&packet[pattern::IP_HEADER_LEN..length as usize])
        } else {
            // Remove wrapped IP header, and truncate
            &packet[pattern::IP_HEADER_LEN..length as usize]
        }
    } else {
        println!("Failed to read length for packet of length {}. Read {}. Returned raw packet.", packet.len() as u16, length);
        packet
    }
}