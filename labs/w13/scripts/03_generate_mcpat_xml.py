#!/usr/bin/env python3
"""Template-based gem5 to McPAT XML helper for a teaching exercise.

This script intentionally stays conservative: it copies an example McPAT XML file and
patches common parameter/stat fields if matching names are present. This keeps the
exercise robust across McPAT versions while still forcing students to reason about
which assumptions and counters drive the result.
"""
from __future__ import annotations
import argparse
import os
import re
import shutil
from pathlib import Path
from lxml import etree

SIZE_RE = re.compile(r'^(\d+(?:\.\d+)?)([kKmMgG]?[bB])?$')

def parse_stats(path: Path) -> dict[str, float]:
    stats = {}
    if not path.exists():
        raise FileNotFoundError(path)
    for line in path.read_text(errors='ignore').splitlines():
        line = line.strip()
        if not line or line.startswith('#') or line.startswith('----------'):
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        key, val = parts[0], parts[1]
        try:
            stats[key] = float(val)
        except ValueError:
            continue
    return stats

def parse_env(path: Path) -> dict[str, str]:
    env = {}
    if path.exists():
        for line in path.read_text(errors='ignore').splitlines():
            if '=' in line:
                k, v = line.split('=', 1)
                env[k.strip()] = v.strip()
    return env

def find_template() -> Path:
    explicit = os.environ.get('MCPAT_TEMPLATE')
    if explicit and Path(explicit).exists():
        return Path(explicit)
    roots = []
    home = os.environ.get('MCPAT_HOME')
    if home:
        roots.append(Path(home))
    roots.extend([Path('/opt/mcpat'), Path('/mcpat')])
    # Prefer small example templates for classroom use. Xeon.xml can be slow/noisy with print_level>1.
    names = ['ARM_A9_2GHz.xml', 'Alpha21364.xml', 'Niagara.xml', 'Xeon.xml']
    for root in roots:
        for name in names:
            hits = list(root.rglob(name)) if root.exists() else []
            if hits:
                return hits[0]
        if root.exists():
            hits = list(root.rglob('*.xml'))
            if hits:
                return hits[0]
    raise FileNotFoundError('No McPAT XML template found. Set MCPAT_TEMPLATE=/path/to/example.xml')

def get_first(stats: dict[str, float], patterns: list[str], default: float) -> float:
    for pat in patterns:
        rgx = re.compile(pat)
        for k, v in stats.items():
            if rgx.search(k):
                return v
    return default

def size_to_bytes(s: str, default: int) -> int:
    m = SIZE_RE.match(s or '')
    if not m:
        return default
    n = float(m.group(1)); unit = (m.group(2) or 'B').lower()
    mult = 1
    if unit.startswith('kb'): mult = 1024
    elif unit.startswith('mb'): mult = 1024**2
    elif unit.startswith('gb'): mult = 1024**3
    return int(n * mult)

def clock_to_mhz(s: str, default: float = 1000.0) -> float:
    s = (s or '').strip().lower()
    m = re.match(r'([0-9.]+)\s*([mgk]?hz)', s)
    if not m:
        return default
    v = float(m.group(1)); u = m.group(2)
    if u == 'ghz': return v * 1000.0
    if u == 'mhz': return v
    if u == 'khz': return v / 1000.0
    return default

def patch_attrs(root, candidates: list[str], value) -> int:
    count = 0
    lc = [c.lower() for c in candidates]
    for elem in root.iter():
        name = elem.get('name')
        if not name:
            continue
        n = name.lower()
        if any(c == n or c in n for c in lc):
            elem.set('value', str(value))
            count += 1
    return count

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--stats', required=True)
    ap.add_argument('--run-env', required=True)
    ap.add_argument('--out', required=True)
    args = ap.parse_args()

    stats_path = Path(args.stats)
    env_path = Path(args.run_env)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)

    stats = parse_stats(stats_path)
    env = parse_env(env_path)
    template = find_template()

    parser = etree.XMLParser(remove_blank_text=False, recover=True)
    tree = etree.parse(str(template), parser)
    root = tree.getroot()

    sim_seconds = get_first(stats, [r'^simSeconds$'], 0.0)
    sim_ticks = get_first(stats, [r'^simTicks$'], 0.0)
    sim_freq = get_first(stats, [r'^simFreq$'], 1e12)
    if sim_seconds <= 0 and sim_ticks > 0:
        sim_seconds = sim_ticks / sim_freq
    cycles = get_first(stats, [r'numCycles$', r'cpu\.numCycles$'], max(1.0, sim_seconds * clock_to_mhz(env.get('CPU_CLOCK', '1GHz')) * 1e6))
    insts = get_first(stats, [r'committedInsts$', r'numInsts$', r'simInsts$'], 1.0)
    dcache_reads = get_first(stats, [r'dcache.*overallAccesses::total$', r'dcache.*demandAccesses::total$', r'dcache.*ReadReq_accesses'], 0.0)
    dcache_misses = get_first(stats, [r'dcache.*overallMisses::total$', r'dcache.*demandMisses::total$', r'dcache.*ReadReq_misses'], 0.0)
    icache_reads = get_first(stats, [r'icache.*overallAccesses::total$', r'icache.*demandAccesses::total$'], insts)
    l2_reads = get_first(stats, [r'l2.*overallAccesses::total$', r'l2cache.*overallAccesses::total$'], dcache_misses)

    # Common McPAT names vary across examples; these broad matches patch useful fields when present.
    patched = {}
    def do(names, value):
        patched['/'.join(names)] = patch_attrs(root, names, value)

    do(['clock_rate'], int(clock_to_mhz(env.get('CPU_CLOCK', '1GHz'))))
    do(['total_cycles', 'cycles'], int(cycles))
    do(['instructions', 'committed_instructions'], int(insts))
    do(['int_instructions'], int(insts * 0.70))
    do(['fp_instructions'], int(insts * 0.02))
    do(['branch_instructions'], int(insts * 0.12))
    do(['load_instructions'], int(insts * 0.25))
    do(['store_instructions'], int(insts * 0.10))
    do(['read_accesses'], int(dcache_reads))
    do(['write_accesses'], int(dcache_reads * 0.25))
    do(['read_misses'], int(dcache_misses))
    do(['write_misses'], int(dcache_misses * 0.20))
    do(['total_accesses'], int(max(dcache_reads, icache_reads)))
    do(['icache_config'], size_to_bytes(env.get('L1I_SIZE', '32kB'), 32768))
    do(['dcache_config'], size_to_bytes(env.get('L1D_SIZE', '32kB'), 32768))
    do(['l2_config'], size_to_bytes(env.get('L2_SIZE', '256kB'), 262144))

    tree.write(str(out), pretty_print=True, xml_declaration=True, encoding='UTF-8')

    report = out.with_suffix('.patch_report.txt')
    with report.open('w') as f:
        f.write(f'template={template}\n')
        f.write(f'sim_seconds={sim_seconds}\n')
        f.write(f'cycles={cycles}\n')
        f.write(f'instructions={insts}\n')
        f.write(f'dcache_reads={dcache_reads}\n')
        f.write(f'dcache_misses={dcache_misses}\n')
        f.write(f'l2_reads={l2_reads}\n')
        for k, v in sorted(patched.items()):
            f.write(f'patched {k}: {v}\n')

    print(out)

if __name__ == '__main__':
    main()
