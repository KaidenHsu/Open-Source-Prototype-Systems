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

printf "\n"
echo "============================"
echo "          lint"
echo "============================"
make -C "$ROOT_DIR" lint

printf "\n\n"
echo "============================"
echo "          run rtl"
echo "============================"
make -C "$ROOT_DIR" run_rtl
