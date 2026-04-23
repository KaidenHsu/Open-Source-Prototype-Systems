`define CLK_PRD 10

module testbench;

    logic clk;
    logic reset;

    // set to 1 to trace pc_current
    bit trace_pc = 0;

    single_cycle_top dut(
        .clk  (clk),
        .reset(reset)
    );

    // TODO: Generate a clock.
    // Suggested period: 10 time units.
    initial begin
        clk = 0;
        forever #(`CLK_PRD/2) clk = ~clk;
    end

    initial begin
        $dumpfile("trace.vcd");
        $dumpvars(0, testbench);

        // -------------------------------------
        //       Test Case 1
        // -------------------------------------
        // Apply reset before running the program.
        reset = 1;

        // Load program image while in reset.
        $readmemh("./pattern/program1.hex", dut.u_imem.mem_array);

        if (trace_pc) $display("program 1 PC trace:");

        repeat (2) @(posedge clk);

        // Release reset and start checking PC flow.
        reset = 0;
        @(posedge clk);
        pc_test;

        // Let writeback/memory effects settle for one more cycle.
        @(posedge clk);

        // SVA to verify final register and memory values
        assert(dut.u_regs.regs[1] == 5) else $error("x1 = %d, expected 5", dut.u_regs.regs[1]);
        assert(dut.u_regs.regs[2] == 7) else $error("x2 = %d, expected 7", dut.u_regs.regs[2]);
        assert(dut.u_regs.regs[3] == 12) else $error("x3 = %d, expected 12", dut.u_regs.regs[3]);
        assert(dut.u_regs.regs[8] == 12) else $error("x8 = %d, expected 12", dut.u_regs.regs[8]);

        assert(dut.u_dmem.mem_array[0] == 12) else $error("mem[0] = %d, expected 0", dut.u_dmem.mem_array[0]);

        @(posedge clk);

        #(3*`CLK_PRD)

        // -------------------------------------
        //       Test Case 2
        // -------------------------------------
        // Apply reset before running the program.
        reset = 1;

        // Load program image while in reset.
        $readmemh("./pattern/program2.hex", dut.u_imem.mem_array);
        if (trace_pc) $display("program 2 PC trace:");

        repeat (2) @(posedge clk);

        // Release reset and start checking PC flow.
        reset = 0;
        @(posedge clk);
        pc_test;

        // Let writeback/memory effects settle for one more cycle.
        @(posedge clk);

        // SVA to verify final register and memory values
        #1 // wait a delta cycle to make sure WB settles
        assert (dut.u_regs.regs[31] == 32'h0) else $error("x31 = %h, expected 0", dut.u_regs.regs[31]);
        assert (dut.u_regs.regs[2]  == 32'd100) else $error("x2 = %0d, expected 100", dut.u_regs.regs[2]);
        assert (dut.u_regs.regs[8]  == 32'd100) else $error("x8 = %0d, expected 100", dut.u_regs.regs[8]);
        assert (dut.u_regs.regs[5]  == 32'd15)  else $error("x5 = %0d, expected 15", dut.u_regs.regs[5]);
        assert (dut.u_regs.regs[6]  == 32'd25)  else $error("x6 = %0d, expected 25", dut.u_regs.regs[6]);
        assert (dut.u_regs.regs[7]  == 32'd2)   else $error("x7 = %0d, expected 2", dut.u_regs.regs[7]);
        assert (dut.u_regs.regs[10] == 32'd99)  else $error("x10 = %0d, expected 99", dut.u_regs.regs[10]);
        assert (dut.u_regs.regs[14] == 32'd999) else $error("x14 = %0d, expected 999", dut.u_regs.regs[14]);

        assert (dut.u_dmem.mem_array[0] == 32'd10) else $error("dmem[0] = %0d, expected 10", dut.u_dmem.mem_array[0]);
        assert (dut.u_dmem.mem_array[4] == -32'd8) else $error("dmem[4] = %0d, expected -8", dut.u_dmem.mem_array[4]);

        $display ("--------------------------------------------------------------------");
        $display ("                         Congratulations!                           ");
        $display ("            You have passed PC & integration test!                  ");
        $display ("--------------------------------------------------------------------");
        #(`CLK_PRD);
        $finish;
    end



    // pc trace
    always @(dut.pc_current) begin
        if (trace_pc) begin
            #1 $display("[%0t] %2h", $time, dut.pc_current);
        end
    end



    // pc test assertion
    task automatic pc_test;
        int exp_pc;

        while (dut.u_regs.regs[14] != 32'd999) begin
            @(negedge clk);

            if (dut.branch_taken) begin // taken branch
                exp_pc = dut.branch_target;
            end else if (dut.Jump) begin // jump
                exp_pc = dut.jump_target;
            end else begin // next instruction
                exp_pc = dut.pc_current + 4;
            end

            #1
            assert(dut.pc_next == exp_pc)
                else $error("next pc assertion failed! expected = %0d, got = %0d", exp_pc, dut.pc_next);

            @(posedge clk);
            #1
            assert(dut.pc_current == exp_pc)
                else $error("current pc assertion failed! expected = %0d, got = %0d", exp_pc, dut.pc_current);
        end
    endtask
endmodule
