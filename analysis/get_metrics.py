import sys
import pandas as pd
import numpy as np
import csv


def analyze_losses(df_tx, df_rx, verbrose=False):
    """
    Given two dataframes, look at how many packets were recevied vs how many were sent
    """
    total_len = len(df_tx.index)
    num_loss = total_len - len(df_rx.index)

    loss = num_loss / total_len

    if verbrose:
        print(f"Lost {num_loss}pkts or {loss*100:.2f}% of all pkts")

    return len(df_rx), num_loss, loss


def analyze_latency(df_tx, df_rx, verbrose=False):
    """
    Given two dataframes, look at the difference in timestamps between packets with the same flow and sequence number
    """
    merged_df = pd.merge(
        df_tx, df_rx, on=["Seq", "Flow"], how="left", suffixes=("_tx", "_rx")
    )
    merged_df["latency"] = merged_df["Time_rx"] - merged_df["Time_tx"]

    sample_mean = np.mean(merged_df["latency"])
    sample_var = np.sum((merged_df["latency"] - sample_mean) ** 2) / (
        merged_df["latency"].count() - 1
    )
    sample_std = np.sqrt(sample_var)

    if verbrose:
        print(
            f"Average latency {sample_mean/1e6:.4f}ms with standard deviation of {sample_std/1e6:.4f}ms"
        )
        print(
            f"The max latency is {max(merged_df['latency'])/1e6:.4f}ms and the min is {min(merged_df['latency'])/1e6:.4f}ms\n"
        )

    return sample_mean, sample_std


def analyze_reordering(df_rx_sorted, df_rx, verbrose=False):
    """
    Given two dataframes, look at the difference in ordering between them
    """

    # The sorted version is the ideal order of arrival
    reordering = df_rx["Seq"].reset_index(drop=True) - df_rx_sorted["Seq"].reset_index(
        drop=True
    )
    reordering.loc[reordering < 0] = 0
    earliest_pkt = max(reordering)
    latest_pkt = np.abs(min(reordering))

    # Only look at the absolute value of reordering for the rest
    reordering = np.abs(reordering)
    sample_mean = np.mean(reordering)
    sample_var = np.sum((reordering - sample_mean) ** 2) / (len(reordering) - 1)
    sample_std = np.sqrt(sample_var)

    if verbrose:
        print(
            f"Average reordering of {int(sample_mean)}pkts with standard deviation of {int(sample_std)}pkts"
        )
        print(f"The earliest packet arrives {earliest_pkt}pkts in advance")
        print(f"The latest packet arrives {latest_pkt}pkts late\n")

    return sample_mean, sample_std, earliest_pkt, latest_pkt


def analyze_jitter_mult(df_rx, num_flows, single_flow_number=0, verbrose=False):
    """
    Given a dataframe and a number of flows, extract the per flow jitter
    """
    # Get the received packets grouped by flow
    jitters = []
    normalized_jitters = []
    if num_flows > 0:
        for i in range(num_flows):
            jitter_flow, normalized_jitter_flow = analyze_jitter_one_flow(df_rx, i)
            jitters.append(jitter_flow)
            normalized_jitters.append(normalized_jitter_flow)
    else:
        jitter_flow, normalized_jitter_flow = analyze_jitter_one_flow(
            df_rx, single_flow_number
        )
        jitters.append(jitter_flow)
        normalized_jitters.append(normalized_jitter_flow)

    jitter = np.mean(jitters)
    normalized_jitter = np.mean(normalized_jitters)

    if verbrose:
        print(f"Jitter in received packets of {jitter}%\n")

    return jitter, normalized_jitter


def analyze_jitter_one_flow(df_rx, flow_num):
    """
    Given a dataframe and a flow number, analyze the jitter in that flow
    """
    df_flow = df_rx[df_rx["Flow"] == flow_num].reset_index(drop=True)
    arrival_time = df_flow["Time"].to_numpy()
    time_diff = [np.abs(t - s) for s, t in zip(arrival_time, arrival_time[1:])]
    avg_time_diff = np.mean(time_diff)

    # Jitter is the average deviation from the average packet inter-arrival time
    jitter_flow = np.mean([np.abs(t - avg_time_diff) for t in time_diff])
    normalization_factor = len(arrival_time) / (arrival_time[-1] - arrival_time[0])
    normalized_jitter_flow = jitter_flow * normalization_factor

    return jitter_flow, normalized_jitter_flow


def analyze_out_of_order_mult(df_rx, num_flows, verbrose=False):
    """
    Given a dataframe and a number of flows, analyze the per flow out of order packet rate
    """
    # A packet is out of order when its seq number is lower than the highest seen so far#
    out_of_order = []
    for i in range(num_flows):
        df_flow = df_rx[df_rx["Flow"] == i].reset_index(drop=True)
        count = 0
        highest_seq = -1

        for seq in df_flow["Seq"]:
            if seq > highest_seq:
                highest_seq = seq
            else:
                # Out of order
                count += 1

        out_of_order.append(count)

    num_out_of_order = np.sum(out_of_order)

    if verbrose:
        print(
            f"{num_out_of_order}pkts are out of order or {num_out_of_order/len(df_rx)*100:.2f}% of all pkts\n"
        )

    return num_out_of_order, num_out_of_order / len(df_rx)


def analyze_pad(df_pad, df_pattern, verbrose=False):
    """
    Given a dataframe, extract the average padding that was used
    """
    # Can adjust data gathering to have something more interesting here
    mean_pad = np.mean(df_pad["Pad"])

    if verbrose:
        print(
            f"Average padding of {int(mean_pad)}B for {''.join(list(df_pattern.columns))}\n"
        )

    return mean_pad


