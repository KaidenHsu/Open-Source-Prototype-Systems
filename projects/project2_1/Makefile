TOP=tb_project2
RTL=rtl/regfile.sv rtl/alu.sv rtl/imm_gen.sv rtl/instr_mem.sv rtl/backing_ram.sv rtl/hazard_unit.sv rtl/forwarding_unit.sv rtl/icache.sv rtl/dcache.sv rtl/pipeline_core.sv rtl/pipeline_controller.sv rtl/one_pulser.sv rtl/soc_top.sv rtl/tb_project2.sv

build:
	verilator -sv --timing --trace --binary --assert --top-module $(TOP) $(RTL)

run-nohaz:
	./obj_dir/V$(TOP) +PROGRAM=programs/program_no_hazard.hex

run-forward:
	./obj_dir/V$(TOP) +PROGRAM=programs/program_forwarding.hex

run-loaduse:
	./obj_dir/V$(TOP) +PROGRAM=programs/program_load_use.hex

run-branch:
	./obj_dir/V$(TOP) +PROGRAM=programs/program_branch_taken.hex

run-temporal:
	./obj_dir/V$(TOP) +PROGRAM=programs/program_temporal.hex +DATA=programs/data_init.hex

run-conflict:
	./obj_dir/V$(TOP) +PROGRAM=programs/program_conflict.hex +DATA=programs/data_init.hex

clean:
	rm -rf obj_dir *.vcd
