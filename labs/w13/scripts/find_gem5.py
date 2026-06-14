#!/usr/bin/env python3
from pathlib import Path
import shutil

candidates = [
    shutil.which('gem5.opt'),
    '/opt/gem5/build/RISCV/gem5.opt',
    '/gem5/build/RISCV/gem5.opt',
]
for c in candidates:
    if c and Path(c).exists():
        print(c)
        raise SystemExit(0)
raise SystemExit('gem5.opt not found')
