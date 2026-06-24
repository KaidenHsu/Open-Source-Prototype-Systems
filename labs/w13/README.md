# Week 13 Lab: McPAT Energy Analysis: Cache Size and Frequency Sensitivity across Workloads

## 1. Introduction

In this lab, three workloads, `array_sum`, `branchy_loop`, and `mini_matmul` are compiled and run through gem5 under a baseline configuration and two controlled variants — one increasing L1 data cache size (`Variant A`) and one increasing clock frequency (`Variant B`). The resulting simulation stats are fed into McPAT to estimate dynamic power, leakage power, total energy, energy per instruction (EPI), and energy-delay product (EDP). By comparing these metrics across workloads and configurations, this lab demonstrates how memory access patterns and branch behavior interact with microarchitectural knobs, and why the same hardware change can have very different energy implications depending on the workload.

## 2. Workflow

```bash
# repeat this for all 3 workloads
$ bash scripts/run_all_exercises.sh workloads/array_sum.c
# observe final summary in results/summary.csv or results/summary.md
```

- Build a small RISC-V workload.
- Run the workload in gem5 under three configurations:
   - `baseline`: timing CPU, 32 KB L1 I/D caches, 256 KB L2.
   - `l1d_big`: larger L1 data cache.
   - `freq_fast`: same cache hierarchy but different frequency assumption.
- Convert gem5 statistics into McPAT XML using a conservative template-based converter.
- Run McPAT.
- Compute runtime, average power, total energy, EPI, and EDP.

- Interpret whether the energy change comes mainly from runtime, activity, or leakage.

## 3. McPAT

### 3.1 Guidance

- McPAT estimates are produced from example templates and heuristic mappings of simulator counters to activity factors. They do not include post‑layout parasitics, process‑corner tuning, physical implementation details, or on‑chip/off‑chip measurement calibration. As a result, McPAT outputs are useful for relative trends and architectural sensitivity analysis but not for absolute power signoff.
- Treat McPAT outputs as comparative guidance; if absolute accuracy is required, calibrate templates/patches against measured data or more detailed physical models.

### 3.2 McPAT Runtime Guard

This package uses compact McPAT output by default:

```bash
MCPAT_PRINT_LEVEL=1
MCPAT_TIMEOUT=120
```

If McPAT appears to run forever, it is usually using a large XML template or verbose print level. Try:

```bash
MCPAT_PRINT_LEVEL=0 MCPAT_TIMEOUT=300 bash scripts/04_run_mcpat_sweep.sh
```

The script prefers smaller McPAT templates such as `ARM_A9_2GHz.xml` before larger examples such as `Xeon.xml`. You can force a template with:

```bash
export MCPAT_TEMPLATE=/opt/mcpat/ProcessorDescriptionFiles/ARM_A9_2GHz.xml
```

- The XML converter is intentionally compact for teaching. It preserves the selected McPAT example template and patches common activity and configuration fields when matching names are found.

## 4. Workloads and Configurations

### 4.1 Workloads

### `array_sum.c`: Sequential Memory Access

``` c
static uint32_t a[N];

int main(void) {
    for (int i = 0; i < N; i++) {
        a[i] = (uint32_t)((i * 1103515245u + 12345u) & 0xffffu);
    }

    volatile uint64_t sum = 0;
    for (int r = 0; r < ITERS; r++) {
        for (int i = 0; i < N; i++) {
            sum += a[i];
        }
    }

    printf("array_sum: N=%d ITERS=%d sum=%llu\n", N, ITERS, (unsigned long long)sum);
    return (sum == 0) ? 1 : 0;
}
```

- Sequential, stride-1 reads make this maximally cache-friendly — a large enough L1D can hold the entire array and eliminate nearly all misses.
- Compute is trivial (one addition per element); runtime is dominated by memory bandwidth, not arithmetic.

### `branchy_loop.c`: Irregular Branching

``` c
static uint32_t x[N];

int main(void) {
    for (int i = 0; i < N; i++) {
        uint32_t v = (uint32_t)(i * 2654435761u);
        x[i] = v ^ (v >> 13);
    }

    volatile uint64_t acc = 0;
    for (int r = 0; r < ITERS; r++) {
        for (int i = 0; i < N; i++) {
            uint32_t v = x[i];
            if ((v & 7u) == 0u) {
                acc += v * 3u;
            } else if ((v & 3u) == 1u) {
                acc ^= (uint64_t)v << 1;
            } else {
                acc += v >> 2;
            }
        }
    }

    printf("branchy_loop: N=%d ITERS=%d acc=%llu\n", N, ITERS, (unsigned long long)acc);
    return (acc == 0) ? 1 : 0;
}
```

- Branch outcomes depend on hash-derived data values, making them unpredictable and stressing the branch predictor.
- Miss pressure comes primarily from branch stalls, not spatial locality.

### `mini_matmul.c`: Compute-Bound, Cache-Friendly Reuse

``` c
static int32_t A[N][N];
static int32_t B[N][N];
static int32_t C[N][N];

int main(void) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            A[i][j] = (i + j) & 15;
            B[i][j] = (i * 3 - j) & 15;
            C[i][j] = 0;
        }
    }

    for (int r = 0; r < ITERS; r++) {
        for (int i = 0; i < N; i++) {
            for (int k = 0; k < N; k++) {
                int32_t aik = A[i][k];
                for (int j = 0; j < N; j++) {
                    C[i][j] += aik * B[k][j];
                }
            }
        }
    }

    volatile int64_t checksum = 0;
    for (int i = 0; i < N; i++) {
        checksum += C[i][i];
    }
    printf("mini_matmul: N=%d ITERS=%d checksum=%lld\n", N, ITERS, (long long)checksum);
    return (checksum == 0) ? 1 : 0;
}
```

