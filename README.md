# Spring 2024 - Maxime Bourassa Master Thesis

In collaboration with EPFL's Security and Privacy Engineering Laboratory (SPRING) and the Cyber-Defense Campus (CYD Campus).

## Repository overview

This repository contains the work related to my Master's thesis. The contents of each of the folders is summarized below. Each folder also has its own README file and instructions on how to run the code.

* `analysis`: Scripts to generate the test results or plot the results as well as CSV file containing the data for the results presented in the report.
* `ipv4_wrapper`: Rust project to wrap packets coming on a network interface in a IP header and to send them out to another interface. Packets coming in the other direction will have their IP header stripped.
* `sender_receiver`: Rust project to send and receive packets between network interfaces and to record their sequence number, timestamp, and flow number. The packets are used for testing.
* `software_ditto`: Software version of Ditto coded in Rust. Main contribution of this repository. It emulates the original version of Ditto that runs on Tofino switches in a software implementation.
* `tests`: Bash scripts to automate running tests. They are highly specific to the infrstructure used to run the tests, but are added here for completeness.  
