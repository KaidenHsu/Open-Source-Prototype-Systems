# Week 12 Lab. Histogram Binning: Evaluating Custom Instructions across Input Distributions and Cache Sizes

## 1. Introduction

This lab explores a control-heavy, memory-sensitive histogram binning kernel on two implementations: a baseline and an XHIST version that explores custom RISC-V instructions. Compiler intrinsics functions for the RISC-V custom instruction ideas are implemented in a C header file. The first check is functional validation with QEMU ISA simulation, where both versions produce the same checksum. After that, cycle-accurate gem5 architectural simulator is used to compare cycle-level behavior under different input distributions and cache sizes. Then, a microtest is invoked on one custom instruction idea using QEMU to test the custom instruction correctness. Finally, after learning how custom instruction ideas can be added, students have to propose a new custom instruction idea and add it to the compiler intrinsics header file, the processor datapath implementation or custom instruction gem5 simulation is not required in this lab.

## 2. Workflow

``` bash
$  bash run.sh
```

## 3. Workloads

### 3.1 Baseline Histogram (`hist_baseline.c`)

``` c
if (x >= min_val && x < max_val) {
    uint32_t bin = (x - min_val) >> shift;

    if (hist[bin] < SAT_LIMIT) {
        hist[bin]++;
    }
}
```

- The workload counts how many input values fall into each histogram bin. Each input element passes through a range check, a bin computation, and a saturating counter update.
- It is a control-heavy and memory-sensitive kernel with irregular updates.

### 3.2 Custom Instruction Ideas (`hist_xhist.c`)

``` c
if (xhrange(x, range_cfg)) {
    uint64_t bin = xhbin(x, bin_cfg);
    hist[bin] = xhsat(hist[bin], SAT_LIMIT);
}
```

## 4. Compiler Intrinsics (`xhist_intrin.h`)

Intrinsics are exposed by the compiler as functions that are not part of any library. For example, **assembly intrinsics** are treated by the compiler as precisely the machine instruction they represent.

Take `xhrange` instruction for example:

``` c
static inline uint64_t xhrange(uint64_t value, uint64_t cfg)
{
    uint64_t rd;
    asm volatile (".insn r 0x0b, 0x0, 0x01, %0, %1, %2"
                  : "=r"(rd)
                  : "r"(value), "r"(cfg));
    return rd;
}
```

All instructions are R-type instructions and use the RISC-V custom-0 (0x0b) opcode space.

| Instruction | Operation | What it replaces | Interpretation |
| --- | --- | --- | --- |
| `xhrange` | Return 1 if value is in configured range | Two comparisons and a Boolean conjunction | Control-flow reduction |
| `xhbin` | Compute bin index from value and packed config | Subtract and variable shift | Datapath fusion |
| `xhsat` | Increment value unless saturation limit is reached | Compare, branch/select, add | Saturating arithmetic specialization |
| `xhpack` | Pack two 16-bit fields into one register | Shift, mask, and OR | Data-layout helper for compact metadata |

**Important lesson**: The `xhist` instructions reduce computation and control overhead, but the histogram update still touches memory. Therefore, the speedup depends on whether execution was compute/control limited or memory limited.

## 5. QEMU ISA Simulation

QEMU is an ISA simulator.  In user-mode emulation, QEMU can launch a program compiled for one CPU architecture on a host running another architecture.

``` bash
mode: baseline
checksum: 0x199fd000
mode: xhist
checksum: 0x199fd000
```

`checksum` for both runs match, which proves functional correctness, while giving no clues of cycle-accurate architectural information.

## 6. Input Distribution Experiments

All CPU models are in-order `TimingSimpleCPU`.

### 6.1 Workload

``` c
static void init_input(void)
{
    for (uint32_t i = 0; i < N; i++) {
#if defined(MODE_HOT_BIN_CLUSTERED)
        input[i] = ((i * 5 + 3) & 0x1f);
#elif defined(MODE_OUT_OF_RANGE_HEAVY)
        if ((i & 3) == 0) {
            input[i] = (i * 37 + 13) & 0x3ff;
        } else {
            input[i] = 1024 + ((i * 37 + 13) & 0x3ff);
        }
#elif defined(MODE_ADVERSARIAL_STRIDE)
        input[i] = (i * 16) & 0x3ff;
#else
        input[i] = (i * 37 + 13) & 0x3ff;
#endif
    }
}
```

### 6.2 Baseline (`hist_baseline.c`)

| Metric | uniform | hot bin clustered | out-of-range heavy | adversarial stride |
| --- | ---: | ---: | ---: | ---: |
| `simInsts` | 182,861 | 180,824 | 185,991 | 182,872 |
| `simTicks` | 358,646,000 | 349,821,000 | 351,083,000 | 354,290,000 |
| `numCycles` | 717,292 | 699,642 | 702,166 | 708,580 |
| `IPC` | 0.254932 | 0.258452 | 0.264882 | 0.258082 |
| `overall dcache misses` | 1,309 | 1,309 | 1,305 | 1,309 |
| `overall icache misses` | 389 | 387 | 395 | 391 |

### 6.3 XHIST (`hist_xhist.c`)

| Metric | uniform | hot bin clustered | out-of-range heavy | adversarial stride |
| --- | ---: | ---: | ---: | ---: |
| `simInsts` | 182,676 | 182,707 | 179,683 | 182,708 |
| `simTicks` | 358,163,000 | 353,831,000 | 344,865,000 | 354,090,000 |
| `numCycles` | 716,326 | 707,662 | 689,730 | 708,180 |
| `IPC` | 0.255018 | 0.258184 | 0.260512 | 0.257997 |
| `overall dcache misses` | 1,308 | 1,309 | 1,305 | 1,309 |
| `overall icache misses` | 388 | 389 | 399 | 387 |

