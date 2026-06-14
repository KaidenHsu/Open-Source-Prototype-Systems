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

mkdir -p log/

# build
echo "> building ..."
make build

# capacity
printf "\n\n"
echo " --------------------"
echo "       CAPACITY      "
echo " --------------------"
make run-capacity | tee log/capacity.log

# conflict
printf "\n\n"
echo " --------------------"
echo "       CONFLICT      "
echo " --------------------"
make run-conflict | tee log/conflict.log

# spatial
printf "\n\n"
echo " --------------------"
echo "       SPATIAL      "
echo " --------------------"
make run-spatial | tee log/spatial.log

# temporal
printf "\n\n"
echo " --------------------"
echo "       TEMPORAL      "
echo " --------------------"
make run-temporal | tee log/temporal.log

# write reuse
printf "\n\n"
echo " --------------------"
echo "     WRITE REUSE     "
echo " --------------------"
make run-write | tee log/write_reuse.log
