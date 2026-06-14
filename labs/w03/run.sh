#!/usr/bin/env bash

# 1. Compile
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Wl,-T,src/linker.ld -o build/rv32i_smoke.elf src/rv32i_smoke.S

# 2. Disassemble
riscv64-unknown-elf-objdump -d build/rv32i_smoke.elf

# 3. Convert into memory file
riscv64-unknown-elf-objcopy -O verilog build/rv32i_smoke.elf build/rv32i_smoke.hex
