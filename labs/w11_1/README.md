# Week11 Lab1. Dual-Core Cache Coherence Prototype System Stabilization

## 1. Introduction

- Understand the two-core cache microarchitecture used in this exercise and the coherence checks implemented as SystemVerilog assertions.
- Be able to run the supplied directed and randomized tests and interpret the self-checking log output.
- Convert observed failures into a precise invariant and validate fixes with the provided test cases (`run-case-b`, `run-case-c`, `run-case-d`).
- Implement one or more assertion goals from Exercise F near the end of `rtl/two_core_cache_system.sv` before `endmodule`.

## 2. Workflow

``` bash
$ ./run.sh
```

## 3. System Architecture

The design is a minimal two-core cache system with a shared backing memory and per-core direct-mapped caches. Key files:

- `rtl/two_core_cache_system.sv` — top-level DUT implementing two per-core caches, a memory array, and debug signals (`dbg_inv0`, `dbg_inv1`, `dbg_mem_c0_addr`, `dbg_mem_c1_addr`).
- `rtl/tb_week11.sv` — self-checking testbench that drives directed sequences, random stress, and trace replays; it records `PASS`/`FAIL` lines and maintains a `golden_mem` model.

```text
+--------------+      +--------------------+     
| Core 0 req   | ---> | C0 private         | ----+
| R/W addr     | <--- | write-through      |     |
+--------------+      | cache              |     |      +--------------------+
                      +--------------------+     +----> | Shared memory      |
                              | snoop            |      | word array         |
                              v invalidation     |      +--------------------+
+--------------+      +--------------------+     |
| Core 1 req   | ---> | C1 private         | ----+
| R/W addr     | <--- | write-through      |      
+--------------+      | cache              |      
                      +--------------------+
```

- Core 0 interface (valid, we, addr, wdata) maps to C0 private cache and shared memory
- Core 1 interface (valid, we, addr, wdata) maps to C1 private cache and shared memory
- Snoop invalidation links the two private caches on conflicting writes

## 4. Baseline Stabiliization Run

Purpose: confirm the baseline model and test harness are stable before attempting any edits.

```bash
$ make build-baseline
$ make run-baseline
```

Expected outcome: `RESULT: PASS` from the testbench and no assertion failures from the RTL. Check the log at `logs/baseline.log` for the full trace of PASS/FAIL lines and the final summary.

What to record on success:

- number of `checks` and `errors` reported by the testbench.
- any debug pulses (`inv0`, `inv1`) logged with the PASS/FAIL lines.

Files to inspect on failure:

- `logs/baseline.log`
- `obj_dir/Vtb_week11.h` and generated simulator artifacts (only for deeper investigation)

## 5. Case B: First Failing Scenario

Target: `make run-case-b` builds with `-GLAB_VARIANT=1` and runs the directed trace.

```bash
$ make run-case-b
```

Behavior: this target historically demonstrates a coherence correctness issue exposed by a write/read sequence between the two cores. The testbench prints the first failing `FAIL[...]` line; use it as your starting point.

What to record from the first failure:

- failing line label (e.g., `seq03`), core number, op type (R/W), address, `got` vs `expected`, `hit` bit, `inv0`/`inv1` debug pulses.

Suggested invariants to check for Case B:

- After Core 0 completes a write to a line also cached by Core 1, Core 1 must not continue to return a stale readable copy (invalidate path correctness).
- The index/tag decode must compare the same stored tag value used for hit decisions.

Exercise F goals tied to this case:

- F3: After Core 0 writes to a line also held by Core 1, Core 1 must not continue to return a stale readable copy.
- F4: After Core 1 writes to a line also held by Core 0, Core 0 must not continue to return a stale readable copy.

Relevant locations:

- `rtl/two_core_cache_system.sv` — look at the write path that updates `mem` and invalidates the peer cache line.
- `rtl/tb_week11.sv` — directed sequence labels and the `do_single`/`do_dual` helpers that record expected values.

## 6. Case C: Address Contract Failure

Target: `make run-case-c` builds with `-GLAB_VARIANT=2` and replays `traces/address_alias.trace`.

