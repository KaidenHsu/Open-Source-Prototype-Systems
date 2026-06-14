#!/usr/bin/env bash
set -euo pipefail

for tool in make python3 verilator yosys; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: missing $tool"
    exit 1
  fi
done

echo "verilator: $(verilator --version)"
echo "yosys: $(yosys -V)"
echo "python: $(python3 --version)"
echo ""
echo "Running small fixed-priority sanity simulation..."
make --no-print-directory sim POLICY=fixed N0=4 N1=4 MAX_CYCLES=200 CHECK_FAIR=0

echo ""
echo "Environment check passed."
