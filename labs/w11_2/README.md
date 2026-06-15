# Week11 Lab2. Producer-Consumer Multithreading Synchronization on a Dual-Core System

## 1. Introduction

This lab contains a lightweight producer-consumer workload for Gem5 SE simulation. The workload demonstrates thread synchronization and inter-thread communication on a simulated two-CPU system using POSIX threads (`<pthread.h>`) and GCC atomic operations, which is ideal for studying cache behavior, memory ordering, and multi-threaded performance on small core counts.

**Key characteristics:**

- **Two threads** (one producer, one consumer) in a single process
- **No host-file IPC**: avoids unsupported syscalls like `renameat2`
- **Shared-memory synchronization** via global mailboxes and atomic loads and stores
- **Release-acquire semantics** to ensure cache coherency across CPU cores
- **Runs in gem5 SE mode** syscall emulation for fast, repeatable simulation


## 2. Workflow

Run with default settings (2048 iterations):

```bash
$ bash run_producer_consumer.sh
```

1. Script locates gem5, se.py config, and RISC-V compiler
2. Compiles `workloads/producer_consumer.c` to RISC-V binary
3. Simulates the binary on a 2-core system with caches
4. Outputs results to `m5out/producer_consumer/`
5. Displays key statistics and workload output

```
CONSUMER role=consumer iterations=2048 observed_iters=2048 observed_sum=2098176 expected=2098176
PRODUCER role=producer iterations=2048 sum=2098176
PRODUCER_CONSUMER PASS
```

## 3. System Under Simulation

- **2 CPUs**: TimingSimpleCPU (in-order, realistic pipeline)
- **L1 caches**: 32 KB instruction cache, 32 KB data cache per CPU (typical)
- **L2 cache**: unified 256 KB cache (shared)
- **Memory**: 512 MB (enough for this workload)

<p align="center"><img src="m5out/producer_consumer/config.dot.svg" alt="config" /></p>

## 4. Workload

### 4.1 Producer Role (pthread)

- Computes the sum: $\sum_{i=1}^{N} i = \frac{N(N+1)}{2}$
- Writes result to `mailbox_sum` with **relaxed atomics** (no ordering)
- Calls `deterministic_delay()` every 64 iterations to simulate realistic work
- Issues a **release-store** to `mailbox_ready` to publish ready flag

``` C
// Publish payload before publishing the ready flag.
__atomic_store_n(&mailbox_sum, sum, __ATOMIC_RELAXED);
__atomic_store_n(&mailbox_iters, iterations, __ATOMIC_RELAXED);
__atomic_store_n(&mailbox_ready, 1, __ATOMIC_RELEASE);
```

### 4.2 Consumer Role (main thread)

- Spin-waits on `mailbox_ready` using **acquire-load** (enforces ordering)
- Once producer signals, reads `mailbox_sum` with relaxed atomics (safe because acquire ordered it)
- Compares observed sum against expected value $\frac{N(N+1)}{2}$
- Prints PASS if they match, FAIL otherwise

``` C
const int max_polls = 2000000;

int ready = 0;
for (int p = 0; p < max_polls; p++) {
    ready = __atomic_load_n(&mailbox_ready, __ATOMIC_ACQUIRE);
    if (ready) break;
    if ((p & 255) == 0) deterministic_delay(16);
}

if (!ready) {
    printf("PRODUCER_CONSUMER FAIL: consumer timeout waiting for ready flag\n");
    return 2;
}

uint64_t observed_sum = __atomic_load_n(&mailbox_sum, __ATOMIC_RELAXED);
int observed_iters = __atomic_load_n(&mailbox_iters, __ATOMIC_RELAXED);
uint64_t expected = expected_sum(iterations);
```

### 4.3 Synchronization Pattern

``` text
Producer:  store(mailbox_sum, sum, RELAXED)
           store(mailbox_iters, N, RELAXED)
           store(mailbox_ready, 1, RELEASE)  ← publishes visibility
                                               
Consumer:  while (!load(mailbox_ready, ACQUIRE)) { spin; }  ← waits, acquires
           sum_obs = load(mailbox_sum, RELAXED)  ← safe: acquire ordered it
           iters_obs = load(mailbox_iters, RELAXED)
           verify(sum_obs == expected_sum(N))
```

The **release-acquire pair** ensures the consumer sees the producer's stores before the ready flag, even on weakly-ordered architectures

### 4.4 Compilation Flags

``` bash
$ riscv64-linux-gnu-gcc -O2 -std=gnu11 -static -pthread
```

## 5. Result

The statistics below are from a successful 2048-iteration run. They reveal cache behavior, memory system efficiency, and per-core performance characteristics.

### 5.1 Overall System Performance

