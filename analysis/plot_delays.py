import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.metrics import roc_curve
import sys


def get_data(filename):
    """
    Given a filename, return a panda dataframe with its data. The file should be a CSV file.
    """
    df = pd.read_csv(filename)
    return df


def get_optimal_threshold(df_traff, df_no_traff):
    """
    Given two CSV files of timings, get the optimal threshold to classify from which file the data comes from
    """

    df = pd.concat([df_traff, df_no_traff], ignore_index=True)

    # Compute ROC curve
    fpr, tpr, thresholds = roc_curve(df["Traffic"], df["Time"])
    opt_idx = np.argmax(tpr - fpr)
    opt_idx = np.argmin(tpr - fpr)
    optimal_threshold = thresholds[opt_idx]
    print(f"Optimal Threshold: {optimal_threshold}ns")

    # Assume longer delays means real traffic
    opt_acc = sum(df["Traffic"] == (df["Time"] > optimal_threshold)) / len(df)
    print(
        f"The optimal accuracy of the classifier is {opt_acc}. TPR @ FPR {fpr[opt_idx]*100:.2f}%: {tpr[opt_idx]*100:.2f}%"
    )

    target_fpr = 0.01
    target_fpr_idx = np.argmax(np.where(fpr <= target_fpr, fpr, np.zeros_like(fpr)))
    print(f"TPR @ FPR {target_fpr*100:.2f}%: {tpr[target_fpr_idx]*100:.2f}%")

    print(
        f"No traffic, number samples above threshold: {sum(df_no_traff['Time'] > optimal_threshold)}"
    )
    print(
        f"Traffic, number samples above threshold: {sum(df_traff['Time'] > optimal_threshold)}"
    )

    return optimal_threshold


def plot_delays(file_no_traff, file_traff):
    """
    Given two CSV files of timings, plot the eCDF of the timings and the optimal threshold for classification
    """

    # Get data
    df_no_traff = get_data(file_no_traff)
    df_no_traff["Traffic"] = False
    df_traff = get_data(file_traff)
    df_traff["Traffic"] = True

    # Get threshold
    opt_th = get_optimal_threshold(df_traff, df_no_traff)

    # Plot delays
    sns.ecdfplot(df_no_traff["Time"], label="CDF no traffic, only chaff")
    sns.ecdfplot(df_traff["Time"], label="CDF traffic at 80 Mbps")

    plt.xlabel("Time to send packet (µs)")
    plt.ylabel("Probability")
    plt.title(f"Cummulative Density Function for {len(df_traff)} data points")
    plt.axvline(x=opt_th, color="r", linestyle="--")

    plt.legend()
    plt.show()


if __name__ == "__main__":
    """
    Given two CSV files of timings, analyze the differences between them and how the data could be optimally classified
    """
    if len(sys.argv) != 3:
        print("Usage: python3 plot_delays.py <file 1 (no traffic)> <file 2 (traffic)>")
        sys.exit(1)

    # The first file should be the timings when only chaff packets are sent on the network
    file_no_traff = sys.argv[1]
    # The second file should be the timings when real traffic is also sent on the network
    file_traff = sys.argv[2]

    plot_delays(file_no_traff, file_traff)
