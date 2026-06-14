#!/usr/bin/env bash
set -euo pipefail

BINARY=${1:-build/array_sum.riscv}

CPU_TYPE=TimingSimpleCPU CPU_CLOCK=1GHz SYS_CLOCK=1GHz L1I_SIZE=32kB L1D_SIZE=32kB L2_SIZE=256kB L1I_ASSOC=2 L1D_ASSOC=2 L2_ASSOC=8 \
  bash scripts/02_run_gem5_one.sh "$BINARY" baseline

CPU_TYPE=TimingSimpleCPU CPU_CLOCK=1GHz SYS_CLOCK=1GHz L1I_SIZE=32kB L1D_SIZE=64kB L2_SIZE=256kB L1I_ASSOC=2 L1D_ASSOC=4 L2_ASSOC=8 \
  bash scripts/02_run_gem5_one.sh "$BINARY" l1d_big

CPU_TYPE=TimingSimpleCPU CPU_CLOCK=1.2GHz SYS_CLOCK=1GHz L1I_SIZE=32kB L1D_SIZE=32kB L2_SIZE=256kB L1I_ASSOC=2 L1D_ASSOC=2 L2_ASSOC=8 \
  bash scripts/02_run_gem5_one.sh "$BINARY" freq_fast
