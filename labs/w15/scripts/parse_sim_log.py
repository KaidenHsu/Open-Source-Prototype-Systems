#!/usr/bin/env python3
import csv
import re
import sys
from pathlib import Path

if len(sys.argv) != 3:
    print("usage: parse_sim_log.py <sim.log> <out.csv>", file=sys.stderr)
    sys.exit(2)

log_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])
metrics = {}
for line in log_path.read_text().splitlines():
    m = re.match(r"METRIC\s+([^=\s]+)=(\d+)", line.strip())
    if m:
        metrics[m.group(1)] = int(m.group(2))

if not metrics:
    print(f"No METRIC lines found in {log_path}", file=sys.stderr)
    sys.exit(1)

out_path.parent.mkdir(parents=True, exist_ok=True)
keys = ["policy", "cycles", "issued0", "issued1", "completed0", "completed1", "grants0", "grants1", "max_wait0", "max_wait1"]
with out_path.open("w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=keys)
    writer.writeheader()
    writer.writerow({k: metrics.get(k, "") for k in keys})
print(f"Wrote {out_path}")
