import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import sys


def ecdf(data, upper_limit=1500):
    """
    Calculates an empirical cdf from the given data.
    """
    sorted_data = np.sort(data)  # O(nlogn) - Dominates complexity
    print(len(sorted_data))

    # Binary search to eliminate jumbo frames
    left, right = 0, len(sorted_data) - 1
    while left <= right:
        mid = (left + right) // 2
        if sorted_data[mid] <= upper_limit:
            left = mid + 1
        else:
            right = mid - 1

    sorted_data = sorted_data[:left]
    data_len = len(sorted_data)
    cdf = np.arange(1, data_len + 1) / data_len

    return sorted_data, cdf


def plot_ecdf(sorted_data, cdf, name):
    """
    Plots an empirical cdf from the given data.
    """
    plt.figure()
    plt.plot(sorted_data, cdf)
    plt.xlabel("IP lengths (B)")
    plt.ylabel("Probability")
    plt.title("ECDF")
    plt.grid(True)

    if name is not None:
        plt.savefig(f"/home/max/cyd/figures/lengths/ecdf_{name}.png")


def plot_epdf(sorted_data, name):
    """
    Plots an empirical pdf from the given data.
    """
    plt.figure()
    sns.histplot(sorted_data, kde=True, stat="density")
    plt.xlabel("IP lengths (B)")
    plt.ylabel("Probability density")
    plt.title("EPDF")
    plt.grid(True)

    if name is not None:
        plt.savefig(f"/home/max/cyd/figures/lengths/epdf_{name}.png")


def scale_data(data, new_max, current_max=1500):
    """
    Scales packet length given an MTU.
    """
    factor = new_max / current_max
    return [d * factor for d in data]


def get_value_given_prob(sorted_data, prob):
    """
    Get X given prob in the equation P[X] = prob.
    It assumes sorted data.
    """
    idx = int(prob * (len(sorted_data) - 1))
    return sorted_data[idx]


def get_patterns(sorted_data, low=1, high=8):
    for i in range(low, high + 1):
        print(f"Pattern of length {i}")
        for j in [x / i for x in range(1, i + 1)]:
            print(get_value_given_prob(sorted_data, j))


if __name__ == "__main__":
    """
    Given a csv file of packet lengths, get the efficient patterns and plot the emprirical PDF and CDF
    """

    # Whether to plot data or not
    is_plot_data = True
    # Whether to get efficient patterns or not
    is_get_patterns = True
    # Whether to scale data to a given MTU or simply set al the values above the MTU to the MTU
    is_scale_data = False
    # The maximum number of data points that will be used for the plots
    num_data_points = 1e6

    if len(sys.argv) < 2:
        print("Usage: python3 analyze_pkt_dist.py <filename>")
        exit(1)

    # A third argument can be given to save the file under the given name
    name = None
    if len(sys.argv) == 3:
        name = sys.argv[2]

    filename = sys.argv[1]

    # Get eCDF from data in csv file
    df = pd.read_csv(filename, nrows=int(num_data_points))
    sorted_data, cdf = ecdf(df["IpLength"])

    if is_scale_data:
        max_length = 1400
        sorted_data = scale_data(sorted_data, max_length)

    if is_get_patterns:
        get_patterns(sorted_data)

    # Average length
    MTU = 1400
    df[df > MTU] = MTU
    print(f"\nAverage packet length of {np.mean(df)}B")

    if is_plot_data:
        plot_ecdf(sorted_data, cdf, name)
        plot_epdf(sorted_data, name)
        plt.show()


# Efficient patterns from the first 1M datapoints of CAIDA
# [1500]
# [1400,1500]
# [200, 1480, 1500]
# [84, 1480, 1480, 1500]
# [60, 537, 1452, 1500, 1500]
# [52, 200, 1400, 1480, 1500, 1500]
# [52, 122, 937, 1452, 1480, 1500, 1500]
# [52, 84, 366, 1400, 1466, 1480, 1500, 1500]