- Hoisting `A[i][k]` out of the innermost loop eliminates redundant loads; the inner loop then streams sequentially through a row of `B`, maximizing spatial locality.
- The i-k-j loop order keeps the working set small, making this workload compute-bound. This matrix summation is repeated `r` times.
- The checksum sums only the diagonal of `C`, acting as a lightweight correctness check rather than iterating the entire output matrix.

### 4.2 Configurations

- Baseline configuration:

``` bash
--cpu-type=TimingSimpleCPU 
--sys-clock=1GHz --cpu-clock=1GHz 
--mem-size=512MB
--caches --l2cache 
--l1i_size=32kB --l1d_size=32kB 
--l1i_assoc=2 --l1d_assoc=2 
--l2_size=256kB --l2_assoc=8 
```

- Variant A (`freq_fast`) modification: `--cpu-clock=1.2GHz`
- Variant B (`l1d_big`) modification: `--l1d_size=64kB --l1d_assoc=4`

## 5. Results

### 5.1 `array_sum.c`

| config | sim_seconds | cycles | instructions | dcache_accesses | dcache_misses | dynamic_w | leakage_w | avg_power_w | energy_j | epi_j_per_inst | edp_j_s |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| baseline | 0.023378 | 2.33782e+07 | 6.49035e+06 | 3.18663e+06 | 67660 | 0.088206 | 0.133595 | 0.221801 | 0.00518526 | 7.98919e-10 | 0.000121221 |
| freq_fast | 0.019496 | 2.34043e+07 | 6.49035e+06 | 3.18663e+06 | 67660 | 0.0934882 | 0.133595 | 0.227083 | 0.00442721 | 6.82123e-10 | 8.6313e-05 |
| l1d_big | 0.021817 | 2.18169e+07 | 6.49035e+06 | 3.18663e+06 | 2619 | 0.0965207 | 0.15519 | 0.251711 | 0.00549157 | 8.46114e-10 | 0.00011981 |

### 5.2 `branchy_loop.c`

| config | sim_seconds | cycles | instructions | dcache_accesses | dcache_misses | dynamic_w | leakage_w | avg_power_w | energy_j | epi_j_per_inst | edp_j_s |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| baseline | 0.045732 | 4.5732e+07 | 1.63047e+07 | 3.20317e+06 | 68663 | 0.0819978 | 0.133595 | 0.215593 | 0.00985949 | 6.04702e-10 | 0.000450894 |
| freq_fast | 0.038125 | 4.57678e+07 | 1.63047e+07 | 3.20317e+06 | 68663 | 0.0875649 | 0.133595 | 0.22116 | 0.00843172 | 5.17134e-10 | 0.000321459 |
| l1d_big | 0.045732 | 4.57316e+07 | 1.63047e+07 | 3.20317e+06 | 68638 | 0.0848442 | 0.15519 | 0.240034 | 0.0109772 | 6.73256e-10 | 0.000502011 |

### 5.3 `mini_matmul.c`

| config | sim_seconds | cycles | instructions | dcache_accesses | dcache_misses | dynamic_w | leakage_w | avg_power_w | energy_j | epi_j_per_inst | edp_j_s |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| baseline | 0.019411 | 1.94107e+07 | 5.53261e+06 | 2.03484e+06 | 1463 | 0.0871658 | 0.133595 | 0.220761 | 0.00428519 | 7.74532e-10 | 8.31798e-05 |
| freq_fast | 0.016188 | 1.94329e+07 | 5.53261e+06 | 2.03484e+06 | 1463 | 0.0924749 | 0.133595 | 0.22607 | 0.00365962 | 6.61463e-10 | 5.92419e-05 |
| l1d_big | 0.01941 | 1.94103e+07 | 5.53261e+06 | 2.03484e+06 | 1435 | 0.0900758 | 0.15519 | 0.245266 | 0.00476061 | 8.60463e-10 | 9.24034e-05 |

### 5.4 Observations

- **Runtime effect**: `freq_fast` reduces runtime while `l1d_big` has little impact
- **Activity / dynamic-power effect**: both `freq_fast` and `l1d_big` increase `dynamic_w`
- **Leakage effect**: `l1d_big` > `freq_fast` > `baseline`
- **Cache or memory effect**: significantly fewer `dcache_misses` for `array_sum.c` than for `branchy_loop.c` and `mini_matmul.c`

## 6. Conclusion

The results confirm that no single hardware change uniformly improves energy efficiency across all workloads. Increasing clock frequency (`freq_fast`) reduces runtime for all three workloads but raises dynamic power, with the net effect on total energy depending on how runtime-sensitive the workload is. Increasing L1D cache size (`l1d_big`) benefits only workloads whose working set fits in the larger cache — `array_sum` sees a dramatic reduction in misses while `branchy_loop` and `mini_matmul` see almost none. McPAT's leakage estimates also rise with cache size regardless of whether the extra capacity is used, which can make a larger cache a net loss when the miss-reduction benefit is small.

Going forward, when using gem5 and McPAT for energy analysis: Always compare runs using the same binary and input size, since any change in compiled code or problem scale invalidates direct energy comparisons. Treat McPAT outputs as relative trends rather than absolute figures, as the tool relies on template-based models without considering physical constraints. When a configuration change appears to improve one metric, check the others — a faster runtime that raises leakage-dominated total energy is not necessarily a win.
