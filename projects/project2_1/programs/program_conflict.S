# Conflict misses: 0x00 and 0x20 map to same line in 4-line, 2-word/line cache
addi x1, x0, 0 # x1 = 0
addi x2, x0, 32 // x2 = 32
lw   x3, 0(x1) // x3 = dmem[0]
lw   x4, 0(x2) // x4 = dmem[32]
lw   x5, 0(x1) // x5 = dmem[0]
lw   x6, 0(x2) // x6 = dmem[32]
.word 0xffffffff
