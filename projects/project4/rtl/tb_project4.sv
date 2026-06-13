module tb_project4;
    logic clk;
    logic reset;
    logic halted;

    project4_top dut (.clk(clk), .reset(reset), .halted(halted));

    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer cycle;
    initial begin
        $dumpfile("project4.vcd");
        $dumpvars(0, tb_project4);

        // reset
        reset = 1'b1;
        repeat (4) @(posedge clk);
        reset = 1'b0;

        // apply input


        // check answer
        for (cycle = 0; cycle < 200; cycle = cycle + 1) begin
            @(posedge clk);
            if (halted) begin
                check_results();
                $finish;
            end
        end

        $display("FAIL: timeout waiting for RISC-V program to halt");
        $finish;
    end

    task automatic check_word(input int idx, input logic signed [31:0] expected);
        logic signed [31:0] got;
        begin
            got = dut.data_memory.mem_array[idx];
            if (got !== expected) begin
                $display("[%0t] FAIL: output[%0d] expected %0d got %0d", $time, idx, expected, got);
                $finish;
            end
        end
    endtask

    task automatic check_results();
        begin
            check_word(0, -32'sd6);
            check_word(1,  32'sd18);
            check_word(2,  32'sd0);
            check_word(3,  32'sd45);

            #10 $display("PASS: RISC-V-controlled convolution accelerator produced expected outputs");
        end
    endtask
endmodule
