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

# simulate buggy and fixed, test, and analyze
echo "=================================="
echo "     simulation and analysis"
echo "=================================="
make -C $ROOT_DIR sim
printf "\n\n"

# run synthesis and generate Yosys area reports
echo "=================================="
echo "      sythesis and report"
echo "=================================="

# syntehsis, generate reports
make -C $ROOT_DIR synth

# inspect key report lines
grep -E "Number of cells|\$dff|\$mux|\$xor|\$and|\$or" \
    build/yosys_buggy.rpt build/yosys_fixed.rpt | tee build/key_report_lines.log
printf "\n\n"

# optional activity proxy
echo "=================================="
echo "        transition counts"
echo "=================================="
make -C $ROOT_DIR transitions
