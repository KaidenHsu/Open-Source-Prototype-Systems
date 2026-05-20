`timescale 1ns/1ps

`ifndef VARIANT
`define VARIANT 0
`endif

module tb_project3;
    localparam VARIANT = `VARIANT;
    localparam ITERATIONS = 16;

    logic clk;
    logic reset;
    logic done0, done1;
    logic [31:0] cycles;
    logic [31:0] c0_hits, c0_misses, c0_invalidations, c0_upgrades;
    logic [31:0] c1_hits, c1_misses, c1_invalidations, c1_upgrades;
    logic [31:0] bus_busrd, bus_busrdx;
    logic [31:0] m0, m1, m4, m16, m17, m18, m19, m32, m33, m34, m35;

    project3_top #(.VARIANT(VARIANT), .ITERATIONS(ITERATIONS)) dut (
        .clk(clk), .reset(reset), .done0(done0), .done1(done1), .cycles(cycles),
        .c0_hits(c0_hits), .c0_misses(c0_misses), .c0_invalidations(c0_invalidations), .c0_upgrades(c0_upgrades),
        .c1_hits(c1_hits), .c1_misses(c1_misses), .c1_invalidations(c1_invalidations), .c1_upgrades(c1_upgrades),
        .bus_busrd(bus_busrd), .bus_busrdx(bus_busrdx),
        .dbg_mem0(m0), .dbg_mem1(m1), .dbg_mem4(m4),
        .dbg_mem16(m16), .dbg_mem17(m17), .dbg_mem18(m18), .dbg_mem19(m19),
        .dbg_mem32(m32), .dbg_mem33(m33), .dbg_mem34(m34), .dbg_mem35(m35)
    );

    initial clk = 0;
    /* verilator lint_off BLKSEQ */
    always #5 clk = ~clk;
    /* verilator lint_on BLKSEQ */

    initial begin
        $dumpfile("project3.vcd");
        $dumpvars(0, tb_project3);
        reset = 1;
        repeat (5) @(posedge clk);
        reset = 0;
        repeat (4000) begin
            @(posedge clk);
            if (done0 && done1) begin
                repeat (5) @(posedge clk);
                print_summary();
                run_checks();
                $finish;
            end
        end
        $display("FAIL: timeout");
        $finish;
    end

    task print_summary;
        begin
            $display("--- Project 3 summary ---");
            $display("variant=%0d cycles=%0d", VARIANT, cycles);
            $display("core0 hits=%0d misses=%0d invalidations=%0d upgrades=%0d", c0_hits, c0_misses, c0_invalidations, c0_upgrades);
            $display("core1 hits=%0d misses=%0d invalidations=%0d upgrades=%0d", c1_hits, c1_misses, c1_invalidations, c1_upgrades);
            $display("bus BusRd=%0d BusRdX=%0d", bus_busrd, bus_busrdx);
            $display("mem[0]=%0d mem[1]=%0d mem[4]=%0d", m0, m1, m4);
            $display("local0=%0d,%0d,%0d,%0d", m16, m17, m18, m19);
            $display("local1=%0d,%0d,%0d,%0d", m32, m33, m34, m35);
        end
    endtask

    task run_checks;
        begin
            if (VARIANT == 1) begin
                if (m0 != ITERATIONS || m1 != ITERATIONS) begin
                    $display("FAIL: false-sharing final bin values are incorrect");
                    $finish;
                end
                if ((c0_invalidations + c1_invalidations) == 0) begin
                    $display("FAIL: false-sharing workload should cause invalidations");
                    $finish;
                end
            end
            if (VARIANT == 2) begin
                if (m0 != ITERATIONS || m4 != ITERATIONS) begin
                    $display("FAIL: padded final bin values are incorrect");
                    $finish;
                end
            end
            if (VARIANT == 3) begin
                if (m16 != 4 || m17 != 4 || m18 != 4 || m19 != 4 ||
                    m32 != 4 || m33 != 4 || m34 != 4 || m35 != 4) begin
                    $display("FAIL: local-bin final values are incorrect");
                    $finish;
                end
            end
            $display("PASS");
        end
    endtask
endmodule
