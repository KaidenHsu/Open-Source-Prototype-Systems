#!/usr/bin/env bash
set -euo pipefail

# get script directory instead of current directory
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OUT_DIR="${ROOT_DIR}/obj_dir"

# check verilator is in PATH
if ! command -v verilator >/dev/null 2>&1; then
    echo "verilator binary not found in PATH" >&2
    exit 1
fi

# avoid locale warnings in minimal containers (en_US.UTF-8 not installed)
export LANG=C.utf8
export LC_ALL=C.utf8
unset LANGUAGE

printf "\n\n"
echo "> linting ..."
make -C "$ROOT_DIR" lint

printf "\n\n"
echo "============================"
echo "           shared"
echo "============================"
make -C "$ROOT_DIR" run_shared

printf "\n\n"
echo "============================"
echo "           false"
echo "============================"
make -C "$ROOT_DIR" run_false

printf "\n\n"
echo "============================"
echo "           padded"
echo "============================"
make -C "$ROOT_DIR" run_padded

printf "\n\n"
echo "============================"
echo "           local"
echo "============================"
make -C "$ROOT_DIR" run_local
