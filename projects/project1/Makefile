TOP = testbench
BIN = obj_dir/V$(TOP)
VERILATOR_OPTS = -sv --timing --trace --binary --assert
SRCS = \
	single_cycle_top.sv \
	mux2.sv \
	adder.sv \
	branch_unit.sv \
	pc.sv \
	instr_mem.sv \
	regfile.sv \
	imm_gen.sv \
	alu.sv \
	data_mem.sv \
	control_unit.sv \
	instr_parser.sv \
	tb/testbench.sv

ALU_TOP = alu_tb
ALU_BIN = obj_dir/V$(ALU_TOP)
ALU_SRCS = \
	alu.sv \
	tb/alu_tb.sv

REGFILE_TOP = regfile_tb
REGFILE_BIN = obj_dir/V$(REGFILE_TOP)
REGFILE_SRCS = \
	regfile.sv \
	tb/regfile_tb.sv

IMM_GEN_TOP = imm_gen_tb
IMM_GEN_BIN = obj_dir/V$(IMM_GEN_TOP)
IMM_GEN_SRCS = \
	imm_gen.sv \
	tb/imm_gen_tb.sv

CONTROL_UNIT_TOP = control_unit_tb
CONTROL_UNIT_BIN = obj_dir/V$(CONTROL_UNIT_TOP)
CONTROL_UNIT_SRCS = \
	control_unit.sv \
	tb/control_unit_tb.sv

.PHONY: all alu regfile imm_gen control_unit clean

# make
all: $(BIN)

$(BIN): $(SRCS)
	verilator $(VERILATOR_OPTS) --top-module $(TOP) $(SRCS)

# make regfile
regfile: $(REGFILE_BIN)

$(REGFILE_BIN): $(REGFILE_SRCS)
	verilator $(VERILATOR_OPTS) --top-module $(REGFILE_TOP) $(REGFILE_SRCS)

# make imm_gen
imm_gen: $(IMM_GEN_BIN)

$(IMM_GEN_BIN): $(IMM_GEN_SRCS)
	verilator $(VERILATOR_OPTS) --top-module $(IMM_GEN_TOP) $(IMM_GEN_SRCS)

# make control_unit
control_unit: $(CONTROL_UNIT_BIN)

$(CONTROL_UNIT_BIN): $(CONTROL_UNIT_SRCS)
	verilator $(VERILATOR_OPTS) --top-module $(CONTROL_UNIT_TOP) $(CONTROL_UNIT_SRCS)

# make alu
alu: $(ALU_BIN)

$(ALU_BIN): $(ALU_SRCS)
	verilator $(VERILATOR_OPTS) --top-module $(ALU_TOP) $(ALU_SRCS)

# make clean
clean:
	rm -rf obj_dir/
