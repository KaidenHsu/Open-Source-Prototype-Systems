VERILATOR ?= verilator
RTL_SRCS = rtl/rv32i_core.sv rtl/instr_mem.sv rtl/data_mem.sv rtl/mmio_decoder.sv rtl/conv_accel.sv rtl/project4_top.sv rtl/tb_project4.sv

.PHONY: run_rtl lint clean run_gem5_scalar run_gem5_optimized run_gem5_xdot4

run_rtl:
	mkdir -p logs
	$(VERILATOR) --binary --timing --trace -sv -Wall -Wno-fatal -Wno-BLKSEQ --top-module tb_project4 --Mdir obj_dir_project4 $(RTL_SRCS)
	@echo ""
	@echo ""
	./obj_dir_project4/Vtb_project4 | tee logs/rtl.log

lint:
	$(VERILATOR) --lint-only --timing -sv -Wall -Wno-fatal -Wno-BLKSEQ --top-module tb_project4 $(RTL_SRCS)

run_gem5_scalar:
	bash gem5/scripts/run_bench.sh conv2d_scalar

run_gem5_optimized:
	bash gem5/scripts/run_bench.sh conv2d_optimized

run_gem5_xdot4:
	bash gem5/scripts/run_bench.sh conv2d_xdot4

inspect_asm:
	riscv64-linux-gnu-objdump -d -S -C build/conv2d_xdot4.riscv > build/conv2d_xdot4.asm

clean:
	rm -rf obj_dir_project4 build
