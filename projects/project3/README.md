# Project 3. Two-Core MSI-Coherent Parallel Histogram

This package does not use RV32I `.hex` instruction programs. Instead, each core is represented by a small deterministic workload driver that loads an address trace and issues histogram-style read-modify-write memory requests to the private cache.

## 1. Quick Start

```bash
$ ./run.sh
```

## 2. Design

- MSI
- write-back
- blocking
- direct-mapped, 4 words/line
- requires a final flush before the final memory state inspection

<p align="center"><img src="images/top.jpg" alt="top" width=960 /></p>
<p align="center"><img src="images/FSM_cache_controller.jpg" alt="cache controller" width=720 /></p>
<p align="center">
    <img src="./images/core_state_diagram.png" alt="core" align="middle" />
    <img src="./images/bus_state_diagram.png" alt="bus" align="middle" />
</p>
<p align="center"> <img src="./images/FSM_MSI_core.jpg" alt="core" align="middle" width=720 /> </p>
<p align="center"> <img src="./images/FSM_MSI_bus.jpg" alt="bus" align="middle" width=720 /> </p>


## 3. Workloads

### 3.1 Trace format

Each trace line is one hexadecimal word address. For every address, the driver performs:

```text
load bin[address]
store bin[address] + 1
```

The address is a word address, not a byte address. With four-word cache lines, addresses `00`, `01`, `02`, and `03` map to the same cache line, while address `04` maps to the next line.

### 3.2 Workload Variants

| Target | Trace files | Purpose |
|---|---|---|
| `shared_bins` | `workloads/shared_bins_core0.trace`, `workloads/shared_bins_core1.trace` | Both cores update compact global bins. This demonstrates coherence traffic and also shows that coherence is not atomicity. |
| `false_sharing` | `workloads/false_sharing_core0.trace`, `workloads/false_sharing_core1.trace` | The cores update different words in the same cache line. This exposes false sharing and ownership ping-pong. |
| `padded_bins` | `workloads/padded_bins_core0.trace`, `workloads/padded_bins_core1.trace` | The cores update words in different cache lines. This should reduce unnecessary invalidations. |
| `local_bins` | `workloads/local_bins_core0.trace`, `workloads/local_bins_core1.trace` | Each core uses private local histogram bins. This models local accumulation before a merge step. |


| core0 / core1 | `shared_bins` | `false_sharing` | `padded_bins` | `local_bins` |
|---|---|---|---|---|
| request 1 | 00 / 00 | 00 / 01 | 00 / 04 | 10 / 20 |
| request 2 | 01 / 01 | 00 / 01 | 00 / 04 | 11 / 21 |
| request 3 | 02 / 02 | 00 / 01 | 00 / 04 | 12 / 22 |
| request 4 | 03 / 03 | 00 / 01 | 00 / 04 | 13 / 23 |
| request 5 | 00 / 00 | 00 / 01 | 00 / 04 | 10 / 20 |
| request 6 | 01 / 01 | 00 / 01 | 00 / 04 | 11 / 21 |
| request 7 | 02 / 02 | 00 / 01 | 00 / 04 | 12 / 22 |
| request 8 | 03 / 03 | 00 / 01 | 00 / 04 | 13 / 23 |
| request 9 | 00 / 00 | 00 / 01 | 00 / 04 | 10 / 20 |
| request 10 | 01 / 01 | 00 / 01 | 00 / 04 | 11 / 21 |
| request 11 | 02 / 02 | 00 / 01 | 00 / 04 | 12 / 22 |
| request 12 | 03 / 03 | 00 / 01 | 00 / 04 | 13 / 23 |
| request 13 | 00 / 00 | 00 / 01 | 00 / 04 | 10 / 20 |
| request 14 | 01 / 01 | 00 / 01 | 00 / 04 | 11 / 21 |
| request 15 | 02 / 02 | 00 / 01 | 00 / 04 | 12 / 22 |
| request 16 | 03 / 03 | 00 / 01 | 00 / 04 | 13 / 23 |

## 5. Results

| **metrics\\workload** | **shared_bins** | **false_sharing** | **padded_bins** | **local_bins** |
|---|---:|---:|---:|---:|
| **cycles** | 88 | 88 | 52 | 52 |
| **hits** | 56 | 56 | 62 | 62 |
| **misses** | 8 | 8 | 2 | 2 |
| **BusRd** | 8 | 8 | 2 | 2 |
| **BusRdX** | 13 | 13 | 2 | 2 |
| **invalidations** | 13 | 13 | 0 | 0 |
