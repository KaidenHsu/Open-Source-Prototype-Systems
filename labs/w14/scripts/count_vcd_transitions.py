#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    print("Usage: count_vcd_transitions.py <trace.vcd>")
    sys.exit(2)

path = Path(sys.argv[1])
if not path.exists():
    print(f"Missing VCD: {path}")
    sys.exit(2)

transitions = 0
for line in path.open(errors="ignore"):
    line = line.strip()
    if not line or line.startswith("$") or line.startswith("#"):
        continue
    if line[0] in "01xzbr":
        transitions += 1
print(f"{path}: approximate VCD value-change records = {transitions}")
