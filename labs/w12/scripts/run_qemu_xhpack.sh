riscv64-linux-gnu-gcc -O2 -static -march=rv64gc -mabi=lp64d \
  -o build/test_xhpack.riscv src/test_xhpack.c 
 
qemu-riscv64-xhist build/test_xhpack.riscv