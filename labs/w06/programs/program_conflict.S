# Conflict misses: 0x00 and 0x20 map to same line in 4-line, 2-word/line cache
addi x1, x0, 0
addi x2, x0, 32
lw   x3, 0(x1)
lw   x4, 0(x2)
lw   x5, 0(x1)
lw   x6, 0(x2)
.word 0xffffffff
