#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/gem5/m5out/producer_consumer"
SRC="$ROOT_DIR/gem5/workloads/producer_consumer.c"
BIN="$ROOT_DIR/gem5/bin/producer_consumer.riscv"
ITERS="${ITERS:-2048}"

find_gem5() {
  if command -v gem5.opt >/dev/null 2>&1; then
    command -v gem5.opt
  elif [ -x /opt/gem5/build/RISCV/gem5.opt ]; then
    echo /opt/gem5/build/RISCV/gem5.opt
  elif [ -x /opt/gem5/build/X86/gem5.opt ]; then
    echo /opt/gem5/build/X86/gem5.opt
  else
    return 1
  fi
}

find_se_py() {
  for p in \
    /opt/gem5/configs/deprecated/example/se.py \
    /opt/gem5/configs/example/se.py \
    "$ROOT_DIR/../gem5/configs/deprecated/example/se.py" \
    "$ROOT_DIR/../gem5/configs/example/se.py"; do
    if [ -f "$p" ]; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

find_riscv_gcc() {
  if [ -n "${RISCV_CC:-}" ] && command -v "$RISCV_CC" >/dev/null 2>&1; then
    echo "$RISCV_CC"
    return 0
  fi
  for cc in riscv64-linux-gnu-gcc riscv64-unknown-linux-gnu-gcc riscv64-unknown-elf-gcc; do
    if command -v "$cc" >/dev/null 2>&1; then
      echo "$cc"
      return 0
    fi
  done
  return 1
}

GEM5="$(find_gem5)" || {
  echo "ERROR: gem5.opt not found. Check the Docker image." >&2
  exit 1
}
SE_PY="$(find_se_py)" || {
  echo "ERROR: Could not find gem5 se.py under /opt/gem5/configs." >&2
  exit 1
}
CC="$(find_riscv_gcc)" || {
  echo "ERROR: RISC-V cross compiler not found." >&2
  echo "Install/use one of: riscv64-linux-gnu-gcc, riscv64-unknown-linux-gnu-gcc, riscv64-unknown-elf-gcc" >&2
  echo "Or set RISCV_CC=/path/to/compiler." >&2
  exit 1
}

mkdir -p "$(dirname "$BIN")"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

echo "Using gem5: $GEM5"
echo "Using config: $SE_PY"
echo "Using compiler: $CC"
echo "Building workload: $BIN"

# Exactly one pthread is created. The main thread acts as the consumer, and the
# pthread acts as the producer. This uses two thread contexts on two CPUs and
# avoids host-file IPC and renameat2.
"$CC" -O2 -std=gnu11 -static -pthread "$SRC" -o "$BIN"

echo "Running shared-memory producer-consumer workload in gem5 SE mode"

"$GEM5" -d "$OUT_DIR" "$SE_PY" \
  --num-cpus=2 \
  --cpu-type=TimingSimpleCPU \
  --caches \
  --l2cache \
  --mem-size=512MB \
  --cmd="$BIN" \
  --options="$ITERS"

cat <<MSG

Gem5 producer-consumer run complete.
Key files:
- $OUT_DIR/simout
- $OUT_DIR/stats.txt

Expected workload output in simout:
- PRODUCER role=producer ...
- CONSUMER role=consumer ...
- PRODUCER_CONSUMER PASS

Suggested stats to inspect:
MSG

if [ -f "$OUT_DIR/simout" ]; then
  grep -E "PRODUCER|CONSUMER|PRODUCER_CONSUMER|Exiting" "$OUT_DIR/simout" || true
fi

if [ -f "$OUT_DIR/stats.txt" ]; then
  grep -E "^(simTicks|simInsts|hostSeconds|system\.cpu[0-9]+\.(numCycles|committedInsts|numInsts)|system\..*overall(Misses|Accesses)|system\..*demand(Misses|Accesses))" "$OUT_DIR/stats.txt" | head -80 || true
fi
