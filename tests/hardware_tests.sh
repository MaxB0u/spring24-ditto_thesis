#!/usr/bin/bash

# The switches need to have already been started and to be sending chaff packets between them.
# The ipv4 wrapping must also be running already.
echo "Starting hardware Ditto tests..."

NUM_RUNS=30
RATES=("1.0" "10.0" "50.0" "80.0" "100.0" "200.0" "300.0" "400.0" "500.0" "750.0" "1000.0")

TEST_HARDWARE=true

# Set to empty string if want to see console output
SUPPRESS_CONSOLE_OUTPUT="> /dev/null 2>&1"
SUPPRESS_CONSOLE_OUTPUT=""

DEVICE_SENDER='tofino-lausanne'
VM_RECEIVER='zurich'

USER_SENDER="wedge100bf"
USER_RECEIVER="lab"

ADDR_ZURICH="10.7.0.2"
ADDR_LAUSANNE="10.7.0.3"

USER_LOCAL='max'

# Set dst for sender in ditto config and dst in sender_receiver config
dst_sr=$(ssh dev-$VM_RECEIVER "grep 'dst=' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
ssh dev-$VM_RECEIVER "sed -i \"s/$dst_sr/dst='$ADDR_LAUSANNE'/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
dst_sr=$(ssh $DEVICE_SENDER "grep 'dst=' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml")
ssh $DEVICE_SENDER "sed -i \"s/$dst_sr/dst='$ADDR_ZURICH'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml"

# Set interfaces
input=$(ssh dev-$VM_RECEIVER "grep 'input' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
output=$(ssh dev-$VM_RECEIVER "grep 'output' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
ssh dev-$VM_RECEIVER "sed -i \"s/$input/input='ens38'/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
ssh dev-$VM_RECEIVER "sed -i \"s/$output/output='ens38'/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

input=$(ssh $DEVICE_SENDER "grep 'input' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml")
output=$(ssh $DEVICE_SENDER "grep 'output' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml")
ssh $DEVICE_SENDER "sed -i \"s/$input/input='enp4s0f1'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml"
ssh $DEVICE_SENDER "sed -i \"s/$output/output='enp4s0f1'/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml"

sshfs $VM_RECEIVER:/home/$USER_RECEIVER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_RECEIVER
sshfs $DEVICE_SENDER:/home/$USER_SENDER/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$DEVICE_SENDER

pwd_file_receiver="/home/$USER_LOCAL/cyd/remote/.auth/$VM_RECEIVER"
pwd_receiver=$(<"$pwd_file_receiver")
pwd_receiver=$(echo "$pwd_receiver" | tr -d '\n')

cmd_sender="cd $USER_LOCAL/sender_receiver && sudo -E cargo run config/config_client_$DEVICE_SENDER.toml $SUPPRESS_CONSOLE_OUTPUT"
cmd_receiver="cd $USER_LOCAL/sender_receiver && echo $pwd_receiver | sudo -S -E /home/$USER_RECEIVER/.cargo/bin/cargo run config/config_client_$VM_RECEIVER.toml $SUPPRESS_CONSOLE_OUTPUT"

# Kill lingering processes
ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill sender_receiver"
ssh $DEVICE_SENDER "sudo -S pkill sender_receiver"

FILE_DATA_SENDER="/home/$USER_LOCAL/cyd/remote/$DEVICE_SENDER/sender_receiver/tx_data_0.csv"
FILE_DATA_RECEIVER="/home/$USER_LOCAL/cyd/remote/$VM_RECEIVER/sender_receiver/rx_data.csv"

FILE="/home/$USER_LOCAL/cyd/analysis/results/results_hardware_${DEVICE_SENDER}_${VM_RECEIVER}_${RESULT_FILE_SUFFIX}.csv"
is_full=$(python3 /home/$USER_LOCAL/cyd/analysis/check_csv.py $FILE ${#RATES[@]} $NUM_RUNS full)

if $TEST_HARDWARE && [ $is_full = 'False' ]; then
    echo "Running hardware Ditto tests from lausanne to zurich"

    # Set send/receive/save in configs
    sends=$(ssh $DEVICE_SENDER "grep 'send=' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml")
    receives=$(ssh $DEVICE_SENDER "grep 'receive=' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml")
    save_sender=$(ssh $DEVICE_SENDER "grep 'save=' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml")
    dataset=$(ssh $DEVICE_SENDER "grep 'dataset' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml")
    ssh $DEVICE_SENDER "sed -i \"s/$sends/send=true/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml"
    ssh $DEVICE_SENDER "sed -i \"s/$receives/receive=false/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml"
    ssh $DEVICE_SENDER "sed -i \"s/$save_sender/save=true/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml"
    ssh $DEVICE_SENDER "sed -i \"s/$dataset/dataset=''/g\" /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml"

    sends=$(ssh dev-$VM_RECEIVER "grep 'send=' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    receives=$(ssh dev-$VM_RECEIVER "grep 'receive=' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    save_receiver=$(ssh dev-$VM_RECEIVER "grep 'save=' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_RECEIVER "sed -i \"s/$sends/send=false/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$receives/receive=true/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$save_receiver/save=true/g\" /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

    rate_old=$(ssh $DEVICE_SENDER "grep 'rate' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml")
    rate_old_rx=$(ssh dev-$VM_RECEIVER "grep 'rate' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")

    # Wait 1s before starting test runs
    sleep 3

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
            ssh $DEVICE_SENDER "sed -i 's/$rate_old/$rate_new/g' /home/$USER_SENDER/$USER_LOCAL/sender_receiver/config/config_client_$DEVICE_SENDER.toml"
            ssh dev-$VM_RECEIVER "sed -i 's/$rate_old_rx/$rate_new/g' /home/$USER_RECEIVER/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
            rate_old=$rate_new
            rate_old_rx=$rate_new

            # Send from sender to receiver
            echo "Sending at $rate_new Mbps"
            sleep 1
            ssh dev-$VM_RECEIVER "$cmd_receiver" &
            sleep 2
            ssh $DEVICE_SENDER "$cmd_sender"
            
            sleep 1
            ssh $DEVICE_SENDER "sudo -S pkill sender_receiver"
            ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill sender_receiver"
            sleep 2

            # Log data
            python3 /home/$USER_LOCAL/cyd/analysis/get_metrics.py $FILE_DATA_SENDER $FILE_DATA_RECEIVER $rate $i $FILE False
        done
    done

elif [ $is_full = 'True' ]; then
    echo "Skipping Ditto tests, already completed"
fi



