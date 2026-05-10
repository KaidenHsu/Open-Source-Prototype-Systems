#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[1] / "traces"
root.mkdir(exist_ok=True)

(root / "coherence_directed.trace").write_text("""# op core addr data
R 0 20 00000000
R 1 20 00000000
W 0 20 CAFE0001
R 1 20 00000000
W 1 20 BEEF0002
R 0 20 00000000
R 0 20 00000000
""")
(root / "address_alias.trace").write_text("""# Same index, different tag
R 0 20 00000000
R 0 30 00000000
R 0 20 00000000
""")
(root / "simultaneous_race.trace").write_text("""# Simultaneous read/write trigger
R 0 24 00000000
R 1 24 00000000
D 0 00 00000000
R 0 24 00000000
""")
# Exercise C: student test extension
(root / "raw.trace").write_text("""# op core addr data
R 0 10 00000000
R 0 20 00000000
""")
# my trace
(root / "raw.trace").write_text("""# op core addr data
R 0 18 00000000
R 1 18 00000000
W 0 20 CAFE0001
R 1 20 00000000
W 1 22 BEEF0002
R 0 22 BEEF0002
R 0 22 00000000
""")

print(f"Wrote traces to {root}")
