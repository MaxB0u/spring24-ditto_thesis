import pandas as pd
import sys


def check_if_already_in_csv(filename, key, run_num):
    """
    Given a csv file name, a key and a run number, check if the entry is already in the file.
    """
    try:
        df = pd.read_csv(filename)
        df = df[df["Key"] == key]
        df = df[df["RunNum"] == run_num]
    except FileNotFoundError:
        df = pd.DataFrame()

    return len(df) > 0


def check_if_already_filled_csv(filename, num_keys=8, num_runs=30):
    """
    Given a csv file name, check if it already has num_keys * num_runs entries.
    """
    try:
        df = pd.read_csv(filename)
    except FileNotFoundError:
        df = pd.DataFrame()
    return len(df) >= num_keys * num_runs


if __name__ == "__main__":
    """
    Given a csv file name, a key in the file name and a run number, check if it already exists.
    """

    if len(sys.argv) < 4:
        print("Usage: python3 check_csv.py <filename> <key> <run_num>")
        exit(1)

    # CSV files in this repo are indexed with a unique combination of key and run number
    filename = sys.argv[1]
    key = float(sys.argv[2])
    run_num = float(sys.argv[3])

    if len(sys.argv) == 5:
        exists = check_if_already_filled_csv(filename, key, run_num)
    else:
        exists = check_if_already_in_csv(filename, key, run_num)
    print(exists)
