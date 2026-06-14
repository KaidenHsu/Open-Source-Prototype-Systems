#!/usr/bin/env bash
set -euo pipefail

fail=0
check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "[OK] $1: $(command -v "$1")"
  else
    echo "[MISS] $1"
    fail=1
  fi
}

check_cmd python3
check_cmd mcpat
check_cmd verilator
check_cmd riscv64-linux-gnu-gcc

if command -v gem5.opt >/dev/null 2>&1; then
  echo "[OK] gem5.opt: $(command -v gem5.opt)"
elif [ -x /opt/gem5/build/RISCV/gem5.opt ]; then
  echo "[OK] gem5.opt: /opt/gem5/build/RISCV/gem5.opt"
else
  echo "[MISS] gem5.opt"
  fail=1
fi

python3 - <<'PY'
import importlib
for name in ['numpy', 'pandas', 'matplotlib', 'lxml', 'yaml']:
    importlib.import_module(name)
print('[OK] Python packages: numpy pandas matplotlib lxml yaml')
PY

if [ "$fail" -ne 0 ]; then
  echo "One or more required tools are missing. Use amansinhaatnycu/osp:week13-power."
  exit 1
fi
