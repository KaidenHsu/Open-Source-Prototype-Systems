#!/usr/bin/env python3
import sys, re
path = sys.argv[1]
keys = ["simInsts", "numCycles", "hostSeconds", "simSeconds", "system.cpu.ipc", "system.cpu.cpi"]
print("Selected gem5 statistics:")
with open(path, "r", errors="ignore") as f:
    lines = f.readlines()
for key in keys:
    for line in lines:
        if line.startswith(key + " "):
            print(line.strip())
            break
