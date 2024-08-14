# IPv4 Wrapper

Rust program used to listen on a network interface and wrap ethernet frames in an ip header so that they can be sent end to end through a wireguard tunnel.

This program can currently run to about 800 Mbps. In its current state, parameters such as network interface names are set explicitely in `lib.rs`. In the future this could be done in a separate configuration file or as command line arguments, but due to the simplicity of the program it did not feel needed. 

Another solution would be to use a Wireguard tunnel at the link layer.

## Repository overview

The most important contents of this repository are:

* `src/main.rs`: Entry point of the program.
* `src/lib.rs`: Contains all the logic for wrapping and unwrapping packets.

## Running the IPv4 wrapper

```sudo cargo run <ip of the host>```

The program needs super user privilege to be able to send and receive packets. It also needs the ip address of the host since it will only unwrap packets that are destined to this ip address.