### 6.4 Interpretation

- `out-of-range heavy` gave the largest improvement: `numCycles` −1.77%, `simInsts` −3.39%. 75% of inputs fall outside the valid range, so `xhrange` eliminates two comparisons and a branch for most iterations. The instruction reduction (3.39%) outpacing the cycle reduction (1.77%) caused `IPC` to drop by 1.65%, which reveals that the histogram update's load-compare-store latency remains a bottleneck even when it executes less often.
- `hot bin clustered` is the only distribution where XHIST regresses: `numCycles` +1.15% (slower), `simInsts` +1.04%. All inputs fall in a narrow 0–31 band, so `xhrange` returns 1 on virtually every iteration and provides no branch-skip savings. The custom instruction overhead, without any compensating elimination of in-range branches, makes XHIST slower.
- `uniform` and `adversarial stride` show marginal improvements (+0.135% and +0.056% `numCycles`). Both distributions produce inputs mostly in range and have identical dcache miss counts (1,309), so the memory update bottleneck dominates and `xhrange` rarely skips.
- **conclusion**: The primary driver of XHIST benefit is how often `xhrange` can skip the histogram update path. The dcache miss count is nearly unchanged across all four distributions, confirming that XHIST's impact is in the control/compute path, not memory traffic. This teaches that although lower `simInsts` is useful, memory behavior can still cap speedup.

## 7. Cache Sensitivity Sweep

All CPU models are in-order `TimingSimpleCPU`.

| L1D Size | Baseline cycles | XHIST cycles | Baseline L1D misses | XHIST L1D misses |
|---|---:|---:|---:|---:|
| 8kB | 749,562 | 747,446 | 1,606 | 1,605 |
| 32kB | 717,292 | 716,326 | 1,309 | 1,308 |
| 64kB | 714,396 | 714,176 | 1,287 | 1,286 |

Moving from 32kB to 64kB produces marginal benefit compared to from 8kB to 32kB, which implies that 32kB is the L1D cache size sweet spot.

## 8. `xhpack` Microtest

This microtest tests `xhpack` directly, which helps understand how a small data-layout helpers can be made a custom instruction.

In `test_xhpack.c`:

``` c
#include "xhist_intrin.h" 
 
int main(void) 
{ 
    uint64_t a = 0x1234; 
    uint64_t b = 0xabcd; 
    uint64_t r = xhpack(a, b); 
    printf("xhpack result: 0x%lx\n", r); 
    return 0; 
} 
```

``` bash
$ bash scripts/run_qemu_xhpack.sh
xhpack result: 0x1234abcd
```

This result matches `((0x1234 & 0xffff) << 16) | (0xabcd & 0xffff)`, pass!

## 9. Custom Instruction Idea

- **Instruction**: `xhbinclip rd, rs1, rs2`
- **Semantic model**: `rd = clipped_bin(rs1, rs2)`, where `rs1` is the input value and `rs2` packs the lower bound, upper bound, and shift amount used to compute the histogram bin.
- **Encoding**: opcode 0x0b (custom-0), funct3 = 0x4, funct7 = 0x02.
- **Expected benefit**: replaces the range check and bin selection sequence in `hist_xhist.c` with one fused operation.
- **Concern**: the saturating histogram update is still a normal load-compare-store sequence.

In the compiler intrinsics header file (`xhist_intrin.h`):

``` c
static inline uint64_t xhbinclip(uint64_t a, uint64_t b)
{
    uint64_t rd;
    asm volatile (".insn r 0x0b, 0x4, 0x02, %0, %1, %2"
                  : "=r"(rd)
                  : "r"(a), "r"(b));
    return rd;
}
```

## 10. Conclusion

Both implementations produce the same checksum under QEMU, confirming that the custom instruction encoding, QEMU translation hooks, and intrinsic wrappers are all functionally correct. This teaches that custom instructions are contracts: QEMU, gem5, compiler/assembly, and workload code must agree on encoding and semantics.

The gem5 results show that XHIST's impact is highly input-dependent, and the controlling variable is how often `xhrange` can skip the histogram update. `out-of-range heavy` (75% of inputs out-of-range) yields the largest improvement at −1.77% `numCycles` and −3.39% `simInsts`. `hot bin clustered` (all inputs in-range) is the only distribution where XHIST regresses, at +1.15% `numCycles` and +1.04% `simInsts`, because `xhrange` fires on every iteration without ever skipping and the instruction overhead is uncompensated. The dcache miss count is nearly unchanged across all four distributions (at most 1 miss difference), confirming that XHIST affects the control/compute path only, not memory traffic. The cache sweep reinforces this: as L1D grows from 8 kB to 64 kB, the XHIST cycle advantage narrows from 2,116 to 220 cycles (0.28% to 0.03%), and L1D miss counts differ by at most 1 at every cache size.

The persistent bottleneck across all runs is the histogram update's load-compare-store sequence. Even in the best case, the instruction reduction (3.39%) far exceeds the cycle reduction (1.77%), and IPC falls by 1.65%, because memory latency cannot be eliminated by control-flow reduction alone.

Going forward, custom instructions should be added only after profiling confirms that the target operation is compute- or control-bound, not memory-bound: if the bottleneck is load-store latency, fusing or eliminating scalar instructions leaves the critical path untouched and the overhead can regress performance. Any proposed instruction must be validated functionally in QEMU and evaluated architecturally in gem5 across representative input distributions before a speedup claim can be made, because a reduction in instruction count does not imply a proportional reduction in cycles when memory traffic dominates.
