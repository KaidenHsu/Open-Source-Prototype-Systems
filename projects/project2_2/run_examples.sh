#!/usr/bin/env bash
set -e

CC=${CC:-riscv64-linux-gnu-gcc}
GEM5=${GEM5:-/opt/gem5/build/RISCV/gem5.opt}
SE=${SE:-/opt/gem5/configs/deprecated/example/se.py}

$CC -O2 -static -o histogram_baseline.riscv histogram_baseline.c
$CC -O2 -static -o histogram_optimized.riscv histogram_optimized.c

$GEM5 -d m5out_hist_base $SE --cmd=./histogram_baseline.riscv
$GEM5 -d m5out_hist_opt  $SE --cmd=./histogram_optimized.riscv

echo "=== baseline ==="
grep -E "simInsts|numCycles|ipc|cpi" m5out_hist_base/stats.txt || true
echo "=== optimized ==="
grep -E "simInsts|numCycles|ipc|cpi" m5out_hist_opt/stats.txt || true
