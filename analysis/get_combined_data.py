import pandas as pd
import sys


def get_combined_column(df_combined, df_voip, df_web, column_name, action):
    """
    Given three data frames, a column name, and an action, combine the data in the voip and web dataframe to the combined dataframe.
    """

    # Choose how to combine based on the action
    if action == "w":
        weights_voip = df_voip["NumReceived"] + df_voip["NumLoss"]
        weights_web = df_web["NumReceived"] + df_web["NumLoss"]
        df_combined[column_name] = df_voip[column_name] * weights_voip / (
            weights_voip + weights_web
        ) + df_web[column_name] * weights_web / (weights_voip + weights_web)
        return df_combined
    elif action == "+":
        df_combined[column_name] = df_voip[column_name] + df_web[column_name]
        return df_combined
    else:
        return df_combined


if __name__ == "__main__":
    """
    Given the resutls of the backbone tests, combined the results from the VoIP and teh web flow. This file defines for which value we should do an addition, an averag, or a weighted average.
    '+' is for addition
    'w' is for weighted average
    '' is for keeping the value as is
    """
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
    actions = [
        "+",
        "",
        "w",
        "w",
        "w",
        "w",
        "w",
        "w",
        "w",
        "w",
        "+",
        "+",
        "+",
        "+",
        "w",
        "w",
    ]

    if len(sys.argv) < 2:
        print("Usage: python3 get_combined_data.py <Ditto rate(Mbps)>")
        sys.exit(1)

    rate = int(float(sys.argv[1]))
    # The rate should be 100 or 200 Mbps
    if rate == 100:
        file_voip = "results/results_backbone_voip_100_p6.csv"
        file_web = "results/results_backbone_web_100_p6.csv"
    elif rate == 200:
        file_voip = "results/results_backbone_voip_200_p6.csv"
        file_web = "results/results_backbone_web_200_p6.csv"
    else:
        print("Data only exists for 100Mbps and 200Mbps")
        sys.exit(1)

    # Get the dataframes
    df_voip = pd.read_csv(file_voip)
    df_web = pd.read_csv(file_web)
    df_combined = df_voip.copy()

    # Combine data column by column
    for i in range(len(columns)):
        df_combined = get_combined_column(
            df_combined, df_voip, df_web, columns[i], actions[i]
        )

    df_combined.to_csv(f"results/results_backbone_combined_{rate}_p6.csv", index=False)
