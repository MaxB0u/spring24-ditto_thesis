import sys
import pandas as pd
import matplotlib.pyplot as plt


def plot_data(df, df_caida):
    """
    Get tcp, udp and caida data. Plot them over three curves on a graph
    """
    df_tcp = df[df["PROTOCOL"] == "tcp"]
    df_udp = df[df["PROTOCOL"] == "udp"]

    # Plot tcp
    plt.figure()
    grouped_tcp = df_tcp.groupby("PATTERN_LEN")["RATE"].agg(["mean", "std"])
    plt.plot(grouped_tcp.index, grouped_tcp["mean"], label="Tcp")
    plt.errorbar(
        grouped_tcp.index, grouped_tcp["mean"], yerr=grouped_tcp["std"], fmt="o"
    )

    # Plot udp
    grouped_udp = df_udp.groupby("PATTERN_LEN")["RATE"].agg(["mean", "std"])
    plt.plot(grouped_udp.index, grouped_udp["mean"], label="Udp")
    plt.errorbar(
        grouped_udp.index, grouped_udp["mean"], yerr=grouped_udp["std"], fmt="o"
    )

    # Plot caida
    grouped_caida = df_caida.groupby("Key")["Loss"].agg(["mean", "std"])
    plt.plot(grouped_caida.index, 100 - grouped_caida["mean"] * 100, label="Caida")
    plt.errorbar(
        grouped_caida.index,
        100 - grouped_caida["mean"] * 100,
        yerr=grouped_caida["std"] * 100,
        fmt="o",
    )

    plt.title("Achievable rate vs Pattern Length")
    plt.xlabel("Pattern length")
    plt.ylabel("Rate (Mbps)")
    plt.legend()
    plt.ylim(bottom=0, top=100)

    plt.show()


if __name__ == "__main__":
    """
    Given two CSV files of iPerf results, plot teh achievable rate under tcp, udp, and CAIDA data. If no files are given, default filenames are used.
    """

    # Default file names
    filename = "~/cyd/analysis/results/iperf_results.csv"
    filename_caida = "~/cyd/analysis/results/results_pattern_rate_zurich_thun_caida.csv"

    # User specified file names
    if len(sys.argv) == 3:
        filename = sys.argv[1]
        filename_caida = sys.argv[2]

    df = pd.read_csv(filename)
    df_caida = pd.read_csv(filename_caida)

    plot_data(df, df_caida)
