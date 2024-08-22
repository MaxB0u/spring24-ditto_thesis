# Software Ditto

Rust implementation of Ditto based on Roland Meier's original P4 version (available [here](https://github.com/nsg-ethz/ditto)). It does not need any special hardware to run. However, it can only be used for applications that require lower throughput.

This program can currently run up to around 1 Gbps. The exact speed depends on the CPU of the system and the underlying hardware. Lower speeds are recommended for optimal performance. The settings with which it should run are set in the configuration files in `config/` and passed to the program as command line arguments. This program should be run over a Wireguard or other VPN to benefit from encryption and so that packets can not be trivially deobfuscated by an eavesdropper. A wireguard VPN was used for all tests.

## Repository overview

The most important contents of this repository are:

* `src/main.rs`: Entry point of the program.
* `src/lib.rs`: Contains the main logic of the program. Starts threads for sending to and receiving from the network.
* `config/*.toml`: Toml configuration files, whose structure will be described below.
* `src/pattern.rs`: File in which the Ditto pattern is set along with many other constants. The Ditto pattern can not be set in the configuration file for efficiency and to benefit from more compiler optimizations.

## Running the software version of Ditto

```sudo cargo run config/<name of the config file to use>```

The program needs super user privilege to be able to send and receive packets. It also needs the name of the configuration file to use. For example, `config_client_zurich.toml`.

## Important fields in the configuration file
* `src`: Source ip address used by Ditto obfuscated packets. Usually the address of a VPN peer.
* `dst`: Destination ip address used by Ditto obfuscated packets. Usually the address of a VPN peer. The destination address should be another instance of Ditto so that packets can be deobfuscated.
* `[isolation]`: Section for setting isolation policies to make outgoing traffic independent from incoming traffic. These parameters are specific to the cpu and hardware you are running. Under doubt, set all of them to `false` to deactivate isolation. 
* `no_obf`: Name of the network interface that will be used to send and receive unobfuscated or deobfuscated traffic.
* `obf`: Name of the network interface that will be used to send and receive obfuscated traffic.
* `src_device`: Name of a device from which Ethernet frames will be obfuscated in addition to the `no_obf` interface. Useful when you want to obfuscate frames that come from a router on your LAN and not directly from the `no_obf` interface.
* `rate`: The rate at which obfuscated Ditto traffic will be sent to the network (`obf` interface) in Mbps. Note that if no real traffic is being communicated, chaff packets will be sent instead.
* `pad_log_interval`: Interval of packets after which the average padding will be logged for analysis. Set a very large value to not log these values often.
* `save`: Whether or not logged values and configuration parameters such as the pattern should be saved to a file.
* `local`: Whether or not this instance of Ditto is running locally with another Ditto instance or if the Ditto peer is remote.
* `log`: Whether or not to show more debugging information when running the program.
* `hw_obfuscation`: Whether or not traffic is being received from a Tofino switch. This program can deobfuscate packets from a Tofino switch, but it can not at this moment obfuscate packets in a way that the Tofino switch will be able to deobfuscate them. This is because the p4 program running on the Tofino uses a different obfuscation scheme than this software version and adds fake Ethernet headers instead of extending the trailing bytes of the packet for padding.
* `backbone`: Whether or not this Ditto instance runs in the backbone. In its default configuration Ditto will run end-to-end between communication link, but there is the option to run it in the backbone. Note that in the backbone case more configuration will be needed such as the IP address of the next Ditto peer to forward the packet to. In a more mature version of the software, this should be handled by a router.




