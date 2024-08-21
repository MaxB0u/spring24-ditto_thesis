import subprocess
import sys


def test_mult_flows():
    return 0


def test_one_flow_one_state():
    return 0


def test_one_flow_per_state():
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python test_mult_flows_new.py <test_name>")
        exit(1)

    test_name = sys.argv[1]

    if test_name == "mult_flows":
        test_mult_flows()
    elif test_name == "one_flow_one_state":
        test_one_flow_one_state()
    elif test_name == "one_flow_per_state":
        test_one_flow_per_state()
