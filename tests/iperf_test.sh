#!/usr/bin/bash

echo "Starting iperf tests..."

NUM_RUNS=30
IPERF_DURATION=10
# RATE=100.0
OVERWRITE_RESULTS=false
TEST_TCP=false
TEST_UDP=true

PATTERNS=(
        "pub const PATTERN: [usize; 1] = [1400];"
        "pub const PATTERN: [usize; 2] = [1400, 1400];"
        "pub const PATTERN: [usize; 3] = [200, 1400, 1400];"
        "pub const PATTERN: [usize; 4] = [84, 1400, 1400, 1400];"
        "pub const PATTERN: [usize; 5] = [60, 537, 1400, 1400, 1400];"
        "pub const PATTERN: [usize; 6] = [52, 200, 1400, 1400, 1400, 1400];"
        "pub const PATTERN: [usize; 7] = [52, 122, 937, 1400, 1400, 1400, 1400];"
        "pub const PATTERN: [usize; 8] = [52, 84, 366, 1400, 1400, 1400, 1400, 1400];"
)

USER_LOCAL='max'

OUTPUT_FILE="/home/$USER_LOCAL/cyd/analysis/results/iperf_results.csv"

# Set to empty string if want to see console output
SUPPRESS_CONSOLE_OUTPUT="> /dev/null 2>&1"
# SUPPRESS_CONSOLE_OUTPUT=""

VM_SENDER='zurich'
VM_RECEIVER='thun'

ADDR_THUN="10.7.0.1"
ADDR_ZURICH="10.7.0.2"
ADDR_LAUSANNE="10.7.0.3"

