#!/usr/bin/env bash
set -euo pipefail

# get script directory instead of current directory
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# check verilator is in PATH
if ! command -v verilator >/dev/null 2>&1; then
    echo "verilator binary not found in PATH" >&2
    exit 1
fi

# avoid locale warnings in minimal containers (en_US.UTF-8 not installed)
export LANG=C.utf8
export LC_ALL=C.utf8
unset LANGUAGE

# environment check
printf "\n"
echo "=============================="
echo "          env check"
echo "============================="
make -C "$ROOT_DIR" env-check

# The fixed-priority baseline should pass correctness.
# It should also show that requester 1 can wait much longer than requester 0.
printf "\n\n"
echo "=============================="
echo "   fixed priority baseline"
echo "=============================="
make -C "$ROOT_DIR" sim POLICY=fixed


# In the unmodified starter version, this should pass correctness but print `FAIL fairness`.
# This is expected. It means the placeholder round-robin path still behaves like fixed priority.
printf "\n\n"
echo "=============================="
echo "         round robin"
echo "=============================="
make -C "$ROOT_DIR" sim POLICY=rr CHECK_FAIR=1
printf "\n"
make check
printf "\n"
make compare

printf "\n\n"
echo "=============================="
echo "    round robin with aging"
echo "=============================="
make -C "$ROOT_DIR" sim POLICY=aging CHECK_FAIR=1
printf "\n"
make check
printf "\n"
make compare

printf "\n\n"
echo "=============================="
echo "      YOSYS synthesis"
echo "=============================="
make yosys POLICY=fixed
make yosys POLICY=rr
make yosys POLICY=aging