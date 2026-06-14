#!/usr/bin/env bash
set -e

mode=${1:-uniform}

make -C /opt/osp-xhist baseline MODE="$mode"

qemu-riscv64-xhist "/opt/osp-xhist/build/hist_baseline.${mode}.riscv"
