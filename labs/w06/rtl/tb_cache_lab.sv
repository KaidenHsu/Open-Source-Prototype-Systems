module tb_cache_lab;
    logic clk;
    logic reset;
    logic halted;
    logic [31:0] cycle_count, retired_count;
    logic [31:0] access_count, read_count, write_count, hit_count, miss_count;
    string program_file;
    string data_file;
    integer max_cycles;

    soc_top dut(
        .clk(clk), .reset(reset), .halted(halted),
        .cycle_count(cycle_count), .retired_count(retired_count),
        .access_count(access_count), .read_count(read_count), .write_count(write_count),
        .hit_count(hit_count), .miss_count(miss_count)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic print_state;
        $display("cycle=%0d pc=%08x instr=%08x accesses=%0d hits=%0d misses=%0d",
            cycle_count, dut.u_core.pc, dut.u_core.instr, access_count, hit_count, miss_count);
    endtask

    initial begin
        if (!$value$plusargs("PROGRAM=%s", program_file))
            program_file = "programs/program_temporal.hex";
        if (!$value$plusargs("DATA=%s", data_file))
            data_file = "programs/data_init.hex";
        if (!$value$plusargs("MAXCYC=%d", max_cycles))
            max_cycles = 300;

        $display("Loading program: %s", program_file);
        $readmemh(program_file, dut.u_imem.mem);
        $display("Loading data image: %s", data_file);
        $readmemh(data_file, dut.u_dram.mem);

        reset = 1'b1;
        repeat (2) @(posedge clk);
        reset = 1'b0;

        $dumpfile("week6_cache_lab.vcd");
        $dumpvars(0, tb_cache_lab);

        while (!halted && cycle_count < max_cycles) begin
            @(posedge clk);
            if (cycle_count <= 30)
                print_state();
        end

        if (!halted)
            $display("WARNING: reached MAXCYC before HALT.");

        $display(" ==== Final Lab Stats ====");
        $display("Total cycles           : %0d", cycle_count);
        $display("Retired instructions   : %0d", retired_count);
        $display("Memory accesses        : %0d", access_count);
        $display("Reads                  : %0d", read_count);
        $display("Writes                 : %0d", write_count);
        $display("Cache hits             : %0d", hit_count);
        $display("Cache misses           : %0d", miss_count);
        if (access_count != 0)
            $display("Hit rate               : %0f", (hit_count * 1.0) / access_count);
        if (retired_count != 0)
            $display("Approx CPI             : %0f", (cycle_count * 1.0) / retired_count);

        $display(" Register highlights: x1=%0d x2=%0d x3=%0d x4=%0d x5=%0d x6=%0d x7=%0d",
            dut.u_core.u_regfile.regs[1], dut.u_core.u_regfile.regs[2], dut.u_core.u_regfile.regs[3],
            dut.u_core.u_regfile.regs[4], dut.u_core.u_regfile.regs[5], dut.u_core.u_regfile.regs[6],
            dut.u_core.u_regfile.regs[7]);
        $display("Data[0]=%0d Data[8]=%0d Data[32]=%0d Data[64]=%0d",
            dut.u_dram.mem[0], dut.u_dram.mem[2], dut.u_dram.mem[8], dut.u_dram.mem[16]);
        $finish;
    end
endmodule
