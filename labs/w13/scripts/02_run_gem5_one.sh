#!/usr/bin/env bash
set -euo pipefail

BINARY=${1:?Usage: 02_run_gem5_one.sh <binary> <config-name>}
CFG=${2:?Usage: 02_run_gem5_one.sh <binary> <config-name>}

GEM5=${GEM5:-$(python3 scripts/find_gem5.py)}
SE=${GEM5_SE_CONFIG:-$(python3 scripts/find_se_config.py)}
OUTDIR="results/${CFG}/gem5"
mkdir -p "$OUTDIR"

CPU_TYPE=${CPU_TYPE:-TimingSimpleCPU}
CPU_CLOCK=${CPU_CLOCK:-1GHz}
SYS_CLOCK=${SYS_CLOCK:-1GHz}
L1I_SIZE=${L1I_SIZE:-32kB}
L1D_SIZE=${L1D_SIZE:-32kB}
L2_SIZE=${L2_SIZE:-256kB}
L1I_ASSOC=${L1I_ASSOC:-2}
L1D_ASSOC=${L1D_ASSOC:-2}
L2_ASSOC=${L2_ASSOC:-8}
MEM_SIZE=${MEM_SIZE:-512MB}

cat > "results/${CFG}/run_config.env" <<EOF2
CFG=$CFG
BINARY=$BINARY
CPU_TYPE=$CPU_TYPE
CPU_CLOCK=$CPU_CLOCK
SYS_CLOCK=$SYS_CLOCK
L1I_SIZE=$L1I_SIZE
L1D_SIZE=$L1D_SIZE
L2_SIZE=$L2_SIZE
L1I_ASSOC=$L1I_ASSOC
L1D_ASSOC=$L1D_ASSOC
L2_ASSOC=$L2_ASSOC
MEM_SIZE=$MEM_SIZE
EOF2

CMD=("$GEM5" -d "$OUTDIR" "$SE" \
  --cmd="$BINARY" \
  --cpu-type="$CPU_TYPE" \
  --sys-clock="$SYS_CLOCK" \
  --cpu-clock="$CPU_CLOCK" \
  --mem-size="$MEM_SIZE" \
  --caches --l2cache \
  --l1i_size="$L1I_SIZE" --l1d_size="$L1D_SIZE" --l2_size="$L2_SIZE" \
  --l1i_assoc="$L1I_ASSOC" --l1d_assoc="$L1D_ASSOC" --l2_assoc="$L2_ASSOC")

printf '%q \n' "${CMD[@]}" | tee "results/${CFG}/gem5_command.txt"
echo | tee -a "results/${CFG}/gem5_command.txt"
"${CMD[@]}" 2>&1 | tee "results/${CFG}/gem5_terminal.log"