def log_run(filename, data, run_num=None, verbrose=False):
    """
    Given a file name, log he extracted metrics into it. The file should be a CSV file
    """
    is_row_added = False
    # Create dataframe if file does not exist
    try:
        df = pd.read_csv(filename)
    except:
        columns = [
            "Key",
            "RunNum",
            "LatAvg",
            "LatStd",
            "Jitter",
            "NormJitter",
            "ReordAvg",
            "ReordStd",
            "ReordEarliest",
            "ReordLatest",
            "NumOutOfOrder",
            "OutOfOrder",
            "NumReceived",
            "NumLoss",
            "Loss",
            "PadAvg",
        ]
        df = pd.DataFrame(columns=columns)

    # Check if the entry is already in the csv. Do not save if it already is.
    if run_num is None:
        if not (df["Key"] == data[0]).any():
            df.loc[len(df)] = data
            is_row_added = True
    else:
        if not ((df["Key"] == data[0]) & (df["RunNum"] == data[1])).any():
            df.loc[len(df)] = data
            is_row_added = True

    df.to_csv(filename, index=False)

    if is_row_added and verbrose:
        print(f"Saving data to {filename}")


def get_site(filename):
    """
    Given a file name, get if the data comes from the thun, zurich, or lausanne site
    """
    if "zurich" in filename:
        return "zurich"
    elif "thun" in filename:
        return "thun"
    else:
        return "lausanne"


if __name__ == "__main__":
    """
    Given packet sequence number, timestamps, and flow number, extract metrics from them that will then be useful for our analysis.
    """

    # By default, do not analyze padding
    is_analyze_pad = False
    # Whether to log the output of the calculations to the terminal or not
    verbrose = True
    # Default filename to save the data into
    filename = "~/cyd/analysis/results/default.csv"

    # Get files with data
    if len(sys.argv) < 3:
        print("Usage: python3 get_metrics.py <tx_file> <rx_file>")
        exit(1)
    else:
        tx_file = sys.argv[1]
        rx_file = sys.argv[2]

    # Get the site name to save the data in different filenames for different sites (thun, zurich, lausanne)
    site = get_site(tx_file)

    # Get key
    key = None
    if len(sys.argv) >= 4:
        key = float(sys.argv[3])
    data = [key]

    # Get run number
    run_number = None
    if len(sys.argv) >= 5:
        run_number = int(sys.argv[4])
        data.append(run_number)

    # Get file to save data to
    if len(sys.argv) >= 6:
        filename = sys.argv[5]

    # Get whether to analyze padding or not
    if len(sys.argv) >= 7:
        is_analyze_pad = sys.argv[6] == "True"

    num_flows = 1
    # Get the number of flows
    if len(sys.argv) >= 8:
        num_flows = int(sys.argv[7])

        if num_flows > 0:
            for i in range(num_flows):
                tx_file = f"~/cyd/remote/{site}/sender_receiver/tx_data_{i}.csv"
                if i == 0:
                    df_tx = pd.read_csv(tx_file)
                else:
                    df_tmp = pd.read_csv(tx_file)
                    df_tx = pd.concat([df_tx, df_tmp], ignore_index=True)
        else:
            df_tx = pd.read_csv(tx_file)
    else:
        df_tx = pd.read_csv(tx_file)

    flow = -1
    # Get a specific flow number
    if len(sys.argv) == 9:
        flow = int(sys.argv[8])

    # Read and filter data
    df_rx = pd.read_csv(rx_file)
    if flow != -1:
        df_rx = df_rx[df_rx["Flow"] == flow].reset_index(drop=True)

    df_rx_filtered = df_rx[df_rx["Seq"] <= df_tx.shape[0]].reset_index(drop=True)
    df_rx_filtered = df_rx_filtered[df_rx_filtered["Seq"] > 0].reset_index(drop=True)
    df_rx_sorted_flow = df_rx_filtered.groupby("Flow", sort=False).apply(
        lambda x: x.reset_index(drop=True), include_groups=False
    )
    df_rx_sorted_flow = df_rx_sorted_flow.reset_index()
    df_rx_sorted = df_rx_filtered.sort_values(by=["Flow", "Seq"]).reset_index(drop=True)

    # Log info about the dataframes
    if verbrose:
        print(
            f"tx: {len(df_tx)} \nrx: {len(df_rx)} \nrx_filtered: {len(df_rx_filtered)} \nrx_sorted_flow: {len(df_rx_sorted_flow)} \nrx_sorted: {len(df_rx_sorted)} "
        )

    # Analyze data
    data.extend(analyze_latency(df_tx, df_rx_filtered, verbrose=verbrose))
    data.extend(
        analyze_jitter_mult(
            df_rx_sorted_flow, num_flows, single_flow_number=flow, verbrose=verbrose
        )
    )
    data.extend(analyze_reordering(df_rx_sorted, df_rx_sorted_flow, verbrose=verbrose))
    data.extend(
        analyze_out_of_order_mult(df_rx_sorted_flow, num_flows, verbrose=verbrose)
    )
    data.extend(analyze_losses(df_tx, df_rx_filtered, verbrose=verbrose))

    if is_analyze_pad:
        # Analyze padding only if needed or else put 0 in the padding column
        df_pad = pd.read_csv("~/cyd/remote/zurich/budget_ditto/pad.csv")
        df_pattern = pd.read_csv(
            "~/cyd/remote/zurich/budget_ditto/parameters.csv", skiprows=2
        )
        data.append(analyze_pad(df_pad, df_pattern, verbrose=verbrose))
    else:
        # No padding
        data.append(0)

    # Save data
    if key is not None:
        log_run(filename, data, run_number, verbrose=True)
