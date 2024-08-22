import pandas as pd
import sys

# Skip first entries to reduce noise
OFFSET = 750000


def select_consecutive_entries(input_file, output_file, num_entries=1e6):
    """
    Skip the first entries of the file and select 1M entries after to be sent to the output file.
    """

    # Get the data
    df = pd.read_csv(input_file)
    num_entries = int(num_entries)

    # Make sure enough entries in file
    if len(df) < num_entries + OFFSET:
        print("Error: Input file does not have enough entries.")
        return

    # Select the entries and save to the output
    sampled_df = df["Time"].iloc[OFFSET : num_entries + OFFSET]
    sampled_df.to_csv(output_file, index=False)

    # Show info on the console
    print(
        f"Selected {num_entries} consecutive entries from {input_file} and wrote them to {output_file}"
    )


if __name__ == "__main__":
    """
    Given a file with logged packets, skip the first entries, log 1 million packets and save it to another file. This file is used for maual tests where not all the process were started for the first few packets.
    """

    if len(sys.argv) != 3:
        print("Usage: python3 script.py <input_file> <output_file>")
        sys.exit(1)

    # Get the input and output file
    input_file = sys.argv[1]
    output_file = sys.argv[2]

    # Skip the first entries and select 1M entries after
    select_consecutive_entries(input_file, output_file)
