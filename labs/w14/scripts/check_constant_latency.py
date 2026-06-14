#!/usr/bin/env python3
import csv
import sys
from pathlib import Path

if len(sys.argv) != 2:
    print("Usage: check_constant_latency.py <latency_csv>")
    sys.exit(2)

path = Path(sys.argv[1])
rows = list(csv.DictReader(path.open()))
if not rows:
    print(f"No rows found in {path}")
    sys.exit(2)

latencies = {int(r["latency_cycles"]) for r in rows}
debug_values = {int(r["debug_count"]) for r in rows}
match_rows = [r for r in rows if r["case"] == "exact_match"]

print(f"Checked {len(rows)} cases from {path}")
print(f"Observed latencies: {sorted(latencies)}")
print(f"Observed public debug_count values: {sorted(debug_values)}")

ok = True
if len(latencies) != 1:
    print("FAIL: Latency is not constant across candidate classes.")
    ok = False
if len(debug_values) != 1:
    print("FAIL: Public debug_count still varies across candidate classes.")
    ok = False
if not match_rows or match_rows[0]["match"] != "1":
    print("FAIL: Exact match did not produce match=1.")
    ok = False
for r in rows:
    if r["case"] != "exact_match" and r["match"] != "0":
        print(f"FAIL: {r['case']} should not match.")
        ok = False

if ok:
    print("PASS: Functional and basic constant-latency checks passed.")
    sys.exit(0)
else:
    sys.exit(1)
