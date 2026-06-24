# Week 14 Lab. Timing Side-Channel Security: Early-Exit Leakage in a Token Comparator

## 1. Introduction

This lab demonstrates timing leakage in an RTL token comparator. Students start from reproducing a deliberately leaky timing side channel token comparator and fix `rtl/secure_compare_fixed.sv` so that all candidate tokens complete in the same number of cycles and do not expose byte-progress through the public debug counter.

## 2. Workflow

```bash
$ bash run.sh
```

Use `make wave-buggy` or `make wave-fixed` to open the generated VCD in GTKWave.

## 3. Main files

- `rtl/secure_compare_buggy.sv`: Deliberately leaky reference for observation only.
- `rtl/secure_compare_fixed.sv`: File you modify.
- `tb/tb_secure_compare.cpp`: Verilator testbench.
- `scripts/check_constant_latency.py`: Checks basic leakage requirements.
- `scripts/analyze_latency.py`: Prints tables and optional plots.
- `Makefile`: Simulation, waveform, and synthesis commands.

## 4. Threat model

Assume an untrusted program can submit candidate tokens to a memory-mapped accelerator and measure when the accelerator asserts `done`. The final `match` bit is architecturally allowed. The byte position of the first mismatch is not allowed to leak.

## 5. Timing Side-Channel Leakage Patch

``` v
if (last_byte) begin
    running <= 1'b0;
    done <= 1'b1;
    match <= !(mismatch_seen || !byte_equal);
end else begin
    mismatch_seen <= (mismatch_seen || !byte_equal);
    idx <= idx + IDX_W'(1);
end
```

## 6. Directed and Randomized Verification

### 6.1 `secure_compare_buggy.sv`

| case | candidate_hex | match | latency_cycles | debug_count |
| --- | --- | ---: | ---: | ---: |
| exact_match | 0x1122334455667788 | 1 | 8 | 7 |
| mismatch_byte0 | 0x1122334455667777 | 0 | 1 | 0 |
| mismatch_byte1 | 0x1122334455668888 | 0 | 2 | 1 |
| mismatch_byte3 | 0x11223344aa667788 | 0 | 4 | 3 |
| mismatch_byte7 | 0xee22334455667788 | 0 | 8 | 7 |
| random_0 | 0xac0ea305d922b047 | 0 | 1 | 0 |
| random_1 | 0x137eb7d8669d8c7e | 0 | 1 | 0 |
| random_2 | 0x0aa707a7a7a8878b | 0 | 1 | 0 |
| random_3 | 0x772c418d25001f87 | 0 | 1 | 0 |
| random_4 | 0x7e59d70683ee5508 | 0 | 1 | 0 |

### 6.2 `secure_compare_fixed.sv`

| case | candidate_hex | match | latency_cycles | debug_count |
| --- | --- | ---: | ---: | ---: |
| exact_match | 0x1122334455667788 | 1 | 8 | 0 |
| mismatch_byte0 | 0x1122334455667777 | 0 | 8 | 0 |
| mismatch_byte1 | 0x1122334455668888 | 0 | 8 | 0 |
| mismatch_byte3 | 0x11223344aa667788 | 0 | 8 | 0 |
| mismatch_byte7 | 0xee22334455667788 | 0 | 8 | 0 |
| random_0 | 0xac0ea305d922b047 | 0 | 8 | 0 |
| random_1 | 0x137eb7d8669d8c7e | 0 | 8 | 0 |
| random_2 | 0x0aa707a7a7a8878b | 0 | 8 | 0 |
| random_3 | 0x772c418d25001f87 | 0 | 8 | 0 |
| random_4 | 0x7e59d70683ee5508 | 0 | 8 | 0 |

## 7. Conclusion

- Timing side channels can leak sensitive information when observable outputs (e.g. `done`) vary with internal progress; even a simple early-exit can expose the index of the first mismatching byte.
- Public debug signals must be designed carefully — `debug_count` in the buggy design directly revealed internal state and should be gated or kept constant in publicly-observable modes.
- Fixed-latency designs remove timing variation by processing all inputs to completion before asserting `done`; this trades latency and possibly area/power for reduced information leakage.
- Verification needs both directed tests (targeted mismatches) and randomized tests to increase confidence; the combined tables show both cases and highlight the leak in the buggy RTL and the constant-latency behavior in the fixed RTL.
- Small, self-contained Verilator testbenches are effective for rapid iteration; tools like Yosys and GTKWave help compare area and timing consequences of mitigations.
