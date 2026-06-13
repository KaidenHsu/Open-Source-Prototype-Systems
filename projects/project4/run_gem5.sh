#!/usr/bin/env bash
set -euo pipefail

# get script directory instead of current directory
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

printf "\n\n"
echo "============================"
echo "           xdot4"
echo "============================"
make -C $ROOT_DIR run_gem5_xdot4

printf "\n\n"
echo "============================"
echo "         optimized"
echo "============================"
make -C $ROOT_DIR run_gem5_optimized

printf "\n\n"
echo "============================"
echo "          scalar"
echo "============================"
make -C $ROOT_DIR run_gem5_scalar
