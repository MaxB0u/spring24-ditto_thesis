#!/usr/bin/bash

echo "Starting Ditto in the backbone tests..."

NUM_RUNS=30

TEST_BACKBONE=true

PATTERN_VOIP="pub const PATTERN: [usize; 3] = [98, 200, 1400];"
PATTERN_WEB="pub const PATTERN: [usize; 3] = [1228, 1228, 1400];"
PATTERN_COMBINED="pub const PATTERN: [usize; 3] = [200, 1228, 1400];"
# PATTERN_COMBINED="pub const PATTERN: [usize; 6] = [98, 200, 1228, 1228, 1400, 1400];"

FLOW_VOIP="0"
FLOW_WEB="1"

RATE_DITTO_SINGLE_FLOW="100.0"
RATE_DITTO_COMBINED_FLOW=("100.0" "200.0")
RATES_VOIP=("1.0" "3.75" "7.5" "11.25" "15.0" "18.75" "22.5" "26.25" "30.0")
RATES_WEB=("1.0" "10.0" "20.0" "30.0" "40.0" "50.0" "60.0" "70.0" "80.0")

# Set to empty string if want to see console output
SUPPRESS_CONSOLE_OUTPUT="> /dev/null 2>&1"
# SUPPRESS_CONSOLE_OUTPUT=""

VM_VOIP='zurich'
VM_WEB='lausanne'
VM_COMBINED='thun'

USER_VOIP="lab"
USER_WEB="ubuntu"
USER_COMBINED="lab"

ADDR_THUN="10.7.0.1"
ADDR_ZURICH="10.7.0.2"
ADDR_LAUSANNE="10.7.0.3"

USER_LOCAL='max'

# Set dst for sender in ditto config and dst in sender_receiver config
dst_ditto=$(ssh dev-$VM_VOIP "grep 'dst=' /home/$USER_VOIP/$USER_LOCAL/budget_ditto/config/config_client_$VM_VOIP.toml")
dst_sr=$(ssh dev-$VM_VOIP "grep 'dst=' /home/$USER_VOIP/$USER_LOCAL/sender_receiver/config/config_client_$VM_VOIP.toml")
ssh dev-$VM_VOIP "sed -i \"s/$dst_ditto/dst='$ADDR_THUN'/g\" /home/$USER_VOIP/$USER_LOCAL/budget_ditto/config/config_client_$VM_VOIP.toml"
ssh dev-$VM_VOIP "sed -i \"s/$dst_sr/dst='$ADDR_THUN'/g\" /home/$USER_VOIP/$USER_LOCAL/sender_receiver/config/config_client_$VM_VOIP.toml"

# Set dst for receiver in ditto config and dsr in sender_receiver config
dst_ditto=$(ssh dev-$VM_WEB "grep 'dst=' /home/$USER_WEB/$USER_LOCAL/budget_ditto/config/config_client_$VM_WEB.toml")
dst_sr=$(ssh dev-$VM_WEB "grep 'dst=' /home/$USER_WEB/$USER_LOCAL/sender_receiver/config/config_client_$VM_WEB.toml")
ssh dev-$VM_WEB "sed -i \"s/$dst_ditto/dst='$ADDR_THUN'/g\" /home/$USER_WEB/$USER_LOCAL/budget_ditto/config/config_client_$VM_WEB.toml"
ssh dev-$VM_WEB "sed -i \"s/$dst_sr/dst='$ADDR_THUN'/g\" /home/$USER_WEB/$USER_LOCAL/sender_receiver/config/config_client_$VM_WEB.toml"

# Set dst for sender in ditto config and dst in sender_receiver config
dst_ditto=$(ssh dev-$VM_COMBINED "grep 'dst=' /home/$USER_COMBINED/$USER_LOCAL/budget_ditto/config/config_client_$VM_COMBINED.toml")
dst_sr=$(ssh dev-$VM_COMBINED "grep 'dst=' /home/$USER_COMBINED/$USER_LOCAL/sender_receiver/config/config_client_$VM_COMBINED.toml")
ssh dev-$VM_COMBINED "sed -i \"s/$dst_ditto/dst='$ADDR_ZURICH'/g\" /home/$USER_COMBINED/$USER_LOCAL/budget_ditto/config/config_client_$VM_COMBINED.toml"
ssh dev-$VM_COMBINED "sed -i \"s/$dst_sr/dst='$ADDR_ZURICH'/g\" /home/$USER_COMBINED/$USER_LOCAL/sender_receiver/config/config_client_$VM_COMBINED.toml"

sshfs dev-$VM_VOIP:/home/$USER_VOIP/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_VOIP
sshfs dev-$VM_WEB:/home/$USER_WEB/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_WEB
sshfs dev-$VM_COMBINED:/home/$USER_COMBINED/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_COMBINED

