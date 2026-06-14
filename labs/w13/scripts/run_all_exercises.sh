#!/usr/bin/env bash
set -euo pipefail

SRC=${1:-workloads/array_sum.c}
BIN=$(bash scripts/01_build_workloads.sh "$SRC" | tail -1)

bash scripts/00_check_tools.sh
bash scripts/01_build_workloads.sh
bash scripts/02_run_gem5_sweep.sh "$BIN"
bash scripts/04_run_mcpat_sweep.sh
python3 scripts/05_summarize_results.py results
