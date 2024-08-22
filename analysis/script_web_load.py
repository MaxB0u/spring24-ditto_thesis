import time
import subprocess
import sys
import psutil
import pandas as pd

VM_NAME = "dev-thun"


def get_load_time(page_name, page_ip):
    """
    Given a page name and its ip address, load it and record the time. The loading time includes opening a web browser and the cache is disabled for all tests.
    """

    # Command used
    command = f"ssh {VM_NAME} \"google-chrome-beta --disable-gpu --user-data-dir=$foo --host-resolver-rules='MAP *:80 {page_ip}:8080,MAP *:443 {page_ip}:8081,EXCLUDE localhost' --ignore-certificate-errors-spki-list=PhrPvGIaAMmd29hj8BCZOq096yj7uMpRNHpn5PDxI6I=,2HcXCSKKJS0lEXLQEWhpHUfGuojiU0tiT5gOF9LP6IQ= --disable-extensions http://{page_name}\""

    target_line = "Created TensorFlow Lite XNNPACK delegate for CPU."

    start_time = time.time()

    # Run the command
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=True,
        universal_newlines=True,
    )

    # Close the process after the loading is done and record the time
    while True:
        line = process.stderr.readline()
        if target_line in line:
            end_time = time.time()
            load_time = end_time - start_time
            print(f"{page_name} load time: {load_time * 1000} ms")
            process = subprocess.Popen(
                f'ssh {VM_NAME} "pkill -f chrome-beta"',
                shell=True,
                universal_newlines=True,
            )
            break

    return load_time


def log_run(filename, data, verbrose=False):
    """
    Log the given data to a filename for later analysis and plotting.
    """
    is_row_added = False
    # Create dataframe if file does not exist
    try:
        df = pd.read_csv(filename)
    except:
        columns = ["RunNum", "PatternLength", "Page", "Mode", "LoadTime"]
        df = pd.DataFrame(columns=columns)

    if not (
        (df["RunNum"] == data[0])
        & (df["PatternLength"] == data[1])
        & (df["Page"] == data[2])
    ).any():
        # Add line only if doesn't already exist
        df.loc[len(df)] = data
        is_row_added = True

    df.to_csv(filename, index=False)

    if is_row_added and verbrose:
        print(f"Saving data to {filename}")


def get_mode(ip_addr):
    match ip_addr:
        case "10.7.0.2":
            return "WIREGUARD"
        case "10.20.0.10":
            return "DITTO"
        case _:
            return "OTHER"


def check_if_already_in_csv(filename, pattern_len, run_num, page_name, mode):
    """
    Given a file name, pattern length, run number, page name and mode, check if the entry already exists in the file.
    """
    try:
        df = pd.read_csv(filename)
        df = df[df["PatternLength"] == pattern_len]
        df = df[df["RunNum"] == run_num]
        df = df[df["Page"] == page_name]
        df = df[df["Mode"] == mode]
    except FileNotFoundError:
        df = pd.DataFrame()

    return len(df) > 0


if __name__ == "__main__":
    """
    Given a web page name and its IP address, load it and log how much time it took. Optionally, specify a file to save the data in as well as a run number and the length of the pattern used.
    """

    if len(sys.argv) < 3:
        print(
            "USAGE: python3 web_load_time.py <web_page_name> <web_page_ip> OPTIONAL: <filename> <run_number> <pattern_length>"
        )
        sys.exit(1)

    # Web page name and its ip address
    # In our tests, the web pages were hosted on a VM and not on their usual web server although both would work if you don't need Ditto protected links only.
    page_name = sys.argv[1]
    page_ip = sys.argv[2]

    if len(sys.argv) == 6:
        # Log data if correct parameters are present and the page was loaded successfully
        filename = sys.argv[3]
        run_number = int(sys.argv[4])
        pattern_len = int(sys.argv[5])
        mode = get_mode(page_ip)

        # Only log the data if it is not already in the CSV file
        if check_if_already_in_csv(filename, pattern_len, run_number, page_name, mode):
            print("Entry already exists, skipping")
            exit(0)

        # Load the page and get the load time
        load_time = get_load_time(page_name, page_ip)

        # If the loading did not fail, log the data
        if load_time is not None:
            data = [run_number, pattern_len, page_name, mode, load_time]
            log_run(filename, data)
    else:
        # Here only get the load time, but do not log the data to a file
        get_load_time(page_name, page_ip)
