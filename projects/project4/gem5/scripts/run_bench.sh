#!/usr/bin/env bash
set -euo pipefail

BENCH=$1
GEM5_BIN=${GEM5_BIN:-/opt/gem5/build/RISCV/gem5.opt}
GEM5_CONFIG=${GEM5_CONFIG:-/opt/gem5/configs/deprecated/example/se.py}
RISCV_GCC=${RISCV_GCC:-riscv64-linux-gnu-gcc}
CFLAGS=${CFLAGS:--O2 -static -march=rv64imafd -mabi=lp64d}

mkdir -p build logs results
$RISCV_GCC $CFLAGS -o build/${BENCH}.riscv gem5/src/${BENCH}.c
$GEM5_BIN --outdir=results/${BENCH} $GEM5_CONFIG --cmd=build/${BENCH}.riscv 2>&1 | tee logs/${BENCH}.log
python3 gem5/scripts/collect_stats.py results/${BENCH}/stats.txt | tee -a logs/${BENCH}.log
