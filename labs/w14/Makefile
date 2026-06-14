VERILATOR ?= verilator
YOSYS ?= yosys
GTKWAVE ?= gtkwave
PYTHON ?= python3

BUILD_DIR := build
OBJ_BUGGY := obj_dir_buggy
OBJ_FIXED := obj_dir_fixed

.PHONY: sim sim-buggy sim-fixed test analyze synth synth-buggy synth-fixed wave-buggy wave-fixed clean

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

sim: sim-buggy test analyze

sim-buggy: $(BUILD_DIR)
	$(VERILATOR) --cc --exe --build --trace --top-module secure_compare_buggy \
		-Mdir $(OBJ_BUGGY) rtl/secure_compare_buggy.sv tb/tb_secure_compare.cpp \
		-CFLAGS "-DDESIGN_BUGGY"
	./$(OBJ_BUGGY)/Vsecure_compare_buggy +trace \
		+csv=$(BUILD_DIR)/latency_buggy.csv +vcd=$(BUILD_DIR)/trace_buggy.vcd

sim-fixed: $(BUILD_DIR)
	$(VERILATOR) --cc --exe --build --trace --top-module secure_compare_fixed \
		-Mdir $(OBJ_FIXED) rtl/secure_compare_fixed.sv tb/tb_secure_compare.cpp \
		-CFLAGS "-DDESIGN_FIXED"
	./$(OBJ_FIXED)/Vsecure_compare_fixed +trace \
		+csv=$(BUILD_DIR)/latency_fixed.csv +vcd=$(BUILD_DIR)/trace_fixed.vcd

test: sim-fixed
	$(PYTHON) scripts/check_constant_latency.py $(BUILD_DIR)/latency_fixed.csv

analyze:
	$(PYTHON) scripts/analyze_latency.py $(BUILD_DIR)/latency_buggy.csv $(BUILD_DIR)/latency_fixed.csv

synth: synth-buggy synth-fixed

synth-buggy: $(BUILD_DIR)
	$(YOSYS) -p "read_verilog -sv rtl/secure_compare_buggy.sv; synth -top secure_compare_buggy; stat" \
		> $(BUILD_DIR)/yosys_buggy.rpt

synth-fixed: $(BUILD_DIR)
	$(YOSYS) -p "read_verilog -sv rtl/secure_compare_fixed.sv; synth -top secure_compare_fixed; stat" \
		> $(BUILD_DIR)/yosys_fixed.rpt

wave-buggy: sim-buggy
	$(GTKWAVE) $(BUILD_DIR)/trace_buggy.vcd &

wave-fixed: sim-fixed
	$(GTKWAVE) $(BUILD_DIR)/trace_fixed.vcd &

transitions: sim-buggy sim-fixed
	$(PYTHON) scripts/count_vcd_transitions.py $(BUILD_DIR)/trace_buggy.vcd
	$(PYTHON) scripts/count_vcd_transitions.py $(BUILD_DIR)/trace_fixed.vcd

clean:
	rm -rf $(OBJ_BUGGY) $(OBJ_FIXED)