| Metric | Value | Description |
|--------|-------|-------------|
| **simTicks** | 374,372,500 | Total simulation time across all cores |
| **simInsts** | 202,166 | Total instructions executed |
| **hostSeconds** | 0.18 | Wall-clock time elapsed on host machine |
| **IPC** | ~0.27 | Instructions per cycle (typical for in-order CPUs with memory delays) |

### 5.2 CPU0 Performance (Consumer Thread)

**total cycles** = 748,745

| Metric | Accesses | Misses | Miss Rate | Description |
|--------|----------|--------|-----------|-------------|
| **L1 D-Cache** | 35,113 | 1,243 | 3.5% | Data cache; high miss rate due to spin-waiting on mailbox |
| **L1 I-Cache** | 206,447 | 521 | 0.25% | Instruction cache; tight polling loop |
| **L2 (total)** | — | 1,643 | 90.6% hit | 474 inst + 1,169 data misses |

### 5.3 CPU1 Performance (Producer Thread)

**total cycles** = 733,365

| Metric | Accesses | Misses | Miss Rate | Description |
|--------|----------|--------|-----------|-------------|
| **L1 D-Cache** | 8,399 | 96 | 1.1% | Data cache; low miss rate, tight inner loop |
| **L1 I-Cache** | 31,091 | 142 | 0.46% | Instruction cache; simple accumulation loop |
| **L2 (total)** | — | 125 | 93.6% hit | 82 inst + 43 data misses |

### 5.4 L2 Unified Cache Summary

| Component | CPU 0 | CPU 1 | Total |
|-----------|-------|-------|-------|
| **Demand Misses (Inst)** | 474 | 82 | 556 |
| **Demand Misses (Data)** | 1,169 | 43 | 1,212 |
| **Total Misses** | 1,643 | 125 | **1,768** |
| **Total Accesses** | 1,744 | 207 | **1,951** |
| **Hit Rate** | 90.6% | 93.6% | - |

### 5.5 Statistics Insights

**CPU Work Distribution:**

- number of cycles: CPU0 > CPU1 (CPU1 is the child thread)
- instruction accesses: CPU0 >> CPU1 (consumer is polling)
- Both cores run nearly in parallel (~733k to ~748k cycles) with minimal synchronization overhead

**Cache Behavior:**

| Metric | CPU 0 | CPU 1 | Insight |
|--------|-------|-------|---------|
| **L1 D$** | 1,243 misses / 35,113 accesses = 3.5% miss rate | 96 misses / 8,399 accesses = 1.1% miss rate | Producer has very tight memory access; consumer spins and polls ready flag |
| **L1 I$** | 521 misses / 206,447 accesses = 0.25% miss rate | 142 misses / 31,091 accesses = 0.46% miss rate | Low instruction cache pressure; simple, compact code |
| **L2 $** | 1,643 total misses (474 inst + 1,169 data) | 125 total misses (82 inst + 43 data) | Producer generates moderate L2 pressure; consumer L2 misses are minimal |

**Observations:**

1. **No prefetch activity**: demand misses = overall misses (prefetching disabled or not applicable)
2. **CPU 0 is memory-bound**: 35k data accesses vs. 31k for CPU 1 shows consumer doing more memory work (spinning)
3. **L2 unified cache is effective**: Only 1,768 total L2 misses out of 1,951 L2 accesses = **90.6% L2 hit rate**—excellent for this workload
4. **Inter-core communication is efficient**: Atomic operations and cache coherency work correctly; no deadlock or excessive L2 thrashing
5. **Small working set**: ~40k total L1 accesses + ~1,951 L2 accesses suggests the workload fits well within cache hierarchy

**Insights:**

- The shared-memory synchronization with atomics is low-overhead
- The spin-wait approach (vs. blocking) works well on small core counts
- Release-acquire ordering enforces cache coherency without excessive flushing
- This workload is memory-efficient and scales to slightly larger iteration counts without major cache problems

## 6. Conclusion

This lab demonstrated how to build and simulate a two-thread producer-consumer workload in gem5 SE mode on a RISC-V two-core system. The most important takeaway is that release-acquire semantics are essential for correctness: a release store on the ready flag paired with an acquire load on the consumer side is the minimal ordering that guarantees the consumer sees the producer's payload, and the gem5 cache stats made this visible in a way that unit tests alone cannot—CPU 0's 3.5% L1 D-cache miss rate versus CPU 1's 1.1% directly reflects the spin-wait polling pattern rather than any algorithmic inefficiency.

Going forward, the key practices are to always guard shared data with a release-store/acquire-load pair, add a poll timeout to every spin-wait to prevent silent simulation hangs. It is also worth keeping the working set small when studying synchronization effects on TimingSimpleCPU, and checking stats per-core rather than relying on aggregated totals, since asymmetric thread behavior details can get overlooked post aggregation.