```bash
$ make run-case-c
```

Behavior: this case exercises address aliasing / tag-index mapping problems — two different addresses that map to the same cache index but have different tags.

What to record from the first failure:

- the address pair involved and whether a hit was incorrectly reported for the wrong tag.

Suggested invariants to check for Case C:

- A cache hit must compare the stored tag against the requested tag, not only the index.
- Loading a line on a miss must store the correct tag and data into the targeted index without corrupting other lines.

``` text
addr [7:4 tag | 3:2 index | 1:0 word bits (byte offset)]
```

Exercise F goals tied to this case:

- F1: Core 0 must not accept a cache line as a hit if stored line identity does not match requested line identity.
- F2: Core 1 must not accept a cache line as a hit if stored line identity does not match requested line identity.

Relevant locations:

- `rtl/two_core_cache_system.sv` — `c0_idx`/`c1_idx` calculations and `line_addr_matches_cache` helper.
- `traces/address_alias.trace` — concrete trace steps that reproduce the aliasing scenario.

## 7. Case D: Same Cycle Interaction

Target: `make run-case-d` builds with `-GLAB_VARIANT=3` and replays `traces/simultaneous_race.trace`.

```bash
$ make run-case-d
```

Behavior: exercises same-cycle simultaneous requests (reads/writes to the same line or word) that require careful ordering or invalidation semantics.

What to record from the first failure:

- whether the requests overlapped (both valid on the same clock) and the addresses involved, plus the `got` vs `expected` values.

Suggested invariants to check for Case D:

- A same-cycle interaction must not lose a visibility event required for the next read to observe the correct value.
- If one core writes while the other reads the same line, the read must either see the updated value or be treated as a miss that fetches the correct data (depending on policy) — it must not silently return a stale value.

Exercise F goal tied to this case:

- F5: A same-cycle interaction must not lose a visibility event required for the next read to observe the correct value.

Relevant locations:

- `rtl/two_core_cache_system.sv` — simultaneous write/read handling and the `dbg_inv0`/`dbg_inv1` signals.
- `traces/simultaneous_race.trace` — the canonical race trace.


## 8. Write One New Trace

Trace format: text lines parsed by the testbench via `$sscanf` in `rtl/tb_week11.sv`. Each non-comment line has four fields: `OP CORE ADDR DATA` where `OP` is `R` or `W` (or `D` for a hardcoded simultaneous dual op used by the harness).

Quick steps to add a new trace:

1. Modify `scripts/make_traces.py`
2. Example trace format:

```
# op core addr data
W 0 0x20 0xCAFE0001
R 1 0x20 0x00000000
D 0 0x00 0x00000000   # special dual-case helper in the TB
```

3. Verify trace format:

```bash
$ python3 scripts/check_trace.py traces/my_case.trace
```

4. Run it with the simulator:

```bash
$ make run-raw-trace
```

Notes: the `trace_replay` task in `rtl/tb_week11.sv` gracefully falls back to the directed default if it cannot open the trace file.

## 9. Exercise F: Assertions

| No | Assertion goal |
|---|---|
| F1 | Core 0 must not accept a cache line as a hit if the stored line identity does not match the requested line identity. |
| F2 | Core 1 must not accept a cache line as a hit if the stored line identity does not match the requested line identity. |
| F3 | After Core 0 completes a write to a line also held by Core 1, Core 1 must not continue to return a stale readable copy. |
| F4 | After Core 1 completes a write to a line also held by Core 0, Core 0 must not continue to return a stale readable copy. |
| F5 | A same-cycle interaction must not lose a visibility event required for the next read to observe the correct value. |

Where to place it: add the selected check near the end of `rtl/two_core_cache_system.sv`.

## 10. Conclusion

- **Testing**: asks whether examples behave as expected
- **Verification**: asks whether properties remain true across many behaviors
- **Debugging**: finds the first point where the design violates an invariant
- **Stabilization**: turns an interesting prototype into a reproducible and trustworthy system
- **Multicore lesson**: shared state makes integration bugs visible only when another agent observes the stale or inconsistent state