pwd_file_voip="/home/$USER_LOCAL/cyd/remote/.auth/$VM_VOIP"
pwd_voip=$(<"$pwd_file_voip")
pwd_voip=$(echo "$pwd_voip" | tr -d '\n')

pwd_file_web="/home/$USER_LOCAL/cyd/remote/.auth/$VM_WEB"
pwd_web=$(<"$pwd_file_web")
pwd_web=$(echo "$pwd_web" | tr -d '\n')

pwd_file_combined="/home/$USER_LOCAL/cyd/remote/.auth/$VM_COMBINED"
pwd_combined=$(<"$pwd_file_combined")
pwd_combined=$(echo "$pwd_combined" | tr -d '\n')

cmd_ditto_voip="cd $USER_LOCAL/budget_ditto && echo $pwd_voip | sudo -S -E /home/$USER_VOIP/.cargo/bin/cargo run config/config_client_$VM_VOIP.toml $SUPPRESS_CONSOLE_OUTPUT"
cmd_ditto_web="cd $USER_LOCAL/budget_ditto && echo $pwd_web | sudo -S -E /home/$USER_WEB/.cargo/bin/cargo run config/config_client_$VM_WEB.toml $SUPPRESS_CONSOLE_OUTPUT"
cmd_ditto_combined="cd $USER_LOCAL/budget_ditto && echo $pwd_combined | sudo -S -E /home/$USER_COMBINED/.cargo/bin/cargo run config/config_client_$VM_COMBINED.toml $SUPPRESS_CONSOLE_OUTPUT"

cmd_receive="cd $USER_LOCAL/sender_receiver && echo $pwd_voip | sudo -S -E /home/$USER_VOIP/.cargo/bin/cargo run config/config_client_combined_$VM_VOIP.toml $SUPPRESS_CONSOLE_OUTPUT"
cmd_send_voip="cd $USER_LOCAL/sender_receiver && echo $pwd_voip | sudo -S -E /home/$USER_VOIP/.cargo/bin/cargo run config/config_client_$VM_VOIP.toml $SUPPRESS_CONSOLE_OUTPUT"
cmd_sender_web="cd $USER_LOCAL/sender_receiver && echo $pwd_web | sudo -S -E /home/$USER_WEB/.cargo/bin/cargo run config/config_client_$VM_WEB.toml $SUPPRESS_CONSOLE_OUTPUT"

FILE_DATA_VOIP="/home/$USER_LOCAL/cyd/remote/$VM_VOIP/sender_receiver/tx_data_$FLOW_VOIP.csv"
FILE_DATA_WEB="/home/$USER_LOCAL/cyd/remote/$VM_WEB/sender_receiver/tx_data_$FLOW_WEB.csv"
FILE_DATA_RECEIVER="/home/$USER_LOCAL/cyd/remote/$VM_VOIP/sender_receiver/rx_data.csv"
FILE_VOIP="/home/$USER_LOCAL/cyd/analysis/results/results_backbone_voip.csv"
FILE_WEB="/home/$USER_LOCAL/cyd/analysis/results/results_backbone_web.csv"

# Kill lingering processes
ssh dev-$VM_VOIP "echo $pwd_voip | sudo -S pkill budget_ditto"
ssh dev-$VM_WEB "echo $pwd_web | sudo -S pkill budget_ditto"
ssh dev-$VM_COMBINED "echo $pwd_combined | sudo -S pkill budget_ditto"
ssh dev-$VM_VOIP "echo $pwd_voip | sudo -S pkill sender_receiver"
ssh dev-$VM_WEB "echo $pwd_web | sudo -S pkill sender_receiver"
ssh dev-$VM_COMBINED "echo $pwd_combined | sudo -S pkill sender_receiver"



