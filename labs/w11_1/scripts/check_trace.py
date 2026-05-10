#!/usr/bin/env python3
"""Small golden-model checker for Week 11 trace files."""
from __future__ import annotations
import sys
from pathlib import Path

MEM_WORDS = 64

def init_mem():
    return {i: 0x10000000 + i for i in range(MEM_WORDS)}

def word(addr: int) -> int:
    return (addr & 0xFF) >> 2

def main(path: str) -> int:
    mem = init_mem()
    p = Path(path)
    if not p.exists():
        print(f"ERROR: missing trace {path}")
        return 1
    print(f"Golden trace check: {p}")
    for lineno, raw in enumerate(p.read_text().splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        fields = line.split()
        if len(fields) != 4:
            print(f"Line {lineno}: ignored malformed line: {line}")
            continue
        op, core_s, addr_s, data_s = fields
        core = int(core_s)
        addr = int(addr_s, 16)
        data = int(data_s, 16)
        if op == "R":
            print(f"  L{lineno:02d}: C{core} READ  0x{addr:02X} -> 0x{mem[word(addr)]:08X}")
        elif op == "W":
            mem[word(addr)] = data
            print(f"  L{lineno:02d}: C{core} WRITE 0x{addr:02X} <- 0x{data:08X}")
        elif op == "D":
            # Testbench maps D to C0 read + C1 write on 0x24.
            before = mem[word(0x24)]
            mem[word(0x24)] = 0xFACE1111
            print(f"  L{lineno:02d}: DUAL  C0 READ 0x24 -> 0x{before:08X}; C1 WRITE 0x24 <- 0xFACE1111")
        else:
            print(f"Line {lineno}: unknown op {op}")
            return 1
    return 0

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: check_trace.py <trace>")
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
