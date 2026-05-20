# Project 3 simulation Makefile
# Default simulator: Verilator, matching the course Docker image.

VERILATOR ?= verilator
VERILATOR_FLAGS ?= --binary --timing --trace -sv -Wall -Wno-fatal -Wno-BLKSEQ
TOP = tb_project3
SRC = rtl/shared_memory.sv rtl/coherence_bus.sv rtl/msi_cache.sv rtl/core_driver.sv rtl/project3_top.sv rtl/tb_project3.sv

.PHONY: run_shared run_false run_padded run_local run_all lint clean

run_shared:
	mkdir -p logs
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $(TOP) --Mdir obj_dir_shared -DVARIANT=0 $(SRC)
	./obj_dir_shared/V$(TOP) | tee logs/shared.log

run_false:
	mkdir -p logs
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $(TOP) --Mdir obj_dir_false -DVARIANT=1 $(SRC)
	./obj_dir_false/V$(TOP) | tee logs/false.log

run_padded:
	mkdir -p logs
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $(TOP) --Mdir obj_dir_padded -DVARIANT=2 $(SRC)
	./obj_dir_padded/V$(TOP) | tee logs/padded.log

run_local:
	mkdir -p logs
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $(TOP) --Mdir obj_dir_local -DVARIANT=3 $(SRC)
	./obj_dir_local/V$(TOP) | tee logs/local.log

run_all: run_shared run_false run_padded run_local

lint:
	$(VERILATOR) --lint-only --timing -sv -Wall -Wno-fatal --top-module $(TOP) -DVARIANT=0 $(SRC)

clean:
	rm -rf obj_dir obj_dir_shared obj_dir_false obj_dir_padded obj_dir_local logs *.vcd
