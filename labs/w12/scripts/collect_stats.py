#!/usr/bin/env python3

import sys
from pathlib import Path

KEYS = [
    "simInsts",
    "simTicks",
    "system.cpu.numCycles",
    "system.cpu.ipc",
    "system.cpu.dcache.overallMisses::total",
    "system.cpu.icache.overallMisses::total",
]

def parse_stats(path):
    data = {}
    for line in Path(path).read_text().splitlines():
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) >= 2:
            data[parts[0]] = parts[1]
    return data

def main():
    if len(sys.argv) != 3:
        print("usage: collect_stats.py baseline_stats.txt xhist_stats.txt")
        sys.exit(1)

    base = parse_stats(sys.argv[1])
    xhist = parse_stats(sys.argv[2])

    print("| Metric | Baseline | XHIST |")
    print("|---|---:|---:|")

    for key in KEYS:
        print(f"| `{key}` | {base.get(key, 'NA')} | {xhist.get(key, 'NA')} |")

if __name__ == "__main__":
    main()
