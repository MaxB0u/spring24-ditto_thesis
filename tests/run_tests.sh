#!/usr/bin/bash

RUN_zurich_thun=true
RUN_zurich_lausanne=false
RUN_thun_lausanne=false

RUN_DITTO=false
RUN_NORMAL=false
RUN_PATTERN=false
RUN_MULTIPLE_FLOWS=false
RUN_SPECIAL_MULT_FLOWS=false
RUN_PATTERN_RATE=false
RUN_VIDEO=true

USE_CAIDA=true

NUM_RUNS=30

USER_LOCAL='max'

# Run edverything for now
run_ditto=$(grep 'RUN_DITTO=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
run_normal=$(grep 'RUN_NORMAL=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
run_pattern=$(grep 'RUN_PATTERN=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
run_multiple_flows=$(grep 'RUN_MULTIPLE_FLOWS=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
run_special_multiple_flows=$(grep 'RUN_SPECIAL_MULT_FLOWS=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
run_pattern_rate=$(grep 'RUN_PATTERN_RATE=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
run_video=$(grep 'RUN_VIDEO=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
sed -i "s/$run_ditto/RUN_DITTO=$RUN_DITTO/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh
sed -i "s/$run_normal/RUN_NORMAL=$RUN_NORMAL/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh
sed -i "s/$run_pattern/RUN_PATTERN=$RUN_PATTERN/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh
sed -i "s/$run_multiple_flows/RUN_MULTIPLE_FLOWS=$RUN_MULTIPLE_FLOWS/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh
sed -i "s/$run_special_multiple_flows/RUN_SPECIAL_MULT_FLOWS=$RUN_SPECIAL_MULT_FLOWS/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh
sed -i "s/$run_pattern_rate/RUN_PATTERN_RATE=$RUN_PATTERN_RATE/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh
sed -i "s/$run_video/RUN_VIDEO=$RUN_VIDEO/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh

# Do not use caida for now
use_caida=$(grep 'USE_CAIDA=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
sed -i "s/$use_caida/USE_CAIDA=$USE_CAIDA/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh

num_runs=$(grep 'NUM_RUNS=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
sed -i "s/$num_runs/NUM_RUNS=$NUM_RUNS/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh

# Run tests between Zurich and Thun
if $RUN_zurich_thun; then
    echo "Running tests between Zurich and Thun"
    sender=$(grep 'VM_SENDER=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
    receiver=$(grep 'VM_RECEIVER=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
    sed -i "s/$sender/VM_SENDER='zurich'/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh
    sed -i "s/$receiver/VM_RECEIVER='thun'/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh

    bash /home/$USER_LOCAL/cyd/tests/metric_tests.sh
fi

# Run tests between Zurich and Lausanne
if $RUN_zurich_lausanne; then
    echo "Running tests between Zurich and Lausanne"
    sender=$(grep 'VM_SENDER=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
    receiver=$(grep 'VM_RECEIVER=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
    sed -i "s/$sender/VM_SENDER='zurich'/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh
    sed -i "s/$receiver/VM_RECEIVER='lausanne'/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh

    bash /home/$USER_LOCAL/cyd/tests/metric_tests.sh
fi

# Run tests between Thun and Lausanne
if $RUN_thun_lausanne; then
    echo "Running tests between Thun and Lausanne"
    sender=$(grep 'VM_SENDER=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
    receiver=$(grep 'VM_RECEIVER=' /home/$USER_LOCAL/cyd/tests/metric_tests.sh)
    sed -i "s/$sender/VM_SENDER='thun'/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh
    sed -i "s/$receiver/VM_RECEIVER='lausanne'/g" /home/$USER_LOCAL/cyd/tests/metric_tests.sh

    bash /home/$USER_LOCAL/cyd/tests/metric_tests.sh
fi
