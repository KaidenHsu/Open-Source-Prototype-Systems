#!/usr/bin/env bash
set -euo pipefail

# get script directory instead of current directory
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OUT_DIR="${ROOT_DIR}/obj_dir"

# make sure verilator is in PATH
if ! command -v verilator >/dev/null 2>&1; then
    echo "verilator binary not found in PATH" >&2
    exit 1
fi

# avoid locale warnings in minimal containers (en_US.UTF-8 not installed)
export LANG=C.utf8
export LC_ALL=C.utf8
unset LANGUAGE

echo "> building..."
make -C "$ROOT_DIR" build

printf "\n\n"
echo "============================"
echo "       no hazard test"
echo "============================"
make -C "$ROOT_DIR" run-nohaz

printf "\n\n"
echo "============================"
echo "      forwarding test"
echo "============================"
make -C "$ROOT_DIR" run-forward

printf "\n\n"
echo "============================"
echo "     branch taken test"
echo "============================"
make -C "$ROOT_DIR" run-branch

printf "\n\n"
echo "============================"
echo "     temporal test"
echo "============================"
make -C "$ROOT_DIR" run-temporal

printf "\n\n"
echo "============================"
echo "     conflict test"
echo "============================"
make -C "$ROOT_DIR" run-conflict

printf "\n\n"
echo "--------------------------------               "
echo "--                            --       |\__||  "
echo "--  Congratulations !!        --      / O.O  | "
echo "--                            --    /_____   | "
echo "--  All Test Cases Passed !!  --   /^ ^ ^ \\  |"
echo "--                            --  |^ ^ ^ ^ |w| "
echo "--------------------------------   \\m___m__|_|"