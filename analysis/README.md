# Tests

Bash scripts to run tests automatically. The bash scripts expect a certain structure of folder, access to virtual machines and ssh configuration. Without the right configuration these scripts will fail. To run all scripts you need 3 VM. In our case there a VM was hosted in Zurich, one was hosted in Thun, and one was hosted in Lausanne. The constants at the start of the bash scripts should also be adjusted to use the correct IP addresses. All the scripts in the analysis section should be moved to a folder called `cyd` that should be in the home directory of the current user.

The hardware test further assume that you have access to two Tofino switches and that they are already running an instance of Ditto along with an instance of the IP wrapping on a VM connected to it. 

Finally, all tests assume that the different VMs are Wireguard peers to each other and that they can reach each other. All tests were run on a Ubuntu machine with VMs also running Ubuntu.


## Repository overview

Here are the contents of this repository and how to run each of the scripts:

* `analyze_pkt_dist.py`: Given a csv file of packet lengths, get the efficient patterns and plot the emprirical PDF and CDF. The efficient patterns can then be used in the tests.

```python3 analyze_pkt_dist.py <filename>```

* `check_csv.py`: Given a csv file name, a key in the file name and a run number, check if it already exists. If any extra argument is given, it will instead check if the CSV file is already full assuming 8 keys and 30 runs which is the default in the tests. The extra argument is usually called `full` in the tests. This extra option allows to check a CSV file more quickly without having to go line by line through it, but it might be less accurate.

```python3 check_csv.py <filename> <key> <run_num>```

* `extract_pcap_len.py`: Given a pcap file (that can be in a compressed gz or zip format), extract the lengths of each packet in the trace and save the lengths in order in a CSV file. The output of this script can be used for tests or to analyze the packet distribution with the script `analyze_pkt_dist.py`.

```python3 extract_pcap_len.py <input filename> <output filename>```

* `get_combined_data.py`: Given the resutls of the backbone tests, combined the results from the VoIP and the web flow. This file defines for which value we should do an addition, a weighted average, or nothing. A specific rate should be specified when running the file. Either 100 Mbps or 200 Mbps in our tests.

```python3 get_combined_data.py <Ditto rate(Mbps)>```

* `get_metrics.py`: Given packet sequence number, timestamps, and flow number, extract metrics from them that will then be useful for our analysis. In its most basic version, this script takes in a file for the transmitter and a file for the receiver. However, many other options exist with extra arguments. In order, extra arguments can be given for a key number as a float or a run number as an int that will be used to index the data if saved in a file. Then, the user can specify the filname to save the data into. They can also specify whether or not to analyze padding with a boolean. Finally, the user can specify the number of flows to analyze or a specific flow with the following two arguments. The maximum number of argumetns given to the script is therefore 8.

```python3 get_metrics.py <tx_file> <rx_file>```
```python3 get_metrics.py <tx_file> <rx_file> <key_number> <run_number> <filename> <analyze_pad> <num_flows> <flow>```

* `plot_config.csv`: Keeps track of all the CSV files in the results. Set a value in the IsUsed column to True to used this data when plotting with the `plot_results.py` script. The `plot_config.csv` file cannot be run.

* `plot_delays.py`: Given two CSV files of timings, analyze the differences between them and how the data could be optimally classified. This file is used to generate the plots to analyze the timing side channel of the software version of Ditto.

```python3 plot_delays.py <file 1 (no traffic)> <file 2 (traffic)>```

* `plot_iperf.py`: Given two CSV files of iPerf results, plot the achievable rate under tcp, udp, and CAIDA data. If no files are given, default filenames are used.

```python3 plot_iperf.py```
```python3 plot_iperf.py <iperf results file> <iperf results file (caida data)>```

* `plot_load_time.py`: Given two CSV files of web loading results, plot the loading time vs pattern length and the loading time vs background traffic rate. If no files are given, default filenames are used.

```python3 plot_load_time.py```
```python3 plot_load_time.py <file time vs pattern> <file time vs background traffic>```

* `plot_results.py`: Given the information in the `plot_config.csv` file, plot the latency, packet loss, packet reordering, and jitter of the data. The arguments passed are the minimum and maximum bounds of the x-axis of the graphs.

```python3 plot_results.py <min rate (% of capacity)> <max rate (% of capacity)>```

* `plot_web.py`: Given a CSV file, plot the time of web results over curl or wget. If no file is given, a default filename is used.

```python3 plot_web.py```
```python3 plot_web.py <filename>```

* `script_web_load.py`: Given a web page name and its IP address, load it and log how much time it took. Optionally, specify a file to save the data in as well as a run number and the length of the pattern used.

```python3 script_web_load.py <web_page_name> <web_page_ip> OPTIONAL: <filename> <run_number> <pattern_length>```

* `subsample_file.py`: Given a file with logged packets, skip the first entries, log 1 million packets and save it to another file. This file is used for maual tests where not all the process were started for the first few packets.

```python3 subsample_file.py <input_file> <output_file>```

Use pip to install any missing dependencies.
