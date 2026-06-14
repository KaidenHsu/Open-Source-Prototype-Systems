#!/usr/bin/env bash
set -euo pipefail
MCPAT_BIN=${MCPAT_BIN:-mcpat}
TEMPLATE=${MCPAT_TEMPLATE:-}
if [ -z "$TEMPLATE" ]; then
  for cand in \
    "${MCPAT_HOME:-/opt/mcpat}/ProcessorDescriptionFiles/ARM_A9_2GHz.xml" \
    "${MCPAT_HOME:-/opt/mcpat}/ARM_A9_2GHz.xml" \
    "${MCPAT_HOME:-/opt/mcpat}/ProcessorDescriptionFiles/Alpha21364.xml" \
    "${MCPAT_HOME:-/opt/mcpat}/Alpha21364.xml" \
    "${MCPAT_HOME:-/opt/mcpat}/ProcessorDescriptionFiles/Xeon.xml" \
    "${MCPAT_HOME:-/opt/mcpat}/Xeon.xml"; do
    if [ -f "$cand" ]; then TEMPLATE="$cand"; break; fi
  done
fi
if [ -z "$TEMPLATE" ] || [ ! -f "$TEMPLATE" ]; then
  echo "No McPAT template found. Set MCPAT_TEMPLATE=/path/to/example.xml" >&2
  exit 1
fi
mkdir -p results/_smoke
OUT=results/_smoke/mcpat_smoke.txt
LOG=results/_smoke/mcpat_smoke.log
echo "[SMOKE] template=$TEMPLATE"
timeout 60 "$MCPAT_BIN" -infile "$TEMPLATE" -print_level 0 > "$OUT" 2> "$LOG" || {
  status=$?
  echo "[FAIL] McPAT smoke test failed or timed out. status=$status" >&2
  echo "[INFO] See $LOG" >&2
  exit "$status"
}
echo "[OK] McPAT smoke test completed: $OUT"
head -40 "$OUT"
