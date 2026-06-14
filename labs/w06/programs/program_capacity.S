# Capacity pressure: five blocks touched before reusing the first
addi x1, x0, 0
lw   x3, 0(x1)
lw   x4, 8(x1)
lw   x5, 16(x1)
lw   x6, 24(x1)
lw   x7, 32(x1)
lw   x3, 0(x1)
.word 0xffffffff
