#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
OBJ_DIR="$BUILD_DIR/obj_dir"
mkdir -p "$OBJ_DIR"

verilator -Wall -Wno-fatal --trace \
  --cc --exe --build \
  --top-module tiny_system_todo \
  -I"$ROOT_DIR/rtl" \
  "$ROOT_DIR/rtl/tiny_cache.sv" \
  "$ROOT_DIR/rtl/tiny_system_todo.sv" \
  "$ROOT_DIR/tb/tb_tiny_system.cpp" \
  -Mdir "$OBJ_DIR" \
  -o simv

"$OBJ_DIR/simv"