if $TEST_BACKBONE; then
    echo "Running tests with voip and web"

    # Set send/receive/save in configs
    sends_voip=$(ssh dev-$VM_VOIP "grep 'send=' /home/$USER_VOIP/$USER_LOCAL/sender_receiver/config/config_client_$VM_VOIP.toml")
    receives_voip=$(ssh dev-$VM_VOIP "grep 'receive=' /home/$USER_VOIP/$USER_LOCAL/sender_receiver/config/config_client_$VM_VOIP.toml")
    save_voip=$(ssh dev-$VM_VOIP "grep 'save=' /home/$USER_VOIP/$USER_LOCAL/sender_receiver/config/config_client_$VM_VOIP.toml")
    dataset_voip=$(ssh dev-$VM_VOIP "grep 'dataset' /home/$USER_VOIP/$USER_LOCAL/sender_receiver/config/config_client_$VM_VOIP.toml")
    ssh dev-$VM_VOIP "sed -i \"s/$sends_voip/send=true/g\" /home/$USER_VOIP/$USER_LOCAL/sender_receiver/config/config_client_$VM_VOIP.toml"
    ssh dev-$VM_VOIP "sed -i \"s/$receives_voip/receive=false/g\" /home/$USER_VOIP/$USER_LOCAL/sender_receiver/config/config_client_$VM_VOIP.toml"
    ssh dev-$VM_VOIP "sed -i \"s/$save_voip/save=true/g\" /home/$USER_VOIP/$USER_LOCAL/sender_receiver/config/config_client_$VM_VOIP.toml"
    ssh dev-$VM_VOIP "sed -i \"s/$dataset_voip/dataset='video'/g\" /home/$USER_VOIP/$USER_LOCAL/sender_receiver/config/config_client_$VM_VOIP.toml"

    sends_web=$(ssh dev-$VM_WEB "grep 'send=' /home/$USER_WEB/$USER_LOCAL/sender_receiver/config/config_client_$VM_WEB.toml")
    receives_web=$(ssh dev-$VM_WEB "grep 'receive=' /home/$USER_WEB/$USER_LOCAL/sender_receiver/config/config_client_$VM_WEB.toml")
    save_web=$(ssh dev-$VM_WEB "grep 'save=' /home/$USER_WEB/$USER_LOCAL/sender_receiver/config/config_client_$VM_WEB.toml")
    dataset_web=$(ssh dev-$VM_WEB "grep 'dataset' /home/$USER_WEB/$USER_LOCAL/sender_receiver/config/config_client_$VM_WEB.toml")
    ssh dev-$VM_WEB "sed -i \"s/$sends_web/send=true/g\" /home/$USER_WEB/$USER_LOCAL/sender_receiver/config/config_client_$VM_WEB.toml"
    ssh dev-$VM_WEB "sed -i \"s/$receives_web/receive=false/g\" /home/$USER_WEB/$USER_LOCAL/sender_receiver/config/config_client_$VM_WEB.toml"
    ssh dev-$VM_WEB "sed -i \"s/$save_web/save=true/g\" /home/$USER_WEB/$USER_LOCAL/sender_receiver/config/config_client_$VM_WEB.toml"
    ssh dev-$VM_WEB "sed -i \"s/$dataset_web/dataset='web'/g\" /home/$USER_WEB/$USER_LOCAL/sender_receiver/config/config_client_$VM_WEB.toml"
    
    # Set patterns in configs
    pattern_voip=$(ssh dev-$VM_VOIP "grep 'pub const PATTERN' /home/$USER_VOIP/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_web=$(ssh dev-$VM_WEB "grep 'pub const PATTERN' /home/$USER_WEB/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_combined=$(ssh dev-$VM_COMBINED "grep 'pub const PATTERN' /home/$USER_COMBINED/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_voip="${pattern_voip//[/\\[}"
    pattern_web="${pattern_web//[/\\[}"
    pattern_combined="${pattern_combined//[/\\[}"
    ssh dev-$VM_VOIP "sed -i 's/$pattern_voip/$PATTERN_VOIP/g' /home/$USER_VOIP/$USER_LOCAL/budget_ditto/src/pattern.rs"
    ssh dev-$VM_WEB "sed -i 's/$pattern_web/$PATTERN_WEB/g' /home/$USER_WEB/$USER_LOCAL/budget_ditto/src/pattern.rs"
    ssh dev-$VM_COMBINED "sed -i 's/$pattern_combined/$PATTERN_COMBINED/g' /home/$USER_COMBINED/$USER_LOCAL/budget_ditto/src/pattern.rs"

    rate_old_ditto_voip=$(ssh dev-$VM_VOIP "grep 'rate' /home/$USER_VOIP/$USER_LOCAL/budget_ditto/config/config_client_$VM_VOIP.toml")
    rate_old_ditto_web=$(ssh dev-$VM_WEB "grep 'rate' /home/$USER_WEB/$USER_LOCAL/budget_ditto/config/config_client_$VM_WEB.toml")
    ssh dev-$VM_VOIP "sed -i 's/$rate_old_ditto_voip/rate=$RATE_DITTO_SINGLE_FLOW/g' /home/$USER_VOIP/$USER_LOCAL/budget_ditto/config/config_client_$VM_VOIP.toml"
    ssh dev-$VM_WEB "sed -i 's/$rate_old_ditto_web/rate=$RATE_DITTO_SINGLE_FLOW/g' /home/$USER_WEB/$USER_LOCAL/budget_ditto/config/config_client_$VM_WEB.toml"

    rate_old_ditto_combined=$(ssh dev-$VM_COMBINED "grep 'rate' /home/$USER_COMBINED/$USER_LOCAL/budget_ditto/config/config_client_$VM_COMBINED.toml")

    for ((k=0; k < ${#RATE_DITTO_COMBINED_FLOW[@]}; k++)); do
        # Set rate
        rate_ditto_combined="${RATE_DITTO_COMBINED_FLOW[k]}"

        rate_new_ditto_combined="rate=$rate_ditto_combined"
        ssh dev-$VM_COMBINED "sed -i 's/$rate_old_ditto_combined/$rate_new_ditto_combined/g' /home/$USER_COMBINED/$USER_LOCAL/budget_ditto/config/config_client_$VM_COMBINED.toml"
        rate_old_ditto_combined=$rate_new_ditto_combined

        # Start ditto in sender and receiver
        ssh dev-$VM_VOIP "$cmd_ditto_voip" &
        ssh dev-$VM_WEB "$cmd_ditto_web" &
        ssh dev-$VM_COMBINED "$cmd_ditto_combined" &
        sleep 2

        rate_old_voip=$(ssh dev-$VM_VOIP "grep 'rate' /home/$USER_VOIP/$USER_LOCAL/sender_receiver/config/config_client_$VM_VOIP.toml")
        rate_old_web=$(ssh dev-$VM_WEB "grep 'rate' /home/$USER_WEB/$USER_LOCAL/sender_receiver/config/config_client_$VM_WEB.toml")

        for ((i=0; i < ${#RATES_VOIP[@]}; i++)); do
            rate_voip="${RATES_VOIP[i]}"
            rate_web="${RATES_WEB[i]}"

            rate_new_voip="rate=$rate_voip"
            rate_new_web="rate=$rate_web"
            ssh dev-$VM_VOIP "sed -i 's/$rate_old_voip/$rate_new_voip/g' /home/$USER_VOIP/$USER_LOCAL/sender_receiver/config/config_client_$VM_VOIP.toml"
            ssh dev-$VM_WEB "sed -i 's/$rate_old_web/$rate_new_web/g' /home/$USER_WEB/$USER_LOCAL/sender_receiver/config/config_client_$VM_WEB.toml"
            rate_old_voip=$rate_new_voip
            rate_old_web=$rate_new_web

            sleep 1
            for ((j=1; j<=NUM_RUNS; j++)); do
                echo "Run $j"
                # How to receive on either vm web or voip and not mix up with traffic that is being sent
                ssh dev-$VM_VOIP "$cmd_receive" &
                sleep 2

                ssh dev-$VM_VOIP "export FLOW=$FLOW_VOIP && $cmd_send_voip" &
                ssh dev-$VM_WEB "export FLOW=$FLOW_WEB && $cmd_sender_web"
                sleep 1

                # Log data
                # echo "python3 /home/$USER_LOCAL/cyd/analysis/get_metrics.py $FILE_DATA_VOIP $FILE_DATA_RECEIVER $rate_voip$k $j $FILE_VOIP False 0 $FLOW_VOIP"
                # echo "python3 /home/$USER_LOCAL/cyd/analysis/get_metrics.py $FILE_DATA_WEB $FILE_DATA_RECEIVER $rate_web$k $j $FILE_WEB False 0 $FLOW_WEB"

                python3 /home/$USER_LOCAL/cyd/analysis/get_metrics.py $FILE_DATA_VOIP $FILE_DATA_RECEIVER $rate_voip$k $j $FILE_VOIP False 0 $FLOW_VOIP
                python3 /home/$USER_LOCAL/cyd/analysis/get_metrics.py $FILE_DATA_WEB $FILE_DATA_RECEIVER $rate_web$k $j $FILE_WEB False 0 $FLOW_WEB

                ssh dev-$VM_VOIP "echo $pwd_voip | sudo -S pkill sender_receiver"
                ssh dev-$VM_WEB "echo $pwd_web | sudo -S pkill sender_receiver"
                ssh dev-$VM_COMBINED "echo $pwd_combined | sudo -S pkill sender_receiver"
                sleep 1
            done
        done

        ssh dev-$VM_VOIP "echo $pwd_voip | sudo -S pkill budget_ditto"
        ssh dev-$VM_WEB "echo $pwd_web | sudo -S pkill budget_ditto"
        ssh dev-$VM_COMBINED "echo $pwd_combined | sudo -S pkill budget_ditto"
        sleep 1
    done  
fi


ssh dev-$VM_VOIP "echo $pwd_voip | sudo -S pkill budget_ditto"
ssh dev-$VM_WEB "echo $pwd_web | sudo -S pkill budget_ditto"
ssh dev-$VM_COMBINED "echo $pwd_combined | sudo -S pkill budget_ditto"
ssh dev-$VM_VOIP "echo $pwd_voip | sudo -S pkill sender_receiver"
ssh dev-$VM_WEB "echo $pwd_web | sudo -S pkill sender_receiver"
ssh dev-$VM_COMBINED "echo $pwd_combined | sudo -S pkill sender_receiver"


