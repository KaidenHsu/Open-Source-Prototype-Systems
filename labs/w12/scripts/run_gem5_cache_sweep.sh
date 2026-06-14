#!/usr/bin/env bash
set -euo pipefail

# avoid locale warnings in minimal containers (en_US.UTF-8 not installed)
export LANG=C.utf8
export LC_ALL=C.utf8
unset LANGUAGE

# Sweep L1 data cache sizes and run gem5 for each size
SIZES=(8kB 32kB 64kB)
SE_PY=/opt/osp-xhist/gem5/configs/deprecated/example/se.py

for SIZE in "${SIZES[@]}"; do
    OUTDIR=results/gem5_baseline_l1d_${SIZE}
    WORKLOAD=/opt/osp-xhist/build/hist_baseline.uniform.riscv
    mkdir -p "$OUTDIR"
    echo "Running baseline for L1D size=$SIZE -> $OUTDIR"
    gem5-riscv-xhist \
        --outdir="$OUTDIR" \
        "$SE_PY" \
        --cmd="$WORKLOAD" \
        --cpu-type=TimingSimpleCPU \
        --caches \
        --l1d_size=${SIZE} \
        --l1i_size=32kB \
        --cacheline_size=64

    OUTDIR=results/gem5_xhist_l1d_${SIZE}
    WORKLOAD=/opt/osp-xhist/build/hist_xhist.uniform.riscv
    mkdir -p "$OUTDIR"
    echo "Running xhist for L1D size=$SIZE -> $OUTDIR"
    gem5-riscv-xhist \
        --outdir="$OUTDIR" \
        "$SE_PY" \
        --cmd="$WORKLOAD" \
        --cpu-type=TimingSimpleCPU \
        --caches \
        --l1d_size=${SIZE} \
        --l1i_size=32kB \
        --cacheline_size=64
done
