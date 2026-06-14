# Store + reuse: useful for write-through / write-allocate discussion
addi x1, x0, 64
addi x2, x0, 5
sw   x2, 0(x1)
lw   x3, 0(x1)
sw   x2, 4(x1)
lw   x4, 4(x1)
.word 0xffffffff
