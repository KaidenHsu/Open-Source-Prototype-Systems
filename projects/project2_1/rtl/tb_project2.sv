module tb_project2;
    logic clk, reset, halted;
    logic [31:0] cycle_count, retired_count;
    logic [31:0] dc_access_count, dc_hit_count, dc_miss_count;
    string program_file;
    integer max_cycles;
    
    soc_top dut(
        .clk(clk), .reset(reset), .halted(halted), .cycle_count(cycle_count), .retired_count(retired_count),
        .dc_access_count(dc_access_count), .dc_hit_count(dc_hit_count), .dc_miss_count(dc_miss_count)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic print_state;
        $display("cycle=%02d pc=%08x IF/ID=%08x d_hits=%0d d_misses=%0d",
            cycle_count, dut.u_core.pc_reg, dut.u_core.if_id.instr, dc_hit_count, dc_miss_count);
    endtask

    initial begin
        if (!$value$plusargs("PROGRAM=%s", program_file))
            program_file = "programs/program_no_hazard.hex";
        if (!$value$plusargs("MAXCYC=%d", max_cycles))
            max_cycles = 120;

        $display("Loading program: %s", program_file);
        $readmemh(program_file, dut.u_imem_back.mem);
        $readmemh("programs/data_init.hex", dut.u_dmem_back.mem);

        reset = 1'b1;
        repeat (2) @(posedge clk);
        reset = 1'b0;

        $dumpfile("project2.vcd");
        $dumpvars(0, tb_project2);

        while (!halted && cycle_count < max_cycles) begin
            @(posedge clk);
            if (cycle_count <= 100)
                print_state();
        end

        $display("\n* Project 2 Starter Stats");
        $display("Total cycles         : %0d", cycle_count);
        $display("Retired instructions : %0d", retired_count);
        $display("D-cache accesses     : %0d", dc_access_count);
        $display("D-cache hits         : %0d", dc_hit_count);
        $display("D-cache misses       : %0d", dc_miss_count);
        if (dc_access_count != 0)
            $display("D-cache hit rate     : %0f", (dc_hit_count * 1.0) / dc_access_count);

        if (program_file == "programs/program_no_hazard.hex") begin
            assert (dut.u_core.u_regfile.regs[1] == 32'd5)  else $error("x1 expected 5, got %0d",  dut.u_core.u_regfile.regs[1]);
            assert (dut.u_core.u_regfile.regs[2] == 32'd7)  else $error("x2 expected 7, got %0d",  dut.u_core.u_regfile.regs[2]);
            assert (dut.u_core.u_regfile.regs[3] == 32'd9)  else $error("x3 expected 9, got %0d",  dut.u_core.u_regfile.regs[3]);
            assert (dut.u_core.u_regfile.regs[4] == 32'd12) else $error("x4 expected 12, got %0d", dut.u_core.u_regfile.regs[4]);
            assert (dut.u_core.u_regfile.regs[6] == 32'd16) else $error("x6 expected 16, got %0d", dut.u_core.u_regfile.regs[6]);
        end else if (program_file == "programs/program_forwarding.hex") begin
            assert (dut.u_core.u_regfile.regs[1] == 32'd5)  else $error("x1 expected 5, got %0d",  dut.u_core.u_regfile.regs[1]);
            assert (dut.u_core.u_regfile.regs[2] == 32'd7)  else $error("x2 expected 7, got %0d",  dut.u_core.u_regfile.regs[2]);
            assert (dut.u_core.u_regfile.regs[5] == 32'd12) else $error("x5 expected 12, got %0d", dut.u_core.u_regfile.regs[5]);
            assert (dut.u_core.u_regfile.regs[6] == 32'd19) else $error("x6 expected 19, got %0d", dut.u_core.u_regfile.regs[6]);
            assert (dut.u_core.u_regfile.regs[7] == 32'd17) else $error("x7 expected 17, got %0d", dut.u_core.u_regfile.regs[7]);
        end else if (program_file == "program_branch_taken.hex") begin
            assert (dut.u_core.u_regfile.regs[1] == 32'd1)  else $error("x1 expected 1, got %0d",  dut.u_core.u_regfile.regs[1]);
            assert (dut.u_core.u_regfile.regs[2] == 32'd1)  else $error("x2 expected 1, got %0d",  dut.u_core.u_regfile.regs[2]);
            assert (dut.u_core.u_regfile.regs[3] == 32'd0)  else $error("x3 expected 0, got %0d",  dut.u_core.u_regfile.regs[3]);
            assert (dut.u_core.u_regfile.regs[4] == 32'd42) else $error("x4 expected 42, got %0d", dut.u_core.u_regfile.regs[4]);
        end else if (program_file == "programs/program_temporal.hex") begin
            assert (dut.u_core.u_regfile.regs[1] == 32'h0)  else $error("x1 expected 0, got %0d",  dut.u_core.u_regfile.regs[1]);
            assert (dut.u_core.u_regfile.regs[3] == 32'h64) else $error("x3 expected 100, got %0d", dut.u_core.u_regfile.regs[3]);
            assert (dut.u_core.u_regfile.regs[4] == 32'h64) else $error("x4 expected 100, got %0d", dut.u_core.u_regfile.regs[4]);
            assert (dut.u_core.u_regfile.regs[5] == 32'h64) else $error("x5 expected 100, got %0d", dut.u_core.u_regfile.regs[5]);
            assert (dut.u_core.u_regfile.regs[6] == 32'h64) else $error("x6 expected 100, got %0d", dut.u_core.u_regfile.regs[6]);
        end else if (program_file == "programs/program_conflict.hex") begin
            assert (dut.u_core.u_regfile.regs[1] == 32'h0)  else $error("x1 expected 0, got %0d",  dut.u_core.u_regfile.regs[1]);
            assert (dut.u_core.u_regfile.regs[2] == 32'h20) else $error("x2 expected 32, got %0d", dut.u_core.u_regfile.regs[2]);
            assert (dut.u_core.u_regfile.regs[3] == 32'h64) else $error("x3 expected 100, got %0d", dut.u_core.u_regfile.regs[3]);
            assert (dut.u_core.u_regfile.regs[4] == 32'hC8) else $error("x4 expected 200, got %0d", dut.u_core.u_regfile.regs[4]);
            assert (dut.u_core.u_regfile.regs[5] == 32'h64) else $error("x5 expected 100, got %0d", dut.u_core.u_regfile.regs[5]);
            assert (dut.u_core.u_regfile.regs[6] == 32'hC8) else $error("x6 expected 200, got %0d", dut.u_core.u_regfile.regs[6]);
        end

        $finish;
    end

endmodule
