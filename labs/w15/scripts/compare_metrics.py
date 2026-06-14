#!/usr/bin/env python3
import csv
import sys
from pathlib import Path

def load(path):
    with Path(path).open() as f:
        row = next(csv.DictReader(f))
    return {k: int(v) for k, v in row.items() if v != ""}

if len(sys.argv) < 3:
    print("usage: compare_metrics.py fixed.csv rr.csv [aging.csv]", file=sys.stderr)
    sys.exit(2)

rows = [(Path(p).stem.replace("_metrics", ""), load(p)) for p in sys.argv[1:]]
print("\nPolicy comparison")
print("policy,cycles,max_wait0,max_wait1,grants0,grants1")
for name, r in rows:
    print(f"{name},{r.get('cycles')},{r.get('max_wait0')},{r.get('max_wait1')},{r.get('grants0')},{r.get('grants1')}")

base = rows[0][1]
for name, r in rows[1:]:
    dw0 = base.get('max_wait0', 0) - r.get('max_wait0', 0)
    dw1 = base.get('max_wait1', 0) - r.get('max_wait1', 0)
    dc = r.get('cycles', 0) - base.get('cycles', 0)
    print(f"\n{name}: max_wait0 reduction={dw0}, max_wait1 reduction={dw1}, cycle_delta={dc}")
