#!/usr/bin/bash

echo "Starting metric tests..."

RUN_DITTO=true
RUN_NORMAL=false
RUN_PATTERN=false
RUN_MULTIPLE_FLOWS=false
RUN_SPECIAL_MULT_FLOWS=false
RUN_PATTERN_RATE=false
RUN_VIDEO=false

USE_CAIDA=false

NUM_RUNS=30
RATES=("1.0" "10.0" "50.0" "66.0" "70.0" "75.0" "80.0" "90.0" "100.0")

# Set to empty string if want to see console output
SUPPRESS_CONSOLE_OUTPUT="> /dev/null 2>&1"
SUPPRESS_CONSOLE_OUTPUT=""

# Sender
VM_SENDER='zurich'
VM_RECEIVER='lausanne'

if [ "$VM_SENDER" = "thun" ]; then
    USER_SENDER='lab'
elif [ "$VM_SENDER" = "zurich" ]; then
    USER_SENDER='lab'
elif [ "$VM_SENDER" = "lausanne" ]; then
    USER_SENDER='ubuntu'
fi

if [ "$VM_RECEIVER" = "thun" ]; then
    USER_RECEIVER='lab'
elif [ "$VM_RECEIVER" = "zurich" ]; then
    USER_RECEIVER='lab'
elif [ "$VM_RECEIVER" = "lausanne" ]; then
    USER_RECEIVER='ubuntu'
fi

USER_LOCAL='max'

RESULT_FILE_SUFFIX=""

