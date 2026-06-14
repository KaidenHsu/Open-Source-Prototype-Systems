TOP=tb_cache_lab
RTL=rtl/regfile.sv rtl/alu.sv rtl/imm_gen.sv rtl/instr_rom.sv rtl/backing_ram.sv rtl/memory_hierarchy.sv rtl/rv32i_core.sv rtl/soc_top.sv rtl/tb_cache_lab.sv

build:
	verilator -sv --timing --trace --binary --top-module $(TOP) $(RTL)

run-temporal:
	./obj_dir/V$(TOP) +PROGRAM=programs/program_temporal.hex +DATA=programs/data_init.hex

run-spatial:
	./obj_dir/V$(TOP) +PROGRAM=programs/program_spatial.hex +DATA=programs/data_init.hex

run-conflict:
	./obj_dir/V$(TOP) +PROGRAM=programs/program_conflict.hex +DATA=programs/data_init.hex

run-capacity:
	./obj_dir/V$(TOP) +PROGRAM=programs/program_capacity.hex +DATA=programs/data_init.hex

run-write:
	./obj_dir/V$(TOP) +PROGRAM=programs/program_write_reuse.hex +DATA=programs/data_init.hex

clean:
	rm -rf obj_dir *.vcd
