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

echo "> generating traces..."
make -C "$ROOT_DIR" generate-traces

printf "\n\n"
echo "> checking traces..."
make -C "$ROOT_DIR" trace-check

printf "\n\n"
echo "> building..."
make -C "$ROOT_DIR" build-baseline

printf "\n\n"
echo "============================"
echo "         baseline"
echo "============================"
make -C "$ROOT_DIR" run-baseline

printf "\n\n"
echo "============================"
echo "         case b"
echo "============================"
make -C "$ROOT_DIR" run-case-b

printf "\n\n"
echo "============================"
echo "         case c"
echo "============================"
make -C "$ROOT_DIR" run-case-c

printf "\n\n"
echo "============================"
echo "         case d"
echo "============================"
make -C "$ROOT_DIR" run-case-d

printf "\n\n"
echo "============================"
echo "         case d"
echo "============================"
make -C "$ROOT_DIR" run-case-d

printf "\n\n"
echo "============================"
echo "         RAW trace"
echo "============================"
make -C "$ROOT_DIR" run-raw-trace
