import sys
import pandas as pd
import re
import matplotlib.pyplot as plt
import numpy as np

# Conversion factor between bits and bytes
BITS_PER_BYTE = 8


def plot_data(df, df_background):
    """
    Plot the delays. One plot for time vs pattern length, and one for time vs background traffic rate
    """

    # Get the data needed from the dataframe of time vs pattern
    data = (
        df.groupby(["Page", "PatternLength"])
        .agg({"LoadTime": ["mean", "std"]})
        .reset_index()
    )
    data.columns = ["Page", "PatternLength", "LoadTime_mean", "LoadTime_std"]

    # Plot time vs pattern
    plt.figure()
    for page in data["Page"].unique():
        page_data = data[data["Page"] == page]
        plt.errorbar(
            page_data["PatternLength"],
            page_data["LoadTime_mean"],
            yerr=page_data["LoadTime_std"],
            marker="o",
            label=page,
        )

    plt.title("Average Loading Time vs Pattern Length")
    plt.xlabel("Pattern Length")
    plt.ylabel("Loading Time (s)")
    plt.legend(prop={"size": 8}, ncol=2)
    plt.yticks(np.arange(0, 21, step=2))
    plt.ylim(bottom=0, top=20)

    # Get the data needed from the dataframe of time vs background traffic rate
    data = (
        df_background.groupby(["Page", "Rate"])
        .agg({"LoadTime": ["mean", "std"]})
        .reset_index()
    )
    data.columns = ["Page", "Rate", "LoadTime_mean", "LoadTime_std"]

    # Plot time vs background traffic rate
    plt.figure()
    for page in data["Page"].unique():
        page_data = data[data["Page"] == page]
        plt.errorbar(
            page_data["Rate"],
            page_data["LoadTime_mean"],
            yerr=page_data["LoadTime_std"],
            marker="o",
            label=page,
        )

    plt.title("Average Loading Time vs Background traffic rate")
    plt.xlabel("Background traffic rate (Mbps)")
    plt.ylabel("Loading Time (s)")
    plt.legend()
    plt.ylim(bottom=0)

    plt.show()


if __name__ == "__main__":
    """
    Given two CSV files of web loading results, plot the loading time vs pattern length and the loading time vs background traffic rate. If no files are given, default filenames are used.
    """
    
    # Default file names
    filename = "~/cyd/tests/web_results.csv"
    filename_background = "~/cyd/remote/thun/web/web_results_background_traffic.csv"

    # User specified file names
    if len(sys.argv) == 3:
        filename = sys.argv[1]
        filename_background = sys.argv[2]

    df = pd.read_csv(filename)
    df_background = pd.read_csv(filename_background)

    plot_data(df, df_background)
