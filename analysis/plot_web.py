import sys
import pandas as pd
import re
import matplotlib.pyplot as plt

BITS_PER_BYTE = 8


def plot_data(df):
    # Plot time
    plt.figure()
    grouped = df.groupby("Size")["Time"].agg(["mean", "std"])
    plt.plot(grouped.index, grouped["mean"], label="Ditto")
    plt.errorbar(grouped.index, grouped["mean"], yerr=grouped["std"], fmt="o")
    plt.title("Average Time vs Request Size")
    plt.xlabel("Size (MB)")
    plt.ylabel("Time (s)")
    plt.legend()
    plt.ylim(bottom=0)

    # Plot speed
    plt.figure()
    grouped = df.groupby("Size")["Speed"].agg(["mean", "std"])
    plt.plot(grouped.index, grouped["mean"], label="Ditto")
    plt.errorbar(grouped.index, grouped["mean"], yerr=grouped["std"], fmt="o")
    plt.title("Average Speed vs Request Size")
    plt.xlabel("Size (MB)")
    plt.ylabel("Speed (Mbps)")
    plt.legend()
    plt.ylim(bottom=0)

    plt.show()


def parse_files(file_str):
    pattern = "Downloaded: (\d+) files"

    match = re.match(pattern, file_str)
    if match:
        files = int(match.group(1))
        return pd.Series([files], index=["Numfiles"])
    else:
        return pd.Series(["NaN"], index=["Numfiles"])


def parse_results(res_str):
    """
    Parse the web loading results and plot them. Used for programs like curl and wget. These were not used in the final results, but were used in some tests.
    """
    # Split df['Result'] in
    # num files, length, time, speed
    pattern = r" ([\d.]+)([A-Z]+) in ([\d.]+)s \(([\d.]+) ([A-Z]+)\/s\)"

    match = re.match(pattern, res_str)
    if match:
        size = float(match.group(1))
        size_unit = match.group(2)
        time = float(match.group(3))
        speed = float(match.group(4)) * BITS_PER_BYTE
        speed_unit = match.group(5)

        size_unit = size_unit.lower()
        speed_unit = speed_unit.lower()

        # Base is in M for size and Mbps for speed
        if size_unit[0] == "k":
            size /= 1e3
        if speed_unit[0] == "k":
            speed /= 1e3

        # Return parsed values
        return pd.Series([size, time, speed], index=["Size", "Time", "Speed"])
    else:
        return pd.Series(["NaN", "NaN", "NaN"], index=["Size", "Time", "Speed"])


def get_data(filename):
    """
    Get the data from a csv file in a dataframe. Parse the data and return it.
    """
    df = pd.read_csv(filename)
    df[["Numfiles"]] = df["Numfiles"].apply(parse_files)
    df[["Size", "Time", "Speed"]] = df["Result"].apply(parse_results)
    df = df.drop("Result", axis=1)
    return df


if __name__ == "__main__":
    """
    Given a CSV file, plot the time of web results over curl or wget.
    """
    
    # Default filename
    filename = "~/cyd/remote/zurich/analysis/download_results.csv"

    # User specified filename
    if len(sys.argv) == 2:
        filename = sys.argv[1]

    df = get_data(filename)
    plot_data(df)
