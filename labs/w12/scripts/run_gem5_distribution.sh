#!/usr/bin/env bash
set -euo pipefail

# Run both gem5 workloads (baseline and xhist) across several input distributions.
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

MODES=(
    "uniform"
    "hot-bin-clustered"
    "out-of-range-heavy"
    "adversarial-stride"
)

for mode in "${MODES[@]}"; do
    printf "\n\n"
    echo ">>>>> Running gem5 workloads: $mode <<<"
    printf "\n"

    bash "$ROOT_DIR/run_gem5_baseline.sh" "$mode"
    bash "$ROOT_DIR/run_gem5_xhist.sh" "$mode"

    echo "*** baseline ***"
    grep -E "simInsts|numCycles|ipc|overallMisses" "results/gem5_baseline/$mode/stats.txt"

    printf "\n"
    echo "*** xhist ***"
    grep -E "simInsts|numCycles|ipc|overallMisses" "results/gem5_xhist/$mode/stats.txt"
    
    printf "\n"
    python3 /opt/osp-xhist/scripts/collect_stats.py "results/gem5_baseline/$mode/stats.txt" "results/gem5_xhist/$mode/stats.txt"
done
