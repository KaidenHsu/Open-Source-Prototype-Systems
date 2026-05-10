# Temporal locality: same address loaded repeatedly
addi x1, x0, 0
lw   x3, 0(x1)
lw   x4, 0(x1)
lw   x5, 0(x1)
lw   x6, 0(x1)
.word 0xffffffff
