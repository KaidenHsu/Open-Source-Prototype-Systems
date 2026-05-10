# gem5 profiling requirement — histogram workload

## Goal
Use gem5 to profile a branch-heavy baseline histogram and an optimized histogram. Identify the dominant bottleneck and connect it to Project 2 design choices in pipelining and caching.

## Workloads
- `histogram_baseline.c`
  - branch-heavy bucket selection
  - repeated updates to a small global bin array
- `histogram_optimized.c`
  - branchless bucket computation using shifts
  - local-bin accumulation before final writeback

## What students should compare
- `simInsts`
- `numCycles`
- `ipc` or `cpi`
- cache statistics if available
- qualitative branch / control behavior if relevant to the chosen CPU model

## Questions to answer
1. Is the baseline limited more by control flow, memory traffic, or another factor?
2. Does the optimized histogram reduce cycles primarily by lowering branch cost, improving locality in the bin array, or both?
3. Which parts of your Project 2 design address the bottleneck you observed?
4. How would the benefit change with a deeper pipeline or a smaller cache?

## Suggested commands
```bash
riscv64-linux-gnu-gcc -O2 -static -o histogram_baseline.riscv histogram_baseline.c
riscv64-linux-gnu-gcc -O2 -static -o histogram_optimized.riscv histogram_optimized.c

/opt/gem5/build/RISCV/gem5.opt -d m5out_hist_base configs/example/se.py --cmd=./histogram_baseline.riscv
/opt/gem5/build/RISCV/gem5.opt -d m5out_hist_opt  configs/example/se.py --cmd=./histogram_optimized.riscv

grep -E "simInsts|numCycles|ipc|cpi" m5out_hist_base/stats.txt
grep -E "simInsts|numCycles|ipc|cpi" m5out_hist_opt/stats.txt
```
