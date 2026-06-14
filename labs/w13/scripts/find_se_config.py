#!/usr/bin/env python3
from pathlib import Path
import os

candidates = [
    os.environ.get('GEM5_SE_CONFIG'),
    '/opt/gem5/configs/deprecated/example/se.py',
    '/opt/gem5/configs/example/se.py',
    '/gem5/configs/deprecated/example/se.py',
    '/gem5/configs/example/se.py',
]
for c in candidates:
    if c and Path(c).exists():
        print(c)
        raise SystemExit(0)
raise SystemExit('gem5 SE config not found. Set GEM5_SE_CONFIG=/path/to/se.py')
