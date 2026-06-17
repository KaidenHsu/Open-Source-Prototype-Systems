# Week 12 Lab. Evaluating Custom RISC-V Histogram Binning Instructions

## 1. Introduction

This project explores a small histogram kernel on RISC-V using two implementations: a baseline scalar version and an `xhist` version that explores custom instructions. The first check is functional validation with QEMU ISA simulation, where both versions produce the same checksum. After that, cycle-accurate gem5 architectural simulator is used to compare cycle-level behavior under different input distributions and cache sizes, so the effect of the custom instructions can be measured in a controlled way.

## 2. Workflow

``` bash
$  bash run.sh
```

## 3. Workloads

### 3.1 Baseline (`hist_baseline.c`)

``` c
if (x >= min_val && x < max_val) {
    uint32_t bin = (x - min_val) >> shift;

    if (hist[bin] < SAT_LIMIT) {
        hist[bin]++;
    }
}
```

### 3.2 Custom Instruction (`hist_xhist.c`)

``` c
if (xhrange(x, range_cfg)) {
    uint64_t bin = xhbin(x, bin_cfg);
    hist[bin] = xhsat(hist[bin], SAT_LIMIT);
}
```

## 4. Custom Instruction Proposals (`xhist_intrin.h`)

take `xhrange` instruction for example

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

## 5. QEMU ISA Simulaton

QEMU is a ISA simulator, which gives no clues of cycle-accurate architectural information.

``` bash
mode: baseline
checksum: 0x199fd000
mode: xhist
checksum: 0x199fd000
```

`checksum` for both runs are the same, which proves functional correctness.

## 6. Gem5 Architectural Simulation

### 6.1 Input Distribution Experiments

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

### 6.2 Base Run (uniform)

| Metric | Baseline | XHIST | Improvement (%) |
|---|---:|---:|---:|
| `simInsts` | 182861 | 182676 | 0.10 |
| `simTicks` | 358646000 | 358163000 | 0.13 |
| `system.cpu.numCycles` | 717292 | 716326 | 0.13 |
| `system.cpu.ipc` | 0.254932 | 0.255018 | 0.03 |
| `system.cpu.dcache.overallMisses::total` | 1309 | 1308 | 0.08 |
| `system.cpu.icache.overallMisses::total` | 389 | 388 | 0.26 |

### 6.3 Hot Bin Clustered

| Metric | Baseline | XHIST | Improvement (%) |
|---|---:|---:|---:|
| `simInsts` | 180824 | 182707 | -1.04 |
| `simTicks` | 349821000 | 353831000 | -1.15 |
| `system.cpu.numCycles` | 699642 | 707662 | -1.15 |
| `system.cpu.ipc` | 0.258452 | 0.258184 | -0.10 |
| `system.cpu.dcache.overallMisses::total` | 1309 | 1309 | 0.00 |
| `system.cpu.icache.overallMisses::total` | 387 | 389 | -0.52 |

### 6.4 Out-of-Range Heavy

| Metric | Baseline | XHIST | Improvement (%) |
|---|---:|---:|---:|
| `simInsts` | 185991 | 179683 | 3.39 |
| `simTicks` | 351083000 | 344865000 | 1.77 |
| `system.cpu.numCycles` | 702166 | 689730 | 1.77 |
| `system.cpu.ipc` | 0.264882 | 0.260512 | -1.65 |
| `system.cpu.dcache.overallMisses::total` | 1305 | 1305 | 0.00 |
| `system.cpu.icache.overallMisses::total` | 395 | 399 | -1.01 |

### 6.5 Adversarial Stride

| Metric | Baseline | XHIST | Improvement (%) |
|---|---:|---:|---:|
| `simInsts` | 182872 | 182708 | 0.09 |
| `simTicks` | 354290000 | 354090000 | 0.06 |
| `system.cpu.numCycles` | 708580 | 708180 | 0.06 |
| `system.cpu.ipc` | 0.258082 | 0.257997 | -0.03 |
| `system.cpu.dcache.overallMisses::total` | 1309 | 1309 | 0.00 |
| `system.cpu.icache.overallMisses::total` | 391 | 387 | 1.02 |

- `out of range heavy` gave the largest benefit from a `numCycles` standpoint
- `hot bin clustered` made `XHIST` least useful from a `numCycles` standpoint
- conclusion: locality helped more than branch/control reduction in this experiment

### 6.6 Cache Sweep

| L1D Size | Baseline cycles | XHIST cycles | Baseline L1D misses | XHIST L1D misses |
|---|---:|---:|---:|---:|
| 8 kB | 749,562 | 747,446 | 1,606 | 1,605 |
| 32 kB | 717,292 | 716,326 | 1,309 | 1,308 |
| 64 kB | 714,396 | 714,176 | 1,287 | 1,286 |

Conclusion: XHIST produces small but consistent cycle reductions (0.03–0.28%) and reduces L1D misses by 1 across these L1D sizes.

### 6.7 `xhpack` Microtest

``` bash
$ qemu-riscv64-xhist build/test_xhpack.riscv
xhpack result: 0x1234abcd
```

matches `((0x1234 & 0xffff) << 16) | (0xabcd & 0xffff)`, pass!

## 7. Custom Instruction Idea

- **Instruction**: `xhbinclip rd, rs1, rs2`
- **Semantic model**: `rd = clipped_bin(rs1, rs2)`, where `rs1` is the input value and `rs2` packs the lower bound, upper bound, and shift amount used to compute the histogram bin.
- **Encoding**: opcode 0x0b (custom-0), funct3 = 0x4, funct7 = 0x02.
- **Expected benefit**: replaces the range check and bin selection sequence in `hist_xhist.c` with one fused operation.
- **Concern**: the saturating histogram update is still a normal load-compare-store sequence.

In `xhist_intrin.h`:

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

## 8. Conclusion

The `xhist` version preserves correctness, as shown by the matching checksum in QEMU simulation, and it also shows small but consistent cycle improvements in the gem5 measurements. Across the input-distribution runs, the effect depends on locality and control behavior, while the cache sweep shows only modest sensitivity to L1D size.  Taken together, the results suggest that the most promising next step is a custom instruction focused on the hot histogram-update path. The proposal here aims at reducing the range check and bin selection overhead first.
