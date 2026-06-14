#!/usr/bin/env python3
import csv
import sys
from collections import defaultdict
from pathlib import Path

try:
    import matplotlib.pyplot as plt
except Exception:
    plt = None

if len(sys.argv) < 2:
    print("Usage: analyze_latency.py <csv> [<csv> ...]")
    sys.exit(2)

all_rows = []
for p in sys.argv[1:]:
    path = Path(p)
    if not path.exists():
        print(f"Skipping missing file: {path}")
        continue
    rows = list(csv.DictReader(path.open()))
    all_rows.extend(rows)

if not all_rows:
    print("No latency rows available.")
    sys.exit(2)

by_design = defaultdict(list)
for r in all_rows:
    by_design[r["design"]].append(r)

for design, rows in by_design.items():
    latencies = [int(r["latency_cycles"]) for r in rows]
    print(f"\nDesign: {design}")
    print(f"  cases: {len(rows)}")
    print(f"  min latency: {min(latencies)} cycles")
    print(f"  max latency: {max(latencies)} cycles")
    print(f"  unique latencies: {sorted(set(latencies))}")
    print("  selected cases:")
    for r in rows[:8]:
        print(f"    {r['case']:<16} latency={r['latency_cycles']:<3} match={r['match']} debug_count={r['debug_count']}")

if plt:
    Path("build").mkdir(exist_ok=True)
    for design, rows in by_design.items():
        labels = [r["case"] for r in rows if not r["case"].startswith("random_")]
        vals = [int(r["latency_cycles"]) for r in rows if not r["case"].startswith("random_")]
        plt.figure(figsize=(8, 4))
        plt.bar(labels, vals)
        plt.ylabel("Latency cycles")
        plt.xticks(rotation=30, ha="right")
        plt.title(f"Latency by input class: {design}")
        plt.tight_layout()
        out = Path("build") / f"latency_{design}.png"
        plt.savefig(out, dpi=160)
        print(f"  wrote {out}")
else:
    print("\nmatplotlib not available; printed text summary only.")
