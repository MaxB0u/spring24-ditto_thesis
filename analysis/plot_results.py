import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import sys


def plot_results(
    dfs,
    names,
    show_pts=False,
    min_rate=0,
    max_rate=100,
    show_qos=False,
    x_label=None,
    name=None,
):
    """
    Plot of to 5 graphs: the latency, the packet losses, the packet reordering, and the jitter, and the padding from a list of dataframes.
    """

    # Adjust x-axis label of graphs
    if x_label is None:
        x_label = "Sending rate (% of capacity)"
        x_label = "Sending rate (Mbps)"

    # Plot avg latency
    plt.figure()
    for i in range(len(dfs)):
        grouped = dfs[i].groupby("Key")["LatAvg"].agg(["mean", "std"])
        plt.plot(grouped.index, grouped["mean"] / 1e6, label=names[i])
        plt.errorbar(
            grouped.index, grouped["mean"] / 1e6, yerr=grouped["std"] / 1e6, fmt="o"
        )

        if show_pts:
            plt.scatter(dfs[i]["Key"], dfs[i]["LatAvg"] / 1e6)

    # For VoIP plots
    if show_qos:
        plt.axhline(
            y=50,
            xmin=min_rate,
            xmax=max_rate,
            color="r",
            label="Microsoft Teams QOS: 50ms",
        )

    plt.title("Average latency")
    plt.xlabel(x_label)
    plt.ylabel("Latency (ms)")
    plt.legend()
    plt.ylim(bottom=0)
    if name is not None:
        plt.savefig(f"/home/max/cyd/figures/basic_tests/bps/{name}_lat.png")

    # Plot loss
    plt.figure()
    for i in range(len(dfs)):
        grouped = dfs[i].groupby("Key")["Loss"].agg(["mean", "std"])
        # print(df[df['Loss'] > 0.2])
        plt.plot(grouped.index, grouped["mean"] * 100, label=names[i])
        plt.errorbar(
            grouped.index, grouped["mean"] * 100, yerr=grouped["std"] * 100, fmt="o"
        )

        if show_pts:
            plt.scatter(dfs[i]["Key"], dfs[i]["Loss"] * 100)

    # For VoIP plots
    if show_qos:
        plt.axhline(
            y=1,
            xmin=min_rate,
            xmax=max_rate,
            color="r",
            label="Microsoft Teams QOS: 1%",
        )

    plt.title("Average loss")
    plt.xlabel(x_label)
    plt.ylabel("Packet loss (%)")
    plt.legend()
    plt.ylim(bottom=0)
    if name is not None:
        plt.savefig(f"/home/max/cyd/figures/basic_tests/bps/{name}_loss.png")

    # Plot reordering
    plot_out_of_order = True
    plt.figure()
    for i in range(len(dfs)):
        if plot_out_of_order:
            grouped = dfs[i].groupby("Key")["OutOfOrder"].agg(["mean", "std"])
        else:
            grouped = dfs[i].groupby("Key")["ReordAvg"].agg(["mean", "std"])
        plt.plot(grouped.index, grouped["mean"] * 100, label=names[i])
        plt.errorbar(
            grouped.index, grouped["mean"] * 100, yerr=grouped["std"] * 100, fmt="o"
        )

        if show_pts:
            plt.scatter(dfs[i]["Key"], dfs[i]["OutOfOrder"])

    # For VoIP plots
    if show_qos:
        plt.axhline(
            y=0.05,
            xmin=min_rate,
            xmax=max_rate,
            color="r",
            label="Microsoft Teams QOS: 0.05%",
        )

    plt.title("Out of Order Packets")
    plt.xlabel(x_label)
    if plot_out_of_order:
        plt.ylabel("Out of order packets (%)")
    else:
        plt.ylabel("Average reordering (pkts)")
    plt.legend()
    plt.ylim(bottom=0)
    if name is not None:
        plt.savefig(f"/home/max/cyd/figures/basic_tests/bps/{name}_reord.png")

    # Plot jitter
    plt.figure()
    for i in range(len(dfs)):
        grouped = dfs[i].groupby("Key")["Jitter"].agg(["mean", "std"])
        plt.plot(grouped.index, grouped["mean"] / 1e6, label=names[i])
        plt.errorbar(
            grouped.index, grouped["mean"] / 1e6, yerr=grouped["std"] / 1e6, fmt="o"
        )

        if show_pts:
            plt.scatter(dfs[i]["Key"], dfs[i]["Jitter"] / 1e6)

    # For VoIP plots
    if show_qos:
        plt.axhline(
            y=30,
            xmin=min_rate,
            xmax=max_rate,
            color="r",
            label="Microsoft Teams QOS: 30ms",
        )

    plt.title("Average jitter")
    plt.xlabel(x_label)
    plt.ylabel("Jitter (ms)")
    plt.legend()
    plt.ylim(bottom=0)
    if name is not None:
        plt.savefig(f"/home/max/cyd/figures/basic_tests/bps/{name}_jitter.png")

    # Plot padding
    if x_label == "Pattern length":
        plt.figure()
        for i in range(len(dfs)):
            grouped = dfs[i].groupby("Key")["PadAvg"].agg(["mean", "std"])
            plt.plot(grouped.index, grouped["mean"], label=names[i])
            plt.errorbar(grouped.index, grouped["mean"], yerr=grouped["std"], fmt="o")

        plt.title("Average padding")
        plt.xlabel(x_label)
        plt.ylabel("Padding (Bytes)")
        plt.legend()
        if name is not None:
            plt.savefig(f"/home/max/cyd/figures/basic_tests/bps/{name}_pad.png")

    plt.show()


if __name__ == "__main__":
    """
    Given the information in the plot_config.csv file, plot the latency, packet loss, packet reordering, and jitter of the data.
    """

    # Whether to show individual points or just the error bounds
    show_pts = False

    if len(sys.argv) < 3:
        print(
            "Usage: python3 plot_results.py <min rate (% of capacity)> <max rate (% of capacity)>"
        )
        sys.exit(1)

    # Lower and upper bound for the graphs
    min_rate = int(sys.argv[1])
    max_rate = int(sys.argv[2])

    # Get which files to plot
    filename = "plot_config.csv"
    df_config = pd.read_csv(filename)
    df_config = df_config[df_config["IsUsed"]]
    filenames = df_config["File"].to_numpy()
    dfs = [pd.read_csv(f) for f in filenames]
    names = df_config["Name"].to_numpy()

    # Whether or not to show the QoS metrics for VoIP traffic
    show_qos = False
    for n in names:
        if "Voip" in n:
            show_qos = True

    # Customize the x-axis label of the graphs
    x_label = None
    if "pattern" in filenames[0]:
        x_label = "Pattern length"
    elif "mult" in filenames[0]:
        x_label = "Number of flows"

    # Filter data
    dfs_filetered = [df[df["Key"] <= max_rate] for df in dfs]
    dfs_filetered = [df[df["Key"] >= min_rate] for df in dfs_filetered]
    dfs_sorted = [
        df.sort_values(by="Key").reset_index(drop=True) for df in dfs_filetered
    ]

    # Plot the data
    plot_results(
        dfs_sorted, names, show_pts, min_rate, max_rate, show_qos, x_label=x_label
    )
