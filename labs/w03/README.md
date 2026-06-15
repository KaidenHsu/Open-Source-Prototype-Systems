# Week 2 Lab. RV32I Smoke Test and Linker Script

## 1. Introduction

This lab builds and runs a minimal RV32I smoke test to verify that the bare-metal toolchain and custom linker script are working correctly before connecting them to an actual hardware simulator. The workload (`src/rv32i_smoke.S`) is a hand-written assembly program that exercises a small set of base integer instructions — `addi`, `add`, `xori`, and `sw` — then writes a known PASS signature (`0x2A`) to a fixed memory address (`0x110`) and halts in an infinite loop. Because the program is self-contained and produces deterministic values in memory, it serves as the simplest possible end-to-end sanity check: compile, link, disassemble, and confirm the expected bytes appear at the expected addresses.

## 2. Workflow

``` bash
$ ./run.sh
```

## 3. `run.sh` Decomposition

``` bash
$ riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Wl,-T,src/linker.ld -o build/rv32i_smoke.elf src/rv32i_smoke.S
```

Compiles the assembly source into a bare-metal ELF binary. `-march=rv32i` targets the base 32-bit integer ISA, `-mabi=ilp32` sets the 32-bit integer calling convention, `-nostdlib -ffreestanding` strips the standard library and runtime, and `-Wl,-T,src/linker.ld` passes the custom linker script to the linker.

``` bash
$ riscv64-unknown-elf-objdump -d build/rv32i_smoke.elf
```

Disassembles the ELF binary back into human-readable RISC-V assembly, letting you verify that the compiler emitted the expected instructions.

``` bash
$ riscv64-unknown-elf-objcopy -O verilog build/rv32i_smoke.elf build/rv32i_smoke.hex
```

Converts the ELF binary into a Verilog hex memory file (`.hex`) that can be loaded directly into a simulated or synthesized memory using `$readmemh`.


## 4. Workload (`src/hello.c`)

``` c
#include <stdio.h>

int main(void) {
    printf("Hello world!\n");
    return 0;
}
```

## 5. Linker Script (`src/linker.ld`)

``` c
ENTRY(_start)

MEMORY
{
  RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
  .text : {
    *(.text*)
  } > RAM

  .data : {
    *(.data*)
  } > RAM

  .bss : {
    *(.bss*)
  } > RAM
}
```

- `ENTRY(_start)` sets the program entry point to the `_start` symbol defined in the assembly startup code.
- `MEMORY` defines a single 64 KB RAM region starting at address `0x00000000` with read, write, and execute permissions.
- `SECTIONS` maps `.text` (code), `.data` (initialized globals), and `.bss` (zero-initialized globals) contiguously into RAM.
- All sections use wildcard patterns (e.g. `*(.text*)`) to capture similarly-named input sections from all object files.

## 6. Conclusion

The linker script makes the rest of the flow work on bare metal: it tells the linker where to place code and data in the physical address space, which is information that cannot come from the source code or the compiler. In this lab, it maps everything into a single 64 KB RAM region starting at `0x0`, which matches the memory map the hardware simulator will expose. `gcc` consumes the script via `-Wl,-T` during linking to produce a correctly placed ELF, `objdump` lets you verify that sections landed at the right addresses, and `objcopy` converts that placed ELF into the `.hex` that `$readmemh` loads into the simulated memory at exactly the addresses the linker script specified. Going forward, running this compile-disassemble-convert pipeline on any new workload before connecting it to the simulator is good practice — it isolates toolchain and memory-map issues from RTL bugs early. 
