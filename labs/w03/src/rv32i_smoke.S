    .section .text
    .globl _start

_start:
    # ------------------------------------------------------------
    # Simple RV32I smoke test
    # Goal:
    #   1. Execute a few ALU instructions
    #   2. Store intermediate data to memory
    #   3. Write a PASS signature to a fixed address
    #   4. Stop in an infinite loop
    # ------------------------------------------------------------



    # ------------------------------------------------------------
    # 1. Execute a few ALU instructions
    # ------------------------------------------------------------
    # x1 = 5
    addi x1, x0, 5

    # x2 = 7
    addi x2, x0, 7

    # x3 = x1 + x2 = 12
    add  x3, x1, x2

    # x4 = x3 - 2 = 10
    addi x4, x3, -2

    # x5 = x4 ^ 3 = 9
    xori x5, x4, 3

    # ------------------------------------------------------------
    # 2. Memory test region base address = 0x00000100
    # x10 = 0x00000100
    # ------------------------------------------------------------
    addi x10, x0, 0x100

    # Store x3 (=12) at [0x100]
    sw   x3, 0(x10)

    # Store x4 (=10) at [0x104]
    sw   x4, 4(x10)

    # Store x5 (=9) at [0x108]
    sw   x5, 8(x10)

    # ------------------------------------------------------------
    # 3. PASS signature
    # Signature address = 0x00000110
    # Signature value   = 0x0000002A
    # ------------------------------------------------------------
    addi x6, x0, 42
    sw   x6, 16(x10)

# 4. stop in an infinite loop
done:
    beq  x0, x0, done