if $USE_CAIDA; then
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
    dataset_sender=$(ssh dev-$VM_SENDER "grep 'dataset' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    dataset_receiver=$(ssh dev-$VM_RECEIVER "grep 'dataset' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_SENDER "sed -i \"s/$dataset_sender/dataset='caida'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dataset_receiver/dataset='caida'/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

    RESULT_FILE_SUFFIX="caida"
else 
    PATTERNS=(
        "pub const PATTERN: [usize; 1] = [1400];"
        "pub const PATTERN: [usize; 2] = [700, 1400];"
        "pub const PATTERN: [usize; 3] = [467, 933, 1400];"
        "pub const PATTERN: [usize; 4] = [350, 700, 1050, 1400];"
        "pub const PATTERN: [usize; 5] = [280, 560, 840, 1120, 1400];"
        "pub const PATTERN: [usize; 6] = [233, 467, 700, 933, 1167, 1400];"
        "pub const PATTERN: [usize; 7] = [200, 400, 600, 800, 1000, 1200, 1400];"
        "pub const PATTERN: [usize; 8] = [175, 350, 525, 700, 875, 1050, 1225, 1400];"
    )
    dataset_sender=$(ssh dev-$VM_SENDER "grep 'dataset' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    dataset_receiver=$(ssh dev-$VM_RECEIVER "grep 'dataset' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_SENDER "sed -i \"s/$dataset_sender/dataset=''/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dataset_receiver/dataset=''/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
fi

ADDR_THUN="10.7.0.1"
ADDR_ZURICH="10.7.0.2"
ADDR_LAUSANNE="10.7.0.3"

# Set dst for sender in ditto config and dst in sender_receiver config
dst_ditto=$(ssh dev-$VM_SENDER "grep 'dst=' /home/$USER_SENDER/$USER_LOCAL/budget_ditto/config/config_client_$VM_SENDER.toml")
dst_sr=$(ssh dev-$VM_SENDER "grep 'dst=' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
if [ "$VM_RECEIVER" = "thun" ]; then
    ssh dev-$VM_SENDER "sed -i \"s/$dst_ditto/dst='$ADDR_THUN'/g\" /home/$USER_SENDER/$USER_LOCAL/budget_ditto/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_SENDER "sed -i \"s/$dst_sr/dst='$ADDR_THUN'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
elif [ "$VM_RECEIVER" = "zurich" ]; then
    ssh dev-$VM_SENDER "sed -i \"s/$dst_ditto/dst='$ADDR_ZURICH'/g\" /home/$USER_SENDER/$USER_LOCAL/budget_ditto/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_SENDER "sed -i \"s/$dst_sr/dst='$ADDR_ZURICH'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
elif [ "$VM_RECEIVER" = "lausanne" ]; then
    ssh dev-$VM_SENDER "sed -i \"s/$dst_ditto/dst='$ADDR_LAUSANNE'/g\" /home/$USER_SENDER/$USER_LOCAL/budget_ditto/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_SENDER "sed -i \"s/$dst_sr/dst='$ADDR_LAUSANNE'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
fi

# Set dst for receiver in ditto config and dsr in sender_receiver config
dst_ditto=$(ssh dev-$VM_RECEIVER "grep 'dst=' /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/config/config_client_$VM_RECEIVER.toml")
dst_sr=$(ssh dev-$VM_RECEIVER "grep 'dst=' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
if [ "$VM_SENDER" = "thun" ]; then
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_ditto/dst='$ADDR_THUN'/g\" /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_sr/dst='$ADDR_THUN'/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
elif [ "$VM_SENDER" = "zurich" ]; then
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_ditto/dst='$ADDR_ZURICH'/g\" /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_sr/dst='$ADDR_ZURICH'/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
elif [ "$VM_SENDER" = "lausanne" ]; then
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_ditto/dst='$ADDR_LAUSANNE'/g\" /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_sr/dst='$ADDR_LAUSANNE'/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
fi

sshfs dev-$VM_SENDER:/home/$USER_SENDER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_SENDER
sshfs dev-$VM_RECEIVER:/home/$USER_RECEIVER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_RECEIVER

pwd_file_sender="/home/$USER_LOCAL/cyd/remote/.auth/$VM_SENDER"
pwd_sender=$(<"$pwd_file_sender")
pwd_sender=$(echo "$pwd_sender" | tr -d '\n')

pwd_file_receiver="/home/$USER_LOCAL/cyd/remote/.auth/$VM_RECEIVER"
pwd_receiver=$(<"$pwd_file_receiver")
pwd_receiver=$(echo "$pwd_receiver" | tr -d '\n')

cmd_ditto_sender="cd $USER_LOCAL/budget_ditto && echo $pwd_sender | sudo -S -E /home/$USER_SENDER/.cargo/bin/cargo run config/config_client_$VM_SENDER.toml $SUPPRESS_CONSOLE_OUTPUT"
cmd_ditto_receiver="cd $USER_LOCAL/budget_ditto && echo $pwd_receiver | sudo -S -E /home/$USER_RECEIVER/.cargo/bin/cargo run config/config_client_$VM_RECEIVER.toml $SUPPRESS_CONSOLE_OUTPUT"

cmd_sender="cd $USER_LOCAL/sender_receiver && echo $pwd_sender | sudo -S -E /home/$USER_SENDER/.cargo/bin/cargo run config/config_client_$VM_SENDER.toml $SUPPRESS_CONSOLE_OUTPUT"
cmd_receiver="cd $USER_LOCAL/sender_receiver && echo $pwd_receiver | sudo -S -E /home/$USER_RECEIVER/.cargo/bin/cargo run config/config_client_$VM_RECEIVER.toml $SUPPRESS_CONSOLE_OUTPUT"

input=$(ssh dev-$VM_SENDER "grep 'input' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
output=$(ssh dev-$VM_RECEIVER "grep 'output' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
ssh dev-$VM_SENDER "sed -i \"s/$input/input='veth_d'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
ssh dev-$VM_RECEIVER "sed -i \"s/$output/output='veth_d'/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

# Run tests
rate_old=$(ssh dev-$VM_SENDER "grep 'rate' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
rate_old_rx=$(ssh dev-$VM_RECEIVER "grep 'rate' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")

# Set pattern to default value
pattern_sender=$(ssh dev-$VM_SENDER "grep 'pub const PATTERN' /home/$USER_SENDER/$USER_LOCAL/budget_ditto/src/pattern.rs")
pattern_receiver=$(ssh dev-$VM_RECEIVER "grep 'pub const PATTERN' /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/src/pattern.rs")
pattern_sender="${pattern_sender//[/\\[}"
pattern_receiver="${pattern_receiver//[/\\[}"

pattern="${PATTERNS[2]}"
# pattern="pub const PATTERN: [usize; 3] = [467, 933, 1400];"
ssh dev-$VM_SENDER "sed -i 's/$pattern_sender/$pattern/g' /home/$USER_SENDER/$USER_LOCAL/budget_ditto/src/pattern.rs"
ssh dev-$VM_RECEIVER "sed -i 's/$pattern_receiver/$pattern/g' /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/src/pattern.rs"
pattern_sender=$pattern
pattern_receiver=$pattern

# Set input/output back
input=$(ssh dev-$VM_SENDER "grep 'input' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
output=$(ssh dev-$VM_RECEIVER "grep 'output' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
ssh dev-$VM_SENDER "sed -i \"s/$input/input='veth_d'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
ssh dev-$VM_RECEIVER "sed -i \"s/$output/output='veth_d'/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

# Set send/receive in configs
sends=$(ssh dev-$VM_SENDER "grep 'send=' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
receives=$(ssh dev-$VM_SENDER "grep 'receive=' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
ssh dev-$VM_SENDER "sed -i \"s/$sends/send=true/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
ssh dev-$VM_SENDER "sed -i \"s/$receives/receive=false/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
sends=$(ssh dev-$VM_RECEIVER "grep 'send=' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
receives=$(ssh dev-$VM_RECEIVER "grep 'receive=' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
ssh dev-$VM_RECEIVER "sed -i \"s/$sends/send=false/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
ssh dev-$VM_RECEIVER "sed -i \"s/$receives/receive=true/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

# Kill lingering processes
ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill sender_receiver"
ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto"
ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill sender_receiver"

FILE_DATA_SENDER="/home/$USER_LOCAL/cyd/remote/$VM_SENDER/sender_receiver/tx_data_0.csv"
FILE_DATA_RECEIVER="/home/$USER_LOCAL/cyd/remote/$VM_RECEIVER/sender_receiver/rx_data.csv"

FILE="/home/$USER_LOCAL/cyd/analysis/results/results_${VM_SENDER}_${VM_RECEIVER}_${RESULT_FILE_SUFFIX}.csv"
is_full=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE ${#RATES[@]} $NUM_RUNS full)

if $RUN_DITTO && [ $is_full = 'False' ]; then
    echo "Running Ditto tests..."
    sleep 1
    # Start ditto in sender and receiver
    ssh dev-$VM_SENDER "$cmd_ditto_sender" &
    ssh dev-$VM_RECEIVER "$cmd_ditto_receiver" &

    # Wait 1s before starting test runs
    sleep 1

    for ((i=1; i<=NUM_RUNS; i++)); do
        echo "Run $i"
        for ((j=0; j < ${#RATES[@]}; j++)); do
            rate="${RATES[j]}"

            exists=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE $rate $i)
            if [ $exists = 'True' ]; then 
                echo "Skipping, already exists $rate $i"
                continue
            fi
            
            # Modify pps and num_pkts parameters
            # Send 10 times as many packets as pps (i.e. send for baout 10s)
            rate_new="rate=$rate"
            ssh dev-$VM_SENDER "sed -i 's/$rate_old/$rate_new/g' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
            ssh dev-$VM_RECEIVER "sed -i 's/$rate_old_rx/$rate_new/g' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
            rate_old=$rate_new
            rate_old_rx=$rate_new

            # Send from sender to receiver
            echo "Sending at $rate_new Mbps"
            sleep 1
            ssh dev-$VM_RECEIVER "$cmd_receiver" &
            sleep 2
            ssh dev-$VM_SENDER "$cmd_sender"
            
            sleep 2
            ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill sender_receiver"
            ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill sender_receiver"
            sleep 2

            # Log data
            python3 /home/$USER_LOCAL/cyd/analysis/get_metrics.py $FILE_DATA_SENDER $FILE_DATA_RECEIVER $rate $i $FILE False
        done
    done

    # Stop ditto in sender and receiver
    ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
    ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto"
elif [ $is_full = 'True' ]; then
    echo "Skipping Ditto tests, already completed"
fi

sshfs dev-$VM_SENDER:/home/$USER_SENDER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_SENDER
sshfs dev-$VM_RECEIVER:/home/$USER_RECEIVER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_RECEIVER

FILE="/home/$USER_LOCAL/cyd/analysis/results/results_normal_traffic_${VM_SENDER}_${VM_RECEIVER}_${RESULT_FILE_SUFFIX}.csv"
is_full=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE ${#RATES[@]} $NUM_RUNS full)

if $RUN_NORMAL && [ $is_full = 'False' ]; then
    echo "Running normal traffic tests..."
    # Now evaluate for normal traffic
    sleep 1
    input=$(ssh dev-$VM_SENDER "grep 'input' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    output=$(ssh dev-$VM_RECEIVER "grep 'output' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_SENDER "sed -i \"s/$input/input='wg3'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$output/output='wg3'/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

    rate_old=$(ssh dev-$VM_SENDER "grep 'rate' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    rate_old_rx=$(ssh dev-$VM_RECEIVER "grep 'rate' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")

    for ((i=1; i<=NUM_RUNS; i++)); do
        echo "Run $i"
        for ((j=0; j < ${#RATES[@]}; j++)); do
            rate="${RATES[j]}"

            exists=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE $rate $i)
            if [ $exists = 'True' ]; then 
                echo "Skipping, already exists $rate $i"
                continue
            fi
            
            # Modify pps and num_pkts parameters
            # Send 10 times as many packets as pps (i.e. send for baout 10s)
            rate_new="rate=$rate"
            ssh dev-$VM_SENDER "sed -i 's/$rate_old/$rate_new/g' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
            ssh dev-$VM_RECEIVER "sed -i 's/$rate_old_rx/$rate_new/g' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
            rate_old=$rate_new
            rate_old_rx=$rate_new

            # Send from sender to receiver
            echo "Sending at $rate_new Mbps"
            sleep 1
            ssh dev-$VM_RECEIVER "$cmd_receiver" &
            sleep 2
            ssh dev-$VM_SENDER "$cmd_sender"
            
            sleep 2
            ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill sender_receiver"
            ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill sender_receiver"
            sleep 2

            # Log data
            python3 /home/$USER_LOCAL/cyd/analysis/get_metrics.py $FILE_DATA_SENDER $FILE_DATA_RECEIVER $rate $i $FILE False
        done
    done

    # Set input/output back
    input=$(ssh dev-$VM_SENDER "grep 'input' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    output=$(ssh dev-$VM_RECEIVER "grep 'output' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_SENDER "sed -i \"s/$input/input='veth_d'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$output/output='veth_d'/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
elif [ $is_full = 'True' ]; then
    echo "Skipping normal traffic tests, already completed"
fi

sshfs dev-$VM_SENDER:/home/$USER_SENDER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_SENDER
sshfs dev-$VM_RECEIVER:/home/$USER_RECEIVER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_RECEIVER

KEYS=("1" "2" "3" "4" "5" "6" "7" "8")
FILE="/home/$USER_LOCAL/cyd/analysis/results/results_pattern_${VM_SENDER}_${VM_RECEIVER}_${RESULT_FILE_SUFFIX}.csv"
is_full=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE ${#KEYS[@]} $NUM_RUNS full)

if $RUN_PATTERN && [ $is_full = 'False' ]; then
    echo "Running pattern tests..."
    sleep 1
    pattern_sender=$(ssh dev-$VM_SENDER "grep 'pub const PATTERN' /home/$USER_SENDER/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_receiver=$(ssh dev-$VM_RECEIVER "grep 'pub const PATTERN' /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_sender="${pattern_sender//[/\\[}"
    pattern_receiver="${pattern_receiver//[/\\[}"

    rate_old=$(ssh dev-$VM_SENDER "grep 'rate' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    rate_old_rx=$(ssh dev-$VM_RECEIVER "grep 'rate' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")

    # Run at 80%
    rate="70.0"
    
    # Modify pps and num_pkts parameters
    # Send 10 times as many packets as pps (i.e. send for baout 10s)
    rate_new="rate=$rate"
    ssh dev-$VM_SENDER "sed -i 's/$rate_old/$rate_new/g' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_RECEIVER "sed -i 's/$rate_old_rx/$rate_new/g' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
    rate_old=$rate_new
    rate_old_rx=$rate_new

    # Send from sender to receiver
    echo "Sending at $rate_new Mbps"

    for ((j=0; j<${#PATTERNS[@]}; j++)); do
        pattern="${PATTERNS[j]}"
        pattern="${pattern//[/\\[}"
        key="${KEYS[j]}"

        ssh dev-$VM_SENDER "sed -i 's/$pattern_sender/$pattern/g' /home/$USER_SENDER/$USER_LOCAL/budget_ditto/src/pattern.rs"
        ssh dev-$VM_RECEIVER "sed -i 's/$pattern_receiver/$pattern/g' /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/src/pattern.rs"
        pattern_sender=$pattern
        pattern_receiver=$pattern

        echo "Running with pattern $pattern"
        sleep 1
        # Start ditto in sender and receiver
        ssh dev-$VM_SENDER "$cmd_ditto_sender" &
        ssh dev-$VM_RECEIVER "$cmd_ditto_receiver" &

        for ((i=1; i<=NUM_RUNS; i++)); do
            echo "Run $i"

            exists=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE $key $i)
            if [ $exists = 'True' ]; then 
                echo "Skipping, already exists $key $i"
                continue
            fi

            sleep 1
            ssh dev-$VM_RECEIVER "$cmd_receiver" &
            sleep 2
            ssh dev-$VM_SENDER "$cmd_sender"
            
            sleep 2
            ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill sender_receiver"
            ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill sender_receiver"
            sleep 2

            # Log data
            python3 /home/$USER_LOCAL/cyd/analysis/get_metrics.py $FILE_DATA_SENDER $FILE_DATA_RECEIVER $key $i $FILE True
        done

        # Stop ditto in sender and receiver
        ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
        ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto"
    done
elif [ $is_full = 'True' ]; then
    echo "Skipping pattern tests, already completed"
fi

sshfs dev-$VM_SENDER:/home/$USER_SENDER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_SENDER
sshfs dev-$VM_RECEIVER:/home/$USER_RECEIVER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_RECEIVER



FILE="/home/$USER_LOCAL/cyd/analysis/results/results_mult_${VM_SENDER}_${VM_RECEIVER}_${RESULT_FILE_SUFFIX}.csv"
is_full=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE ${#KEYS[@]} $NUM_RUNS full)

if $RUN_MULTIPLE_FLOWS && [ $is_full = 'False' ]; then
    echo "Running multiple flows tests..."
    KEYS=("1" "2" "3" "4" "5" "6" "7" "8")
    RATES=("70.0" "35.0" "23.333" "17.5" "14.0" "11.666" "10.0" "8.75")
    sleep 1
    pattern_sender=$(ssh dev-$VM_SENDER "grep 'pub const PATTERN' /home/$USER_SENDER/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_receiver=$(ssh dev-$VM_RECEIVER "grep 'pub const PATTERN' /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_sender="${pattern_sender//[/\\[}"
    pattern_receiver="${pattern_receiver//[/\\[}"

    # Set pattern
    pattern="${PATTERNS[2]}"
    ssh dev-$VM_SENDER "sed -i 's/$pattern_sender/$pattern/g' /home/$USER_SENDER/$USER_LOCAL/budget_ditto/src/pattern.rs"
    ssh dev-$VM_RECEIVER "sed -i 's/$pattern_receiver/$pattern/g' /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/src/pattern.rs"
    pattern_sender=$pattern
    pattern_receiver=$pattern

    rate_old=$(ssh dev-$VM_SENDER "grep 'rate' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    rate_old_rx=$(ssh dev-$VM_RECEIVER "grep 'rate' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")

    echo "Running with pattern $pattern"
    # Start ditto in sender and receiver
    ssh dev-$VM_SENDER "$cmd_ditto_sender" &
    ssh dev-$VM_RECEIVER "$cmd_ditto_receiver" &

    for ((i=1; i<=NUM_RUNS; i++)); do
        echo "Run $i"
        for ((j=0; j<${#RATES[@]}; j++)); do
            key="${KEYS[j]}"
            rate="${RATES[j]}"

            exists=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE $key $i)
            if [ $exists = 'True' ]; then 
                echo "Skipping, already exists $key $i"
                continue
            fi

            # Modify pps and num_pkts parameters
            # Send 10 times as many packets as pps (i.e. send for baout 10s)
            rate_new="rate=$rate"
            rate_new_rx="rate=$(echo "$rate * $key" | bc)"
            ssh dev-$VM_SENDER "sed -i 's/$rate_old/$rate_new/g' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
            ssh dev-$VM_RECEIVER "sed -i 's/$rate_old_rx/$rate_new_rx/g' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
            rate_old=$rate_new
            rate_old_rx=$rate_new_rx

            # Send from sender to receiver
            echo "Sending at $rate_new Mbps, receiving at $rate_new_rx Mbps"

            # Wait 1s before starting test runs
            sleep 1

            ssh dev-$VM_RECEIVER "$cmd_receiver" &
            sleep 2
            for ((k=0; k<key; k++)); do
                # Launch i flows
                if [ "$k" -eq $((key - 1)) ]; then
                    # Blocks until completion for the last flow
                    ssh dev-$VM_SENDER "export FLOW=$k && $cmd_sender"
                else
                    ssh dev-$VM_SENDER "export FLOW=$k && $cmd_sender" &
                fi
            done
            
            sleep 2
            ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill sender_receiver"
            ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill sender_receiver"
            sleep 3

            # Log data
            python3 /home/$USER_LOCAL/cyd/analysis/get_metrics.py $FILE_DATA_SENDER $FILE_DATA_RECEIVER $key $i $FILE False $key
        done
    done

    RATES=("1.0" "10.0" "50.0" "66.0" "70.0" "75.0" "80.0" "90.0" "100.0")
    # Stop ditto in sender and receiver
    ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
    ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto"
elif [ $is_full = 'True' ]; then
    echo "Skipping multiple flows tests, already completed"
fi

sshfs dev-$VM_SENDER:/home/$USER_SENDER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_SENDER
sshfs dev-$VM_RECEIVER:/home/$USER_RECEIVER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_RECEIVER

# Will never be full since only 1 key and not 8 as expected. Not a problem per say but could be improved
FILE="/home/$USER_LOCAL/cyd/analysis/results/results_mult_special_${VM_SENDER}_${VM_RECEIVER}_${RESULT_FILE_SUFFIX}.csv"
is_full=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE 2 $NUM_RUNS full)

if $RUN_SPECIAL_MULT_FLOWS && ! $USE_CAIDA && [ $is_full = 'False' ]; then
    echo "Running special flow test..."
    sleep 1
    pattern_sender=$(ssh dev-$VM_SENDER "grep 'pub const PATTERN' /home/$USER_SENDER/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_receiver=$(ssh dev-$VM_RECEIVER "grep 'pub const PATTERN' /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_sender="${pattern_sender//[/\\[}"
    pattern_receiver="${pattern_receiver//[/\\[}"

    # Set pattern
    pattern="pub const PATTERN: [usize; 3] = [467, 933, 1400];"
    ssh dev-$VM_SENDER "sed -i 's/$pattern_sender/$pattern/g' /home/$USER_SENDER/$USER_LOCAL/budget_ditto/src/pattern.rs"
    ssh dev-$VM_RECEIVER "sed -i 's/$pattern_receiver/$pattern/g' /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/src/pattern.rs"
    pattern_sender=$pattern
    pattern_receiver=$pattern

    rate_old_1=$(ssh dev-$VM_SENDER "grep 'rate' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_small_pkt_flow.toml")
    rate_old_2=$(ssh dev-$VM_SENDER "grep 'rate' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_med_pkt_flow.toml")
    rate_old_3=$(ssh dev-$VM_SENDER "grep 'rate' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_large_pkt_flow.toml")
    rate_old_rx=$(ssh dev-$VM_RECEIVER "grep 'rate' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")

    dst_small=$(ssh dev-$VM_SENDER "grep 'dst=' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_small_pkt_flow.toml")
    dst_med=$(ssh dev-$VM_SENDER "grep 'dst=' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_med_pkt_flow.toml")
    dst_large=$(ssh dev-$VM_SENDER "grep 'dst=' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_large_pkt_flow.toml")
    if [ "$VM_RECEIVER" = "thun" ]; then
        ssh dev-$VM_SENDER "sed -i \"s/$dst_small/dst='$ADDR_THUN'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_small_pkt_flow.toml"
        ssh dev-$VM_SENDER "sed -i \"s/$dst_med/dst='$ADDR_THUN'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_med_pkt_flow.toml"
        ssh dev-$VM_SENDER "sed -i \"s/$dst_large/dst='$ADDR_THUN'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_large_pkt_flow.toml"
    elif [ "$VM_RECEIVER" = "zurich" ]; then
        ssh dev-$VM_SENDER "sed -i \"s/$dst_small/dst='$ADDR_ZURICH'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_small_pkt_flow.toml"
        ssh dev-$VM_SENDER "sed -i \"s/$dst_med/dst='$ADDR_ZURICH'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_med_pkt_flow.toml"
        ssh dev-$VM_SENDER "sed -i \"s/$dst_large/dst='$ADDR_ZURICH'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_large_pkt_flow.toml"
    elif [ "$VM_RECEIVER" = "lausanne" ]; then
        ssh dev-$VM_SENDER "sed -i \"s/$dst_small/dst='$ADDR_LAUSANNE'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_small_pkt_flow.toml"
        ssh dev-$VM_SENDER "sed -i \"s/$dst_med/dst='$ADDR_LAUSANNE'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_med_pkt_flow.toml"
        ssh dev-$VM_SENDER "sed -i \"s/$dst_large/dst='$ADDR_LAUSANNE'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_large_pkt_flow.toml"
    fi

    src_small=$(ssh dev-$VM_SENDER "grep 'src=' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_small_pkt_flow.toml")
    src_med=$(ssh dev-$VM_SENDER "grep 'src=' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_med_pkt_flow.toml")
    src_large=$(ssh dev-$VM_SENDER "grep 'src=' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_large_pkt_flow.toml")
    if [ "$VM_SENDER" = "thun" ]; then
        ssh dev-$VM_SENDER "sed -i \"s/$src_small/src='$ADDR_THUN'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_small_pkt_flow.toml"
        ssh dev-$VM_SENDER "sed -i \"s/$src_med/src='$ADDR_THUN'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_med_pkt_flow.toml"
        ssh dev-$VM_SENDER "sed -i \"s/$src_large/src='$ADDR_THUN'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_large_pkt_flow.toml"
    elif [ "$VM_SENDER" = "zurich" ]; then
        ssh dev-$VM_SENDER "sed -i \"s/$src_small/src='$ADDR_ZURICH'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_small_pkt_flow.toml"
        ssh dev-$VM_SENDER "sed -i \"s/$src_med/src='$ADDR_ZURICH'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_med_pkt_flow.toml"
        ssh dev-$VM_SENDER "sed -i \"s/$src_large/src='$ADDR_ZURICH'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_large_pkt_flow.toml"
    elif [ "$VM_SENDER" = "lausanne" ]; then
        ssh dev-$VM_SENDER "sed -i \"s/$src_small/src='$ADDR_LAUSANNE'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_small_pkt_flow.toml"
        ssh dev-$VM_SENDER "sed -i \"s/$src_med/src='$ADDR_LAUSANNE'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_med_pkt_flow.toml"
        ssh dev-$VM_SENDER "sed -i \"s/$src_large/src='$ADDR_LAUSANNE'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_large_pkt_flow.toml"
    fi

    echo "Running with pattern $pattern"
    # Start ditto in sender and receiver
    ssh dev-$VM_SENDER "$cmd_ditto_sender" &
    ssh dev-$VM_RECEIVER "$cmd_ditto_receiver" &

    # Run at 70%
    key="3"
    rate="26.666"

    # Modify pps and num_pkts parameters
    # Send 10 times as many packets as pps (i.e. send for baout 10s)
    rate_new="rate=$rate"
    rate_new_rx="rate=$(echo "$rate * $key" | bc)"
    ssh dev-$VM_SENDER "sed -i 's/$rate_old_1/$rate_new/g' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_small_pkt_flow.toml"
    ssh dev-$VM_SENDER "sed -i 's/$rate_old_2/$rate_new/g' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_med_pkt_flow.toml"
    ssh dev-$VM_SENDER "sed -i 's/$rate_old_3/$rate_new/g' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_large_pkt_flow.toml"
    ssh dev-$VM_RECEIVER "sed -i 's/$rate_old_rx/$rate_new_rx/g' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
    rate_old=$rate_new
    rate_old_rx=$rate_new_rx

    for ((i=1; i<=NUM_RUNS; i++)); do
        echo "Run $i"

        exists=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE $key $i)
        if [ $exists = 'True' ]; then 
            echo "Skipping, already exists $key $i"
            continue
        fi

        # Send from sender to receiver
        echo "Sending at $rate_new Mbps, receiving at $rate_new_rx Mbps"

        # Wait 1s before starting test runs
        sleep 1
        ssh dev-$VM_RECEIVER "$cmd_receiver" &
        sleep 2
        cmd_sender="cd $USER_LOCAL/sender_receiver && echo $pwd_sender | sudo -S -E /home/$USER_SENDER/.cargo/bin/cargo run config/config_small_pkt_flow.toml $SUPPRESS_CONSOLE_OUTPUT"
        ssh dev-$VM_SENDER "export FLOW=0 && $cmd_sender" &
        cmd_sender="cd $USER_LOCAL/sender_receiver && echo $pwd_sender | sudo -S -E /home/$USER_SENDER/.cargo/bin/cargo run config/config_med_pkt_flow.toml $SUPPRESS_CONSOLE_OUTPUT"
        ssh dev-$VM_SENDER "export FLOW=1 && $cmd_sender" &
        cmd_sender="cd $USER_LOCAL/sender_receiver && echo $pwd_sender | sudo -S -E /home/$USER_SENDER/.cargo/bin/cargo run config/config_large_pkt_flow.toml $SUPPRESS_CONSOLE_OUTPUT"
        ssh dev-$VM_SENDER "export FLOW=2 && $cmd_sender"
        sleep 2
        ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill sender_receiver"
        ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill sender_receiver"
        sleep 3

        # Log data
        python3 /home/$USER_LOCAL/cyd/analysis/get_metrics.py $FILE_DATA_SENDER $FILE_DATA_RECEIVER $key $i $FILE False $key
    done
    # Stop ditto in sender and receiver
    ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
    ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto"
elif [ $is_full = 'True' ]; then
    echo "Skipping multiple flows tests, already completed"
fi

sshfs dev-$VM_SENDER:/home/$USER_SENDER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_SENDER
sshfs dev-$VM_RECEIVER:/home/$USER_RECEIVER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_RECEIVER

KEYS=("1" "2" "3" "4" "5" "6" "7" "8")
FILE="/home/$USER_LOCAL/cyd/analysis/results/results_pattern_rate_${VM_SENDER}_${VM_RECEIVER}_${RESULT_FILE_SUFFIX}.csv"
is_full=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE ${#KEYS[@]} $NUM_RUNS full)

if $RUN_PATTERN_RATE && [ $is_full = 'False' ]; then
    echo "Running pattern tests for rate..."
    sleep 1
    pattern_sender=$(ssh dev-$VM_SENDER "grep 'pub const PATTERN' /home/$USER_SENDER/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_receiver=$(ssh dev-$VM_RECEIVER "grep 'pub const PATTERN' /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_sender="${pattern_sender//[/\\[}"
    pattern_receiver="${pattern_receiver//[/\\[}"

    rate_old=$(ssh dev-$VM_SENDER "grep 'rate' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    rate_old_rx=$(ssh dev-$VM_RECEIVER "grep 'rate' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")

    # Run at 80%
    rate="100.0"
    
    # Modify pps and num_pkts parameters
    # Send 10 times as many packets as pps (i.e. send for baout 10s)
    rate_new="rate=$rate"
    ssh dev-$VM_SENDER "sed -i 's/$rate_old/$rate_new/g' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_RECEIVER "sed -i 's/$rate_old_rx/$rate_new/g' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
    rate_old=$rate_new
    rate_old_rx=$rate_new

    # Send from sender to receiver
    echo "Sending at $rate_new Mbps"

    for ((j=0; j<${#PATTERNS[@]}; j++)); do
        pattern="${PATTERNS[j]}"
        pattern="${pattern//[/\\[}"
        key="${KEYS[j]}"

        ssh dev-$VM_SENDER "sed -i 's/$pattern_sender/$pattern/g' /home/$USER_SENDER/$USER_LOCAL/budget_ditto/src/pattern.rs"
        ssh dev-$VM_RECEIVER "sed -i 's/$pattern_receiver/$pattern/g' /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/src/pattern.rs"
        pattern_sender=$pattern
        pattern_receiver=$pattern

        echo "Running with pattern $pattern"
        sleep 1
        # Start ditto in sender and receiver
        ssh dev-$VM_SENDER "$cmd_ditto_sender" &
        ssh dev-$VM_RECEIVER "$cmd_ditto_receiver" &

        for ((i=1; i<=NUM_RUNS; i++)); do
            echo "Run $i"

            exists=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE $key $i)
            if [ $exists = 'True' ]; then 
                echo "Skipping, already exists $key $i"
                continue
            fi

            sleep 1
            ssh dev-$VM_RECEIVER "$cmd_receiver" &
            sleep 2
            ssh dev-$VM_SENDER "$cmd_sender"
            
            sleep 2
            ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill sender_receiver"
            ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill sender_receiver"
            sleep 2

            # Log data
            python3 /home/$USER_LOCAL/cyd/analysis/get_metrics.py $FILE_DATA_SENDER $FILE_DATA_RECEIVER $key $i $FILE True
        done

        # Stop ditto in sender and receiver
        ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
        ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto"
    done
elif [ $is_full = 'True' ]; then
    echo "Skipping pattern rate tests, already completed"
fi

sshfs dev-$VM_SENDER:/home/$USER_SENDER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_SENDER
sshfs dev-$VM_RECEIVER:/home/$USER_RECEIVER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_RECEIVER

FILE="/home/$USER_LOCAL/cyd/analysis/results/results_video_${VM_SENDER}_${VM_RECEIVER}_${RESULT_FILE_SUFFIX}.csv"
NUM_ITEMS_VIDEO=27 # Number of rates x number of patterns = 9 * 3 = 27
is_full=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE $NUM_ITEMS_VIDEO $NUM_RUNS full)

if $RUN_VIDEO && [ $is_full = 'False' ]; then
    echo "Running Video tests..."
    sleep 1

    RATES_VIDEO=("1.0" "10.0" "15.0" "20.0" "25.0" "30.0" "40.0" "50.0" "100.0")

    PATTERNS_VIDEO=(
        "pub const PATTERN: [usize; 3] = [98, 200, 1400];"
        "pub const PATTERN: [usize; 3] = [164, 200, 1400];"
        "pub const PATTERN: [usize; 3] = [200, 1228, 1400];"
    )

    dataset_sender=$(ssh dev-$VM_SENDER "grep 'dataset' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    dataset_receiver=$(ssh dev-$VM_RECEIVER "grep 'dataset' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_SENDER "sed -i \"s/$dataset_sender/dataset='video'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dataset_receiver/dataset='video'/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

    pattern_sender=$(ssh dev-$VM_SENDER "grep 'pub const PATTERN' /home/$USER_SENDER/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_receiver=$(ssh dev-$VM_RECEIVER "grep 'pub const PATTERN' /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_sender="${pattern_sender//[/\\[}"
    pattern_receiver="${pattern_receiver//[/\\[}"
    # Wait 1s before starting test runs
    sleep 1

    for ((k=0; k < ${#PATTERNS_VIDEO[@]}; k++)); do
        pattern="${PATTERNS_VIDEO[k]}"
        pattern="${pattern//[/\\[}"
        echo "Running with pattern $pattern"

        ssh dev-$VM_SENDER "sed -i 's/$pattern_sender/$pattern/g' /home/$USER_SENDER/$USER_LOCAL/budget_ditto/src/pattern.rs"
        ssh dev-$VM_RECEIVER "sed -i 's/$pattern_receiver/$pattern/g' /home/$USER_RECEIVER/$USER_LOCAL/budget_ditto/src/pattern.rs"
        pattern_sender=$pattern
        pattern_receiver=$pattern

        # Start ditto in sender and receiver
        ssh dev-$VM_SENDER "$cmd_ditto_sender" &
        ssh dev-$VM_RECEIVER "$cmd_ditto_receiver" &

        for ((i=1; i<=NUM_RUNS; i++)); do
            echo "Run $i"
            for ((j=0; j < ${#RATES_VIDEO[@]}; j++)); do
                rate="${RATES_VIDEO[j]}"

                exists=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE $rate$k $i)
                if [ $exists = 'True' ]; then 
                    echo "Skipping, already exists $rate $i"
                    continue
                fi
                
                # Modify pps and num_pkts parameters
                # Send 10 times as many packets as pps (i.e. send for baout 10s)
                rate_new="rate=$rate"
                ssh dev-$VM_SENDER "sed -i 's/$rate_old/$rate_new/g' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
                ssh dev-$VM_RECEIVER "sed -i 's/$rate_old_rx/$rate_new/g' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
                rate_old=$rate_new
                rate_old_rx=$rate_new

                # Send from sender to receiver
                echo "Sending at $rate_new Mbps"
                sleep 1
                ssh dev-$VM_RECEIVER "$cmd_receiver" &
                sleep 2
                ssh dev-$VM_SENDER "$cmd_sender"
                
                sleep 2
                ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill sender_receiver"
                ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill sender_receiver"
                sleep 2

                # Log data
                python3 /home/$USER_LOCAL/cyd/analysis/get_metrics.py $FILE_DATA_SENDER $FILE_DATA_RECEIVER $rate$k $i $FILE False
            done
        done
        # Stop ditto in sender and receiver
        ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
        ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto"
    done
    
    ssh dev-$VM_SENDER "sed -i \"s/dataset='video'/$dataset_sender/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/dataset='video'/$dataset_receiver/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

elif [ $is_full = 'True' ]; then
    echo "Skipping Ditto tests, already completed"
fi

# umount /home/$USER_LOCAL/cyd/remote/$VM_SENDER
# umount /home/$USER_LOCAL/cyd/remote/$VM_RECEIVER

echo "Tests finished!"