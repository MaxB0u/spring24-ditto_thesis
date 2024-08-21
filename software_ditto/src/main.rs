use std::fs;
use toml::Value;


// Entry point of the program. Parses arguments and calls the main function with the configuration file.
fn main() {
    // Get the name of the network interface from the command-line arguments
    let mut args: Vec<String> = std::env::args().collect();

    // Check if at least four arguments are provided
    if args.len() < 2 {
        eprintln!("Usage (give 4 interface names): {} <config file>", args[0]);
        std::process::exit(1);
    }

    // Get and parse *.toml configuration file
    let toml_str = fs::read_to_string(args.pop().unwrap_or_default()).expect("Failed to read file");
    let toml_value: Value = toml::from_str(&toml_str).expect("Failed to parse TOML");

    if let Err(e) = software_ditto::run(toml_value) {
        eprintln!("Application error: {e}");
        std::process::exit(1);
    }
}

