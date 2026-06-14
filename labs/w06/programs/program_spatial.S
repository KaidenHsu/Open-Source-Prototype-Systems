# Spatial locality: adjacent words inside then across blocks
addi x1, x0, 0
lw   x3, 0(x1)
lw   x4, 4(x1)
lw   x5, 8(x1)
lw   x6, 12(x1)
.word 0xffffffff
