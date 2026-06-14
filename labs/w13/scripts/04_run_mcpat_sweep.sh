#!/usr/bin/env bash
set -euo pipefail

# McPAT can appear to hang because it prints only after finishing, especially with
# large example XMLs and high print levels. For the 1-hour exercise, keep output
# compact and force a timeout so students do not get stuck forever.
MCPAT_BIN=${MCPAT_BIN:-mcpat}
MCPAT_PRINT_LEVEL=${MCPAT_PRINT_LEVEL:-1}
MCPAT_TIMEOUT=${MCPAT_TIMEOUT:-120}

# Prefer a smaller McPAT template if it exists. Students/TAs can override with:
#   export MCPAT_TEMPLATE=/path/to/your/template.xml
if [ -z "${MCPAT_TEMPLATE:-}" ]; then
  for cand in \
    "${MCPAT_HOME:-/opt/mcpat}/ProcessorDescriptionFiles/ARM_A9_2GHz.xml" \
    "${MCPAT_HOME:-/opt/mcpat}/ARM_A9_2GHz.xml" \
    "${MCPAT_HOME:-/opt/mcpat}/ProcessorDescriptionFiles/Alpha21364.xml" \
    "${MCPAT_HOME:-/opt/mcpat}/Alpha21364.xml"; do
    if [ -f "$cand" ]; then
      export MCPAT_TEMPLATE="$cand"
      break
    fi
  done
fi

echo "[INFO] MCPAT_BIN=$MCPAT_BIN"
echo "[INFO] MCPAT_PRINT_LEVEL=$MCPAT_PRINT_LEVEL"
echo "[INFO] MCPAT_TIMEOUT=${MCPAT_TIMEOUT}s"
echo "[INFO] MCPAT_TEMPLATE=${MCPAT_TEMPLATE:-auto}"

for cfgdir in results/*; do
  [ -d "$cfgdir" ] || continue
  cfg=$(basename "$cfgdir")
  stats="$cfgdir/gem5/stats.txt"
  envfile="$cfgdir/run_config.env"
  xml="$cfgdir/mcpat.xml"
  report="$cfgdir/mcpat_report.txt"
  log="$cfgdir/mcpat_run.log"

  if [ ! -f "$stats" ]; then
    echo "[SKIP] $cfg: missing $stats"
    continue
  fi

  echo "[XML] $cfg"
  python3 scripts/03_generate_mcpat_xml.py --stats "$stats" --run-env "$envfile" --out "$xml" | tee "$log"

  echo "[MCPAT] $cfg  (timeout=${MCPAT_TIMEOUT}s, print_level=${MCPAT_PRINT_LEVEL})"
  set +e
  timeout "$MCPAT_TIMEOUT" "$MCPAT_BIN" -infile "$xml" -print_level "$MCPAT_PRINT_LEVEL" > "$report" 2>> "$log"
  status=$?
  set -e

  if [ "$status" -eq 124 ]; then
    echo "[ERROR] McPAT timed out for $cfg after ${MCPAT_TIMEOUT}s" | tee -a "$log"
    echo "[HINT] Try: MCPAT_PRINT_LEVEL=0 MCPAT_TIMEOUT=300 bash scripts/04_run_mcpat_sweep.sh" | tee -a "$log"
    echo "[HINT] Also inspect: $xml and $xml.patch_report.txt" | tee -a "$log"
    exit 124
  elif [ "$status" -ne 0 ]; then
    echo "[ERROR] McPAT failed for $cfg with status $status" | tee -a "$log"
    echo "[HINT] Check $log for details." | tee -a "$log"
    exit "$status"
  fi

  if [ ! -s "$report" ]; then
    echo "[ERROR] McPAT produced an empty report for $cfg" | tee -a "$log"
    exit 1
  fi

  echo "[OK] $report"
done
