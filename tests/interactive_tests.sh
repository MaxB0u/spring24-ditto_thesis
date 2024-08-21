#!/usr/bin/bash

echo "Starting interactive applications tests..."

NUM_RUNS=30

TEST_NORMAL=false
TEST_DITTO=false
RUN_WEB_BACKGROUND_TRAFFIC=false
RUN_VOIP_BACKGROUND_TRAFFIC=true

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

WEBSITES=(
    "yahoo.com"
    "wikipedia.org"
    "reddit.com"
    "www.google.com"
    "www.facebook.com"
    "www.youtube.com"
    "twitter.com"
    "instagram.com"
    "amazon.com"
    # "www.youtube.com/t/advertising_overview"
    # "www.apple.com/iphone/"
)

WEB_RECCORDINGS=(
    "yahoo.wprgo"
    "wikipedia.wprgo"
    "reddit.wprgo"
    "google.wprgo"
    "facebook.wprgo"
    "youtube.wprgo"
    "x.wprgo"
    "instagram.wprgo"
    "amazon.wprgo"
    # "youtube_large.wprgo"
    # "apple_large.wprgo"
)

USER_LOCAL='max'

OUTPUT_FILE="$USER_LOCAL/web/web_results2.csv"

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
    IP_INPUT_WG="10.7.0.1"
    IP_INPUT_DITTO="10.30.0.20"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_ditto/dst='$ADDR_THUN'/g\" /home/lab/$USER_LOCAL/budget_ditto/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_sr/dst='$ADDR_THUN'/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
elif [ "$VM_SENDER" = "zurich" ]; then
    IP_INPUT_WG="10.7.0.2"
    IP_INPUT_DITTO="10.20.0.10"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_ditto/dst='$ADDR_ZURICH'/g\" /home/lab/$USER_LOCAL/budget_ditto/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_sr/dst='$ADDR_ZURICH'/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
elif [ "$VM_SENDER" = "lausanne" ]; then
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_ditto/dst='$ADDR_LAUSANNE'/g\" /home/lab/$USER_LOCAL/budget_ditto/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$dst_sr/dst='$ADDR_LAUSANNE'/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
fi

sshfs dev-$VM_SENDER:/home/lab/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_SENDER
sshfs dev-$VM_RECEIVER:/home/lab/$USER_LOCAL /home/$USER_LOCAL/cyd/remote/$VM_RECEIVER
ssh dev-$VM_SENDER "pkill -f 'go run src/wpr.go replay'"
ssh dev-$VM_SENDER "pkill -f '/tmp/go-build.*/exe/wpr replay'"

pwd_file_sender="/home/$USER_LOCAL/cyd/remote/.auth/$VM_SENDER"
pwd_sender=$(<"$pwd_file_sender")
pwd_sender=$(echo "$pwd_sender" | tr -d '\n')

pwd_file_receiver="/home/$USER_LOCAL/cyd/remote/.auth/$VM_RECEIVER"
pwd_receiver=$(<"$pwd_file_receiver")
pwd_receiver=$(echo "$pwd_receiver" | tr -d '\n')

cmd_ditto_sender="cd $USER_LOCAL/budget_ditto && echo $pwd_sender | sudo -S -E /home/lab/.cargo/bin/cargo run config/config_client_$VM_SENDER.toml $SUPPRESS_CONSOLE_OUTPUT"
cmd_ditto_receiver="cd $USER_LOCAL/budget_ditto && echo $pwd_receiver | sudo -S -E /home/lab/.cargo/bin/cargo run config/config_client_$VM_RECEIVER.toml $SUPPRESS_CONSOLE_OUTPUT"
cmd_sender="cd $USER_LOCAL/sender_receiver && echo $pwd_sender | sudo -S -E /home/lab/.cargo/bin/cargo run config/config_client_$VM_SENDER.toml $SUPPRESS_CONSOLE_OUTPUT"
cmd_receiver="cd $USER_LOCAL/sender_receiver && echo $pwd_receiver | sudo -S -E /home/lab/.cargo/bin/cargo run config/config_client_$VM_RECEIVER.toml $SUPPRESS_CONSOLE_OUTPUT"

