# Sender Receiver

Rust implementation of a program to send and receive packets at the link layer. It is used to test Ditto and network performance by logging the pakcets sent with their timestamp, flow number, and sequence number. It works by directly sending on network interfaces. The sender and the receiver's clocks must be synchronized with programs such as ntp to get accurate results.

This program can currently send up to around 1 Gbps. If logging everything to a file as the packets are received it can receive much slower at around 200 Mbps. The exact speed depends on the CPU of the system and the underlying hardware. Lower speeds are recommended for optimal performance. The settings with which it should run are set in the configuration files in `config/` and passed to the program as command line arguments. This program should be run between network interfaces that are reachable from each other.

The typical use cases are to send between two wireguard peers to test normal traffic, or to send between the input interface of two Ditto peers to test Ditto obfuscated traffic. Although a single instance of the program can both send and receive packets on different threads, it is recommended to only send or receive to get the best performance.

At the receiver, only packets with the right destination address will be logged. Their destination address should be the `src` address of the receiver.


## Repository overview

The most important contents of this repository are:

* `src/main.rs`: Entry point of the program.
* `src/lib.rs`: Contains the main logic of the program. Starts threads for sending to and receiving from the network.
* `config/*.toml`: Toml configuration files, whose structure will be described below.

## Running the sender/receiver program

```sudo cargo run config/<name of the config file to use>```

The program needs super user privilege to be able to send and receive packets. It also needs the name of the configuration file to use. For example, `config_client_zurich.toml`.

## Important fields in the configuration file
* `src`: Source ip address used by the test packets. It should be the address of the `output` network interface.
* `dst`: Destination ip address used by the test packets. It should be the address of the receiver's `input` network interface.
* `[isolation]`: Section for setting isolation policies to make outgoing traffic independent from incoming traffic. These parameters are specific to the cpu and hardware you are running. Under doubt, set all of them to `false` to deactivate isolation. 
* `input`: Name of the network interface that will be used to receive packets.
* `output`: Name of the network interface that will be used to send packets.
* `rate`: The rate at which the test packets will be sent to the `output` interface in Mbps. 
* `time`: The time in seconds during which the test packets will be sent to the `output` interface. 
* `save`: Whether or not packet's timestamp, flow number, and sequence number should be saved to a file.
* `send`: Whether or not this instance of the program should start a thread to send packets to the `output` interface.
* `receive`: Whether or not this instance of the program should start a thread to receive packets to the `input` interface.
* `log`: Whether or not to show more debugging information when running the program.
* `dataset`: Which dataset to use to send packets. The current options are '' for packets of uniformly distributed length, `caida` for the lengths based on a CAIDA 2018 trace, `video` for lengths based on a video call packet trace, and `web` for lengths based on a web packet trace. All these packet traces should be in a folder called `caida` which should be at the same level as the top folder of the cargo project.
* `min_packet_length`: The minimum length of packets to be sent. Leave it at 0 for the minimum length to be automatically determined. All values under a set minimum will not be considered. Currently, the minimum is `29` bytes for the software implementation of Ditto and `49` bytes for the hardware implementation due to additional padding headers.
* `max_packet_length`: The maximum length of packets to be sent. Leave it at 0 for the maximum length to be automatically determined. All values over a set maximum will not be considered. Currently, the maximum is `1386` bytes for the software implementation of Ditto and `1366` bytes for the hardware implementation due to additional padding headers.

## Flow number

The flow number of the traffic should be set as an environment variable named `FLOW`. For instance, setting it to `1` will indicate that all packets sent with this instance of the program belong to flow 1, which will be encoded in the last byte of the packets sent.


