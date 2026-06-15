# Week 13 Lab: McPAT Processor Energy Analysis: Cache Size and Clock Frequency

## 1. Introduction

The exercise compares a baseline gem5 run against controlled variants and computes energy metrics using McPAT.

## 2. Workflow

```bash
$ docker pull amansinhaatnycu/osp:week13-power

$ docker run --rm -it \
  -v "$(pwd)":/work \
  -w /work \
  amansinhaatnycu/osp:week13-power \
  bash
```

- Build a small RISC-V workload.
- Run the workload in gem5 for three configurations:
   - `baseline`: timing CPU, 32 KB L1 I/D caches, 256 KB L2.
   - `l1d_big`: larger L1 data cache.
   - `freq_fast`: same cache hierarchy but different frequency assumption.
- Convert gem5 statistics into McPAT XML using a conservative template-based converter.
- Run McPAT.
- Compute runtime, average power, total energy, EPI, and EDP.

```bash
# repeat this for all 3 workloads
$ bash scripts/run_all_exercises.sh workloads/array_sum.c
# observe final summary in results/summary.csv or results/summary.md
```

- Interpret whether the energy change comes mainly from runtime, activity, or leakage.

## 3. McPAT Runtime Guard

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
- Always compare runs with the same binary and input size.
- McPAT estimates should be interpreted as model-based trends, not post-layout power signoff.

## 4. Workloads and Configurations

- Workloads: `array_sum.c`, `branchy_loop.c`, `mini_matmul.c`
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
- Variant A (`freq_fast`) change: `--cpu-clock=1.2GHz `
- Variant B (`l1d_big`) change: `--l1d_size=64kB --l1d_assoc=4`

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

### 5.3 ``mini_matmul.c`

| config | sim_seconds | cycles | instructions | dcache_accesses | dcache_misses | dynamic_w | leakage_w | avg_power_w | energy_j | epi_j_per_inst | edp_j_s |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| baseline | 0.019411 | 1.94107e+07 | 5.53261e+06 | 2.03484e+06 | 1463 | 0.0871658 | 0.133595 | 0.220761 | 0.00428519 | 7.74532e-10 | 8.31798e-05 |
| freq_fast | 0.016188 | 1.94329e+07 | 5.53261e+06 | 2.03484e+06 | 1463 | 0.0924749 | 0.133595 | 0.22607 | 0.00365962 | 6.61463e-10 | 5.92419e-05 |
| l1d_big | 0.01941 | 1.94103e+07 | 5.53261e+06 | 2.03484e+06 | 1435 | 0.0900758 | 0.15519 | 0.245266 | 0.00476061 | 8.60463e-10 | 9.24034e-05 |

### 5.4 Observations

| Aspect | Observation |
| --- | --- |
| Runtime effect | `freq_fast` reduces runtime while `l1d_big` has little impact |
| Activity / dynamic-power effect | both `freq_fast` and `l1d_big` increase `dynamic_w` |
| Leakage effect | `l1d_big` > `freq_fast` > `baseline` |
| Cache or memory effect | significantly fewer `dcache_misses` for `array_sum.c`, but not for `branchy_loop.c` and `mini_matmul.c` |

## 6. Conclusion

- McPAT estimates are produced from example templates and heuristic mappings of simulator counters to activity factors. They do not include post‑layout parasitics, process‑corner tuning, physical implementation details, or on‑chip/off‑chip measurement calibration. As a result, McPAT outputs are useful for relative trends and architectural sensitivity analysis but not for absolute power signoff.
- Always compare runs using the same binary and input size. Treat McPAT outputs as comparative guidance; if absolute accuracy is required, calibrate templates/patches against measured data or more detailed physical models.
