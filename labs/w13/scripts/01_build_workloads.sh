#!/usr/bin/env bash
set -euo pipefail

SRC=${1:-workloads/array_sum.c}
mkdir -p build
name=$(basename "$SRC" .c)
OUT="build/${name}.riscv"

echo "[BUILD] $SRC -> $OUT"
riscv64-linux-gnu-gcc -O2 -static -march=rv64gc -mabi=lp64d "$SRC" -o "$OUT"
riscv64-linux-gnu-size "$OUT" || true
echo "$OUT"
