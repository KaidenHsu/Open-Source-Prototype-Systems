#!/usr/bin/env bash
set -e

# avoid locale warnings in minimal containers (en_US.UTF-8 not installed)
export LANG=C.utf8
export LC_ALL=C.utf8
unset LANGUAGE

mode=${1:-uniform}

make -C /opt/osp-xhist baseline MODE="$mode"

mkdir -p "results/gem5_baseline/$mode"

binary="/opt/osp-xhist/build/hist_baseline.${mode}.riscv"

gem5-riscv-xhist \
  --outdir="results/gem5_baseline/$mode" \
  /opt/osp-xhist/gem5/configs/deprecated/example/se.py \
  --cmd="$binary" \
  --cpu-type=TimingSimpleCPU \
  --caches \
  --l1d_size=32kB \
  --l1i_size=32kB \
  --cacheline_size=64
