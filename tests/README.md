# Tests

Bash scripts to run tests automatically. The bash scripts expect a certain structure of folder, access to virtual machines and ssh configuration. Without the right configuration these scripts will fail. To run all scripts you need 3 VM. In our case there a VM was hosted in Zurich, one was hosted in Thun, and one was hosted in Lausanne. The constants at the start of the bash scripts should also be adjusted to use the correct IP addresses. All the scripts in the analysis section should be moved to a folder called `cyd` that should be in the home directory of the current user.

The hardware test further assume that you have access to two Tofino switches and that they are already running an instance of Ditto along with an instance of the IP wrapping on a VM connected to it. 

Finally, all tests assume that the different VMs are Wireguard peers to each other and that they can reach each other. All tests were run on a Ubuntu machine with VMs also running Ubuntu.


## Repository overview

The contents of this repository are:

* `backbone_tests.sh`: Automatically runs the backbone tests to test Ditto running in the network bacbone in addition to network edges.
* `hardware_tests.sh`: Automatically runs the hardware tests to test Ditto between Tofino switches.
* `interactive_tests.sh`: Automatically runs the interactive tests to test web browsing and VoIP over Ditto.
* `iperf_test.sh`: Automatically runs the iPerf tests to test how fast data can be sent in TCP and UDP flows over Ditto.
* `metric_tests.sh`: Automatically runs the metric tests to test Ditto for latency, packet losses, packet reordering, and jitter under differenet configurations.
* `run_tests.sh`: Utility script to run the metric tests between all pairs of sites.

To run the tests, simply run the bash script from a terminal.