cmd_voip_sender="cd $USER_LOCAL/sender_receiver && echo $pwd_sender | sudo -S -E /home/lab/.cargo/bin/cargo run config/config_client_voip_$VM_SENDER.toml $SUPPRESS_CONSOLE_OUTPUT"
cmd_voip_receiver="cd $USER_LOCAL/sender_receiver && echo $pwd_receiver | sudo -S -E /home/lab/.cargo/bin/cargo run config/config_client_voip_$VM_RECEIVER.toml $SUPPRESS_CONSOLE_OUTPUT"

FILE_DATA_SENDER="/home/$USER_LOCAL/cyd/remote/$VM_SENDER/sender_receiver/tx_data_0.csv"
FILE_DATA_RECEIVER="/home/$USER_LOCAL/cyd/remote/$VM_RECEIVER/sender_receiver/rx_data.csv"

# Kill lingering processes
ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto"

if $TEST_NORMAL; then
    echo "Running tests over normal wireguard connection"
    cmd_web_server="cd $USER_LOCAL/catapult/web_page_replay_go && /usr/local/go/bin/go run src/wpr.go replay --http_port=8080 --https_port=8081 --host=$IP_INPUT_WG"
    
    for ((i=0; i < ${#WEBSITES[@]}; i++)); do
        page_name="${WEBSITES[i]}"
        web_reccording="${WEB_RECCORDINGS[i]}"

        ssh dev-$VM_SENDER $cmd_web_server $web_reccording $SUPPRESS_CONSOLE_OUTPUT &

        sleep 2
        for ((j=1; j<=NUM_RUNS; j++)); do
            echo "Run $j"
            # python3 web/script_web_load.py $page_name $IP_INPUT_WG $OUTPUT_FILE $j 0
            ssh dev-$VM_RECEIVER "python3 /home/$USER_LOCAL/cyd/analysis/web_load_time.py $page_name $IP_INPUT_DITTO $IP_INPUT_WG $j 0"
            sleep 1
        done

        ssh dev-$VM_SENDER "pkill -f 'go run src/wpr.go replay'"
        ssh dev-$VM_SENDER "pkill -f '/tmp/go-build.*/exe/wpr replay'"

        sleep 1
    done
fi

if $TEST_DITTO; then
    echo "Running tests over Ditto"
    cmd_web_server="cd $USER_LOCAL/catapult/web_page_replay_go && /usr/local/go/bin/go run src/wpr.go replay --http_port=8080 --https_port=8081 --host=$IP_INPUT_DITTO"

    for ((k=0; k < ${#PATTERNS[@]}; k++)); do
        # Set pattern
        pattern="${PATTERNS[k]}"
        pattern="${pattern//[/\\[}"
        echo "Running with pattern $pattern"

        pattern_sender=$(ssh dev-$VM_SENDER "grep 'pub const PATTERN' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs")
        pattern_receiver=$(ssh dev-$VM_RECEIVER "grep 'pub const PATTERN' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs")
        pattern_sender="${pattern_sender//[/\\[}"
        pattern_receiver="${pattern_receiver//[/\\[}"
        ssh dev-$VM_SENDER "sed -i 's/$pattern_sender/$pattern/g' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs"
        ssh dev-$VM_RECEIVER "sed -i 's/$pattern_receiver/$pattern/g' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs"

        # Start ditto in sender and receiver
        ssh dev-$VM_SENDER "$cmd_ditto_sender" &
        ssh dev-$VM_RECEIVER "$cmd_ditto_receiver" &
        sleep 2

        pattern_idx=$((k+1))
        for ((i=0; i < ${#WEBSITES[@]}; i++)); do
            page_name="${WEBSITES[i]}"
            web_reccording="${WEB_RECCORDINGS[i]}"

            ssh dev-$VM_SENDER $cmd_web_server $web_reccording $SUPPRESS_CONSOLE_OUTPUT &

            sleep 2
            for ((j=1; j<=NUM_RUNS; j++)); do
                echo "Run $j"
                # python3 web/script_web_load.py $page_name $IP_INPUT_DITTO $OUTPUT_FILE $j $pattern_idx
                ssh dev-$VM_RECEIVER "python3 /home/$USER_LOCAL/cyd/analysis/web_load_time.py $page_name $IP_INPUT_DITTO $OUTPUT_FILE $j $pattern_idx"
                # ssh -X dev-$VM_RECEIVER "cd $USER_LOCAL/web && python3 script_web_load.py $page_name $IP_INPUT_DITTO $OUTPUT_FILE $j $pattern_idx"
                sleep 1
            done

            ssh dev-$VM_SENDER "pkill -f 'go run src/wpr.go replay'"
            ssh dev-$VM_SENDER "pkill -f '/tmp/go-build.*/exe/wpr replay'"
            ssh dev-$VM_RECEIVER "rm -r $USER_LOCAL/web/'\$foo'"
            sleep 1
        done

        ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
        ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto"
        sleep 1
    done  
fi

OUTPUT_FILE="$USER_LOCAL/web/web_results_background_traffic.csv"


ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto"
ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill sender_receiver"
ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill sender_receiver"
sleep 1

if $RUN_WEB_BACKGROUND_TRAFFIC; then
    echo "Running web tests with background traffic..."
    cmd_web_server="cd $USER_LOCAL/catapult/web_page_replay_go && /usr/local/go/bin/go run src/wpr.go replay --http_port=8080 --https_port=8081 --host=$IP_INPUT_DITTO"
    
    RATES=("0.0" "1.0" "10.0" "50.0" "66.0" "70.0" "75.0" "80.0" "85.0")

    idx=2
    pattern="${PATTERNS[$idx]}"
    pattern_idx=$((idx+1))
    echo "Running with pattern $pattern"

    pattern_sender=$(ssh dev-$VM_SENDER "grep 'pub const PATTERN' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_receiver=$(ssh dev-$VM_RECEIVER "grep 'pub const PATTERN' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_sender="${pattern_sender//[/\\[}"
    pattern_receiver="${pattern_receiver//[/\\[}"
    ssh dev-$VM_SENDER "sed -i 's/$pattern_sender/$pattern/g' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs"
    ssh dev-$VM_RECEIVER "sed -i 's/$pattern_receiver/$pattern/g' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs"

    # Set send/receive/save in configs
    sends=$(ssh dev-$VM_SENDER "grep 'send=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    receives=$(ssh dev-$VM_SENDER "grep 'receive=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    ssh dev-$VM_SENDER "sed -i \"s/$sends/send=true/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_SENDER "sed -i \"s/$receives/receive=false/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"

    sends=$(ssh dev-$VM_RECEIVER "grep 'send=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    receives=$(ssh dev-$VM_RECEIVER "grep 'receive=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_RECEIVER "sed -i \"s/$sends/send=true/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$receives/receive=false/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

    save_sender=$(ssh dev-$VM_SENDER "grep 'save=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    ssh dev-$VM_SENDER "sed -i \"s/$save_sender/save=false/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    save_receiver=$(ssh dev-$VM_RECEIVER "grep 'save=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_RECEIVER "sed -i \"s/$save_receiver/save=false/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

    rate_old=$(ssh dev-$VM_SENDER "grep 'rate' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    rate_old_rx=$(ssh dev-$VM_RECEIVER "grep 'rate' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")

    # Wait 1s before starting test runs
    sleep 1

    # Start ditto in sender and receiver
    ssh dev-$VM_SENDER "$cmd_ditto_sender" &
    ssh dev-$VM_RECEIVER "$cmd_ditto_receiver" &

    for ((k=0; k < ${#RATES[@]}; k++)); do
        rate="${RATES[k]}"

        # Modify pps and num_pkts parameters
        rate_new="rate=$rate"
        ssh dev-$VM_SENDER "sed -i 's/$rate_old/$rate_new/g' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
        ssh dev-$VM_RECEIVER "sed -i 's/$rate_old_rx/$rate_new/g' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
        rate_old=$rate_new
        rate_old_rx=$rate_new

        # Send from sender to receiver
        echo "Background traffic running at $rate Mbps"
        sleep 1
        ssh dev-$VM_RECEIVER "$cmd_receiver" &
        ssh dev-$VM_SENDER "$cmd_sender" &
        sleep 1

        for ((i=0; i < ${#WEBSITES[@]}; i++)); do
            page_name="${WEBSITES[i]}"
            web_reccording="${WEB_RECCORDINGS[i]}"

            for ((j=1; j<=NUM_RUNS; j++)); do
                echo "Run $j"
                ssh dev-$VM_SENDER $cmd_web_server $web_reccording $SUPPRESS_CONSOLE_OUTPUT &
                sleep 1
                # python3 web/script_web_load.py $page_name $IP_INPUT_DITTO $OUTPUT_FILE $j $pattern_idx
                ssh dev-$VM_RECEIVER "python3 /home/$USER_LOCAL/cyd/analysis/web_load_time.py $page_name $IP_INPUT_DITTO $OUTPUT_FILE $j $rate"

                ssh dev-$VM_SENDER "pkill -f 'go run src/wpr.go replay'"
                ssh dev-$VM_SENDER "pkill -f '/tmp/go-build.*/exe/wpr replay'"
                ssh dev-$VM_RECEIVER "rm -r '\$foo'"
                sleep 1
            done
        done

        ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill sender_receiver"
        ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill sender_receiver"
        sleep 1
    done
    # Stop ditto in sender and receiver
    ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
    ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto" 

    # Set send/receive/save in configs
    sends=$(ssh dev-$VM_SENDER "grep 'send=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    receives=$(ssh dev-$VM_SENDER "grep 'receive=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    ssh dev-$VM_SENDER "sed -i \"s/$sends/send=true/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_SENDER "sed -i \"s/$receives/receive=false/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"

    sends=$(ssh dev-$VM_RECEIVER "grep 'send=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    receives=$(ssh dev-$VM_RECEIVER "grep 'receive=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_RECEIVER "sed -i \"s/$sends/send=false/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$receives/receive=true/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

    save_sender=$(ssh dev-$VM_SENDER "grep 'save=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    ssh dev-$VM_SENDER "sed -i \"s/$save_sender/save=true/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    save_receiver=$(ssh dev-$VM_RECEIVER "grep 'save=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_RECEIVER "sed -i \"s/$save_receiver/save=true/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml" 
fi

if $RUN_VOIP_BACKGROUND_TRAFFIC; then
    echo "Running voip tests with background traffic..."
    
    FILE="/home/$USER_LOCAL/cyd/analysis/results/results_voip2_${VM_SENDER}_${VM_RECEIVER}_${RESULT_FILE_SUFFIX}.csv"
    # RATES=("0.0" "1.0" "10.0" "20.0" "30.0" "40.0" "50.0" "60.0" "66.0" "70.0" "75.0" "80.0" "85.0")
    # RATES=("0.0" "1.0" "20.0" "40.0" "60.0" "80.0" "100.0" "120.0" "130.0" "140.0" "150.0" "160.0" "170.0")
    RATES=("0.0" "5.0" "50.0" "100.0" "150.0" "200.0" "250.0" "300.0" "330.0" "350.0" "375.0" "400.0" "425.0")

    idx=2
    pattern="${PATTERNS[$idx]}"
    pattern_idx=$((idx+1))
    echo "Running with pattern $pattern"

    pattern_sender=$(ssh dev-$VM_SENDER "grep 'pub const PATTERN' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_receiver=$(ssh dev-$VM_RECEIVER "grep 'pub const PATTERN' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs")
    pattern_sender="${pattern_sender//[/\\[}"
    pattern_receiver="${pattern_receiver//[/\\[}"
    ssh dev-$VM_SENDER "sed -i 's/$pattern_sender/$pattern/g' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs"
    ssh dev-$VM_RECEIVER "sed -i 's/$pattern_receiver/$pattern/g' /home/lab/$USER_LOCAL/budget_ditto/src/pattern.rs"

    # Set send/receive/save in configs
    sends=$(ssh dev-$VM_SENDER "grep 'send=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    receives=$(ssh dev-$VM_SENDER "grep 'receive=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    ssh dev-$VM_SENDER "sed -i \"s/$sends/send=true/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_SENDER "sed -i \"s/$receives/receive=false/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"

    sends=$(ssh dev-$VM_RECEIVER "grep 'send=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    receives=$(ssh dev-$VM_RECEIVER "grep 'receive=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_RECEIVER "sed -i \"s/$sends/send=true/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$receives/receive=false/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

    save_sender=$(ssh dev-$VM_SENDER "grep 'save=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    ssh dev-$VM_SENDER "sed -i \"s/$save_sender/save=false/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    save_receiver=$(ssh dev-$VM_RECEIVER "grep 'save=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_RECEIVER "sed -i \"s/$save_receiver/save=false/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

    rate_old=$(ssh dev-$VM_SENDER "grep 'rate' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    rate_old_rx=$(ssh dev-$VM_RECEIVER "grep 'rate' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")

    # Wait 1s before starting test runs
    sleep 1

    # Start ditto in sender and receiver
    ssh dev-$VM_SENDER "$cmd_ditto_sender" &
    ssh dev-$VM_RECEIVER "$cmd_ditto_receiver" &

    for ((k=5; k < ${#RATES[@]}; k++)); do
        rate="${RATES[k]}"

        # Modify pps and num_pkts parameters
        rate_new="rate=$rate"
        ssh dev-$VM_SENDER "sed -i 's/$rate_old/$rate_new/g' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
        ssh dev-$VM_RECEIVER "sed -i 's/$rate_old_rx/$rate_new/g' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
        rate_old=$rate_new
        rate_old_rx=$rate_new

        # Send from sender to receiver
        echo "Background traffic running at $rate Mbps"

        for ((i=1; i<=NUM_RUNS; i++)); do
            echo "Run $i"
            
            sleep 1
            ssh dev-$VM_SENDER "$cmd_sender" &
            sleep 1
            ssh dev-$VM_RECEIVER "$cmd_voip_receiver" &
            sleep 1
            ssh dev-$VM_SENDER "$cmd_voip_sender"

            sleep 1
            ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill sender_receiver"
            ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill sender_receiver"
            sleep 1

            # Log data
            python3 /home/$USER_LOCAL/cyd/analysis/get_metrics.py $FILE_DATA_SENDER $FILE_DATA_RECEIVER $rate $i $FILE False
            
        done
    done
    # Stop ditto in sender and receiver
    ssh dev-$VM_SENDER "echo $pwd_sender | sudo -S pkill budget_ditto"
    ssh dev-$VM_RECEIVER "echo $pwd_receiver | sudo -S pkill budget_ditto" 

    # Set send/receive/save in configs
    sends=$(ssh dev-$VM_SENDER "grep 'send=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    receives=$(ssh dev-$VM_SENDER "grep 'receive=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    ssh dev-$VM_SENDER "sed -i \"s/$sends/send=true/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    ssh dev-$VM_SENDER "sed -i \"s/$receives/receive=false/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"

    sends=$(ssh dev-$VM_RECEIVER "grep 'send=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    receives=$(ssh dev-$VM_RECEIVER "grep 'receive=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_RECEIVER "sed -i \"s/$sends/send=false/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"
    ssh dev-$VM_RECEIVER "sed -i \"s/$receives/receive=true/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml"

    save_sender=$(ssh dev-$VM_SENDER "grep 'save=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml")
    ssh dev-$VM_SENDER "sed -i \"s/$save_sender/save=true/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_SENDER.toml"
    save_receiver=$(ssh dev-$VM_RECEIVER "grep 'save=' /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml")
    ssh dev-$VM_RECEIVER "sed -i \"s/$save_receiver/save=true/g\" /home/lab/$USER_LOCAL/sender_receiver/config/config_client_$VM_RECEIVER.toml" 
fi