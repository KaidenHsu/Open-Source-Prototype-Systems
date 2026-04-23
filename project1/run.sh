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

# running controller unit test
echo "============================"
echo "    Controller Unit Test"
echo "============================"
echo "> building ..."
make -C "$ROOT_DIR" control_unit
echo ""
echo "> running testbench ..."
"${OUT_DIR}/Vcontrol_unit_tb"

# running register file test
printf "\n\n"
echo "============================"
echo "      Regfile Unit Test"
echo "============================"
echo "> building ..."
make -C "$ROOT_DIR" regfile
echo ""
echo "> running testbench ..."
"${OUT_DIR}/Vregfile_tb"

# running imm gen test
printf "\n\n"
echo "============================"
echo "      Imm Gen Test"
echo "============================"
echo "> building ..."
make -C "$ROOT_DIR" imm_gen
echo ""
echo "> running testbench ..."
"${OUT_DIR}/Vimm_gen_tb"

# running alu unit test
printf "\n\n"
echo "============================"
echo "      ALU Unit Test"
echo "============================"
echo "> building ..."
make -C "$ROOT_DIR" alu
echo ""
echo "> running testbench ..."
"${OUT_DIR}/Valu_tb"

# running top testbench
printf "\n\n"
echo "============================"
echo "   PC & Integration Test"
echo "============================"
echo "> building ..."
make -C "$ROOT_DIR"
echo ""
echo "> running testbench ..."
"${OUT_DIR}/Vtestbench" # plusarg is passed to the simulator at runtime
