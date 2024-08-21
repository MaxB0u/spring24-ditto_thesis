import pandas as pd
import sys

# Skip first entries to reduce noise
OFFSET = 750000


def select_consecutive_entries(input_file, output_file, num_entries=1e6):
    df = pd.read_csv(input_file)
    num_entries = int(num_entries)

    # Make sure enough entries in file
    if len(df) < num_entries + OFFSET:
        print("Error: Input file does not have enough entries.")
        return

    sampled_df = df["Time"].iloc[OFFSET : num_entries + OFFSET]
    sampled_df.to_csv(output_file, index=False)

    print(
        f"Selected {num_entries} consecutive entries from {input_file} and wrote them to {output_file}"
    )


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <input_file> <output_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    select_consecutive_entries(input_file, output_file)
