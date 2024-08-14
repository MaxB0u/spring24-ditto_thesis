use std::net;

fn main() {
    /// Entry point of the program. Parses arguments and calls the main function with the desired ip address.

    let args: Vec<String> = std::env::args().collect();

    if args.len() < 2 {
        eprintln!("Usage {}: <wg addr>", args[0]);
        std::process::exit(1);
    }

    // Source ip address should be a wireguard peer.
    let ip_src = parse_ip(args[1].to_string());

    if let Err(e) = ipv4_wrapper::run(ip_src) {
        eprintln!("Application error: {e}");
        std::process::exit(1);
    }
}

fn parse_ip(ip_str: String) -> [u8;4] {
    /// Get an ip adress from a string in the format xxx.xxx.xxx.xxx and returns it as 4 bytes.
    let ip_addr = match ip_str.parse::<net::Ipv4Addr>() {
        Ok(addr) => addr,
        Err(e) => {
            panic!("Failed to parse IP address: {}", e);
        }
    };
    ip_addr.octets()
}

