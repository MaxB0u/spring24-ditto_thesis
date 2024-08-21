from scapy.all import *
import gzip
import socket
import sys
import csv
import os


def read_lengths(filename, output_file):    
    """
    Given a pcap file, read the packet lengths and save them to an output file.
    """
    succ_count = 0
    err_count = 0

    # Open the output file
    with open(output_file, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["IpLength"])

        # Open the pcap file
        with PcapReader(filename) as pcap_reader:
            for p in pcap_reader:
                is_extracted = False
                # Log the number of extracted packets periodically
                if succ_count % 100000 == 0:
                    print(succ_count)

                try:
                    # Only look at Ethernet frames
                    p = p[Ether].payload
                except:
                    pass

                if not is_extracted:
                    try:
                        # If it wasn't extracted before, just write the length of the packet to the file
                        writer.writerow([len(p)])
                        succ_count += 1

                    except Exception as e:
                        # It was impossible to extract the length of the packet
                        err_count += 1

            # Log the total number of extracted packets
            print(
                f"Extracted length for {succ_count} packets, failed for {err_count} packets"
            )
            return lengths


def extract_length_compressed(filename, output_file):
    """
    Given a compressed pcap file, read the packet lengths and return them.
    """
    with gzip.open(filename, "rb") as f:
        lengths = read_lengths(f, output_file)

    return lengths


def extract_length(filename, output_file):
    """
    Given a pcap file, read the packet lengths and return them.
    """
    with open(filename, "rb") as f:
        lengths = read_lengths(f, output_file)

    return lengths


if __name__ == "__main__":
    """
    Given a pcap file (that can be in a compressed gz or zip format), extract the lengths of each packet in the trace and save the lengths in order in a CSV file.
    """

    if len(sys.argv) != 3:
        print("Usage: python3 extract_pcap_len.py <input filename> <output filename>")
        exit(1)

    filename = sys.argv[1]
    output_file = sys.argv[2]

    # Check if the file is compressed or not
    lengths = []
    if "zip" in filename or "gz" in filename:
        lengths = extract_length_compressed(filename, output_file)
    else:
        lengths = extract_length(filename, output_file)
