#!/usr/bin/env python3
from __future__ import annotations
import argparse
import re
from pathlib import Path
import csv

POWER_PATTERNS = [
    ('runtime_dynamic_w', re.compile(r'Runtime Dynamic\s*=\s*([0-9.eE+-]+)\s*W')),
    ('subthreshold_leakage_w', re.compile(r'Subthreshold Leakage\s*=\s*([0-9.eE+-]+)\s*W')),
    ('gate_leakage_w', re.compile(r'Gate Leakage\s*=\s*([0-9.eE+-]+)\s*W')),
    ('total_leakage_w', re.compile(r'Total Leakage\s*=\s*([0-9.eE+-]+)\s*W')),
]

def parse_stats(path: Path) -> dict[str, float]:
    out = {}
    for line in path.read_text(errors='ignore').splitlines():
        parts = line.split()
        if len(parts) >= 2:
            try: out[parts[0]] = float(parts[1])
            except ValueError: pass
    return out

def first(stats: dict[str,float], regexes, default=0.0):
    for r in regexes:
        rgx = re.compile(r)
        for k,v in stats.items():
            if rgx.search(k): return v
    return default

def parse_power(path: Path) -> dict[str, float]:
    values = {k: 0.0 for k,_ in POWER_PATTERNS}
    if not path.exists():
        return values
    text = path.read_text(errors='ignore')
    for key, rgx in POWER_PATTERNS:
        vals = [float(m.group(1)) for m in rgx.finditer(text)]
        if vals:
            values[key] = vals[0]
    if values['total_leakage_w'] <= 0:
        values['total_leakage_w'] = values['subthreshold_leakage_w'] + values['gate_leakage_w']
    return values

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('results_dir', nargs='?', default='results')
    args = ap.parse_args()
    root = Path(args.results_dir)
    rows = []
    for cfgdir in sorted(root.iterdir()):
        if not cfgdir.is_dir(): continue
        stats_path = cfgdir/'gem5'/'stats.txt'
        if not stats_path.exists(): continue
        stats = parse_stats(stats_path)
        pwr = parse_power(cfgdir/'mcpat_report.txt')
        sim_seconds = first(stats, [r'^simSeconds$'], 0.0)
        sim_ticks = first(stats, [r'^simTicks$'], 0.0)
        sim_freq = first(stats, [r'^simFreq$'], 1e12)
        if sim_seconds <= 0 and sim_ticks > 0: sim_seconds = sim_ticks / sim_freq
        insts = first(stats, [r'committedInsts$', r'numInsts$', r'^simInsts$'], 1.0)
        cycles = first(stats, [r'numCycles$', r'cpu\.numCycles$'], 0.0)
        misses = first(stats, [r'dcache.*overallMisses::total$', r'dcache.*demandMisses::total$', r'dcache.*ReadReq_misses'], 0.0)
        acc = first(stats, [r'dcache.*overallAccesses::total$', r'dcache.*demandAccesses::total$'], 0.0)
        dyn = pwr['runtime_dynamic_w']
        leak = pwr['total_leakage_w']
        avg = dyn + leak
        energy = avg * sim_seconds
        epi = energy / insts if insts else 0.0
        edp = energy * sim_seconds
        rows.append({
            'config': cfgdir.name,
            'sim_seconds': sim_seconds,
            'cycles': cycles,
            'instructions': insts,
            'dcache_accesses': acc,
            'dcache_misses': misses,
            'dynamic_w': dyn,
            'leakage_w': leak,
            'avg_power_w': avg,
            'energy_j': energy,
            'epi_j_per_inst': epi,
            'edp_j_s': edp,
        })
    out_csv = root/'summary.csv'
    with out_csv.open('w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()) if rows else ['config'])
        w.writeheader(); w.writerows(rows)
    out_md = root/'summary.md'
    with out_md.open('w') as f:
        f.write('# Week 13 Energy Summary\n\n')
        if not rows:
            f.write('No completed runs found.\n')
        else:
            headers = list(rows[0].keys())
            f.write('| ' + ' | '.join(headers) + ' |\n')
            f.write('| ' + ' | '.join(['---']*len(headers)) + ' |\n')
            for r in rows:
                vals = []
                for h in headers:
                    v = r[h]
                    vals.append(f'{v:.6g}' if isinstance(v, float) else str(v))
                f.write('| ' + ' | '.join(vals) + ' |\n')
    print(f'Wrote {out_csv}')
    print(f'Wrote {out_md}')

if __name__ == '__main__':
    main()