# Set dst for sender in ditto config and dst in sender_receiver config
dst_ditto=$(ssh dev-$VM_SENDER "grep 'dst=' /home/lab/$USER_LOCAL/budget_ditto/config/config_client_$VM_SENDER.toml")
dst_sr=$(ssh dev-$VM_SENDER "grep 'dst=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
if [ "$VM_RECEIVER" = "thun" ]; then
    ssh dev-$VM_SENDER "sed -i \"s/$dst_ditto/dst='$ADDR_THUN'/g\" /home/lab/$USER_LOCAL/budget_ditto/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_SENDER "sed -i \"s/$dst_sr/dst='$ADDR_THUN'/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
elif [ "$VM_RECEIVER" = "zurich" ]; then
    ssh dev-$VM_SENDER "sed -i \"s/$dst_ditto/dst='$ADDR_ZURICH'/g\" /home/lab/$USER_LOCAL/budget_ditto/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_SENDER "sed -i \"s/$dst_sr/dst='$ADDR_ZURICH'/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
elif [ "$VM_RECEIVER" = "lausanne" ]; then
    ssh dev-$VM_SENDER "sed -i \"s/$dst_ditto/dst='$ADDR_LAUSANNE'/g\" /home/lab/$USER_LOCAL/budget_ditto/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_SENDER "sed -i \"s/$dst_sr/dst='$ADDR_LAUSANNE'/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
fi

# Set dst for receiver in ditto config and dsr in sender_receiver config
dst_ditto=$(ssh dev-$VM_RECEIVER "grep 'dst=' /home/lab/$USER_LOCAL/budget_ditto/config/config_client_$VM_RECEIVER.toml")
dst_sr=$(ssh dev-$VM_RECEIVER "grep 'dst=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
if [ "$VM_SENDER" = "thun" ]; then
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_ditto/dst='$ADDR_THUN'/g\" /home/lab/$USER_LOCAL/budget_ditto/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_sr/dst='$ADDR_THUN'/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
elif [ "$VM_SENDER" = "zurich" ]; then
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_ditto/dst='$ADDR_ZURICH'/g\" /home/lab/$USER_LOCAL/budget_ditto/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_sr/dst='$ADDR_ZURICH'/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
elif [ "$VM_SENDER" = "lausanne" ]; then
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_ditto/dst='$ADDR_LAUSANNE'/g\" /home/lab/$USER_LOCAL/budget_ditto/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_sr/dst='$ADDR_LAUSANNE'/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
fi

sshfs dev-$VM_SENDER:/home/lab/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_SENDER
sshfs dev-$VM_RECEIVER:/home/lab/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_RECEIVER

pwd_file_sender="/home/$USER_LOCAL/cyd/remote/.auth/$VM_SENDER"
pwd_sender=$(<"$pwd_file_sender")
pwd_sender=$(echo "$pwd_sender" | tr -d '\n')

pwd_file_receiver="/home/$USER_LOCAL/cyd/remote/.auth/$VM_RECEIVER"
pwd_receiver=$(<"$pwd_file_receiver")
pwd_receiver=$(echo "$pwd_receiver" | tr -d '\n')

cmd_ditto_sender="cd $USER_LOCAL/budget_ditto && echo $pwd_sender | sudo -S -E /home/lab/.cargo/bin/cargo run config/config_client_$VM_SENDER.toml $SUPPRESS_CONSOLE_OUTPUT"
cmd_ditto_receiver="cd $USER_LOCAL/budget_ditto && echo $pwd_receiver | sudo -S -E /home/lab/.cargo/bin/cargo run config/config_client_$VM_RECEIVER.toml $SUPPRESS_CONSOLE_OUTPUT"

cmd_iperf_server="echo '$pwd_receiver' | sudo -S iperf3 -s -B 10.30.0.20 -p 8000 $SUPPRESS_CONSOLE_OUTPUT"

# Kill lingering processes
ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto"

if $OVERWRITE_RESULTS; then
    echo "RUN_NUM,PATTERN_LEN,RATE,PROTOCOL,LOSS" > $OUTPUT_FILE
fi

if $TEST_TCP; then
    echo "Running tcp tests"
    cmd_iperf_client="echo '$pwd_sender' | sudo -S iperf3 -c 10.30.0.20 -B 10.20.0.10 -p 8000 -t $IPERF_DURATION | awk '/receiver/ {print \$7}'"

    ssh dev-$VM_RECEIVER "$cmd_iperf_server" &
    for ((i=0; i < ${#PATTERNS[@]}; i++)); do

        # Set pattern
        pattern="${PATTERNS[i]}"
        pattern_sender=$(ssh dev-$VM_SENDER "grep 'pub const PATTERN' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs")
        pattern_receiver=$(ssh dev-$VM_RECEIVER "grep 'pub const PATTERN' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs")
        pattern_sender="${pattern_sender//[/\\[}"
        pattern_receiver="${pattern_receiver//[/\\[}"
        ssh dev-$VM_SENDER "sed -i 's/$pattern_sender/$pattern/g' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs"
        ssh dev-$VM_RECEIVER "sed -i 's/$pattern_receiver/$pattern/g' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs"

        # Start ditto in sender and receiver
        ssh dev-$VM_SENDER "$cmd_ditto_sender" &
        ssh dev-$VM_RECEIVER "$cmd_ditto_receiver" &

        pattern_idx=$((i+1))

        sleep 2
        for ((j=1; j<=NUM_RUNS; j++)); do
            echo "Run $j"
            throughput=$(ssh dev-$VM_SENDER "$cmd_iperf_client")
            echo "$j,$pattern_idx,$throughput,tcp,0" >> $OUTPUT_FILE
        done

        ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
        ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto"
        sleep 1



    done
    ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill iperf"
fi

if $TEST_UDP; then
    echo "Running udp tests"
    cmd_iperf_client="echo '$pwd_sender' | sudo -S iperf3 -c 10.30.0.20 -B 10.20.0.10 -p 8000 -t $IPERF_DURATION -u -b 100M | awk '/receiver/'"

    ssh dev-$VM_RECEIVER "$cmd_iperf_server" &
    for ((i=0; i < ${#PATTERNS[@]}; i++)); do

        # Set pattern
        pattern="${PATTERNS[i]}"
        pattern_sender=$(ssh dev-$VM_SENDER "grep 'pub const PATTERN' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs")
        pattern_receiver=$(ssh dev-$VM_RECEIVER "grep 'pub const PATTERN' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs")
        pattern_sender="${pattern_sender//[/\\[}"
        pattern_receiver="${pattern_receiver//[/\\[}"
        ssh dev-$VM_SENDER "sed -i 's/$pattern_sender/$pattern/g' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs"
        ssh dev-$VM_RECEIVER "sed -i 's/$pattern_receiver/$pattern/g' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs"

        # Start ditto in sender and receiver
        ssh dev-$VM_SENDER "$cmd_ditto_sender" &
        ssh dev-$VM_RECEIVER "$cmd_ditto_receiver" &

        pattern_idx=$((i+1))

        sleep 2
        for ((j=1; j<=NUM_RUNS; j++)); do
            echo "Run $j"
            result=$(ssh dev-$VM_SENDER "$cmd_iperf_client")
            throughput=$(echo "$result" | awk '{print $7}')
            loss=$(echo "$result" | awk -F'[()]' '{print $2}' | tr -d '%')

            echo "$j,$pattern_idx,$throughput,udp,$loss" >> $OUTPUT_FILE
        done

        ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
        ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto"
        sleep 1



    done
    ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill iperf"
fi