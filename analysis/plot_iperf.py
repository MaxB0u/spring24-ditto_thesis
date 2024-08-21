import sys
import pandas as pd
import matplotlib.pyplot as plt


def plot_data(df, df_caida):
    df_tcp = df[df["PROTOCOL"] == "tcp"]
    df_udp = df[df["PROTOCOL"] == "udp"]

    # Plot tcp, udp, and caida
    plt.figure()
    grouped_tcp = df_tcp.groupby("PATTERN_LEN")["RATE"].agg(["mean", "std"])
    plt.plot(grouped_tcp.index, grouped_tcp["mean"], label="Tcp")
    plt.errorbar(
        grouped_tcp.index, grouped_tcp["mean"], yerr=grouped_tcp["std"], fmt="o"
    )

    grouped_udp = df_udp.groupby("PATTERN_LEN")["RATE"].agg(["mean", "std"])
    plt.plot(grouped_udp.index, grouped_udp["mean"], label="Udp")
    plt.errorbar(
        grouped_udp.index, grouped_udp["mean"], yerr=grouped_udp["std"], fmt="o"
    )

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
    is_plot_data = True
    filename = "~/cyd/analysis/results/iperf_results.csv"
    filename_caida = "~/cyd/analysis/results/results_pattern_rate_zurich_thun_caida.csv"

    if len(sys.argv) == 3:
        filename = sys.argv[1]
        filename_caida = sys.argv[1]

    df = pd.read_csv(filename)
    print(df.head())
    print(len(df))

    df_caida = pd.read_csv(filename_caida)

    if is_plot_data:
        plot_data(df, df_caida)
