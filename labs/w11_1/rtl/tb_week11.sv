`timescale 1ns/1ps

module tb_week11;
    parameter int LAB_VARIANT = 0;
    localparam int ADDR_W = 8;
    localparam int DATA_W = 32;
    localparam int MEM_WORDS = 1 << (ADDR_W-2);

    logic clk;
    logic rst_n;

    logic c0_valid, c0_we;
    logic [ADDR_W-1:0] c0_addr;
    logic [DATA_W-1:0] c0_wdata;
    logic c0_ready;
    logic [DATA_W-1:0] c0_rdata;
    logic c0_hit;

    logic c1_valid, c1_we;
    logic [ADDR_W-1:0] c1_addr;
    logic [DATA_W-1:0] c1_wdata;
    logic c1_ready;
    logic [DATA_W-1:0] c1_rdata;
    logic c1_hit;
    logic dbg_inv0, dbg_inv1;
    logic [DATA_W-1:0] dbg_mem_c0_addr, dbg_mem_c1_addr;

    int errors;
    int checks;
    string trace_file;
    logic [DATA_W-1:0] golden_mem [MEM_WORDS];

    two_core_cache_system #(.LAB_VARIANT(LAB_VARIANT)) dut (
        .clk(clk), .rst_n(rst_n),
        .c0_valid(c0_valid), .c0_we(c0_we), .c0_addr(c0_addr), .c0_wdata(c0_wdata),
        .c0_ready(c0_ready), .c0_rdata(c0_rdata), .c0_hit(c0_hit),
        .c1_valid(c1_valid), .c1_we(c1_we), .c1_addr(c1_addr), .c1_wdata(c1_wdata),
        .c1_ready(c1_ready), .c1_rdata(c1_rdata), .c1_hit(c1_hit),
        .dbg_inv0(dbg_inv0), .dbg_inv1(dbg_inv1),
        .dbg_mem_c0_addr(dbg_mem_c0_addr), .dbg_mem_c1_addr(dbg_mem_c1_addr)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic reset_dut;
        int i;
        begin
            rst_n = 1'b0;
            c0_valid = 0; c0_we = 0; c0_addr = 0; c0_wdata = 0;
            c1_valid = 0; c1_we = 0; c1_addr = 0; c1_wdata = 0;
            errors = 0;
            checks = 0;
            for (i = 0; i < MEM_WORDS; i = i + 1) golden_mem[i] = 32'h1000_0000 + i;
            repeat (4) @(posedge clk);
            rst_n = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    task automatic drive_idle;
        begin
            c0_valid = 0; c0_we = 0; c0_addr = '0; c0_wdata = '0;
            c1_valid = 0; c1_we = 0; c1_addr = '0; c1_wdata = '0;
        end
    endtask

    task automatic do_single(input int core, input bit we, input logic [ADDR_W-1:0] addr, input logic [DATA_W-1:0] wdata, input string label);
        logic [DATA_W-1:0] expected;
        begin
            expected = we ? wdata : golden_mem[addr[ADDR_W-1:2]];
            @(negedge clk);
            drive_idle();
            if (core == 0) begin
                c0_valid = 1; c0_we = we; c0_addr = addr; c0_wdata = wdata;
            end else begin
                c1_valid = 1; c1_we = we; c1_addr = addr; c1_wdata = wdata;
            end
            @(posedge clk);
            #1;
            checks++;
            if (core == 0) begin
                if (c0_rdata !== expected) begin
                    $display("FAIL[%s]: C0 %s addr=0x%02h got=0x%08h expected=0x%08h", label, we ? "WRITE" : "READ", addr, c0_rdata, expected);
                    errors++;
                end else begin
                    $display("PASS[%s]: C0 %s addr=0x%02h data=0x%08h hit=%0b inv0=%0b inv1=%0b", label, we ? "WRITE" : "READ", addr, c0_rdata, c0_hit, dbg_inv0, dbg_inv1);
                end
            end else begin
                if (c1_rdata !== expected) begin
                    $display("FAIL[%s]: C1 %s addr=0x%02h got=0x%08h expected=0x%08h", label, we ? "WRITE" : "READ", addr, c1_rdata, expected);
                    errors++;
                end else begin
                    $display("PASS[%s]: C1 %s addr=0x%02h data=0x%08h hit=%0b inv0=%0b inv1=%0b", label, we ? "WRITE" : "READ", addr, c1_rdata, c1_hit, dbg_inv0, dbg_inv1);
                end
            end
            if (we) golden_mem[addr[ADDR_W-1:2]] = wdata;
            @(negedge clk);
            drive_idle();
        end
    endtask

    task automatic do_dual(input bit c0we, input logic [ADDR_W-1:0] a0, input logic [DATA_W-1:0] d0,
                           input bit c1we, input logic [ADDR_W-1:0] a1, input logic [DATA_W-1:0] d1,
                           input string label);
        logic [DATA_W-1:0] exp0, exp1;
        begin
            exp0 = c0we ? d0 : golden_mem[a0[ADDR_W-1:2]];
            exp1 = c1we ? d1 : golden_mem[a1[ADDR_W-1:2]];
            @(negedge clk);
            c0_valid = 1; c0_we = c0we; c0_addr = a0; c0_wdata = d0;
            c1_valid = 1; c1_we = c1we; c1_addr = a1; c1_wdata = d1;
            @(posedge clk);
            #1;
            checks += 2;
            if (c0_rdata !== exp0) begin
                $display("FAIL[%s]: simultaneous C0 got=0x%08h expected=0x%08h", label, c0_rdata, exp0);
                errors++;
            end
            if (c1_rdata !== exp1) begin
                $display("FAIL[%s]: simultaneous C1 got=0x%08h expected=0x%08h", label, c1_rdata, exp1);
                errors++;
            end
            $display("DUAL[%s]: C0 data=0x%08h C1 data=0x%08h inv0=%0b inv1=%0b", label, c0_rdata, c1_rdata, dbg_inv0, dbg_inv1);
            if (c0we) golden_mem[a0[ADDR_W-1:2]] = d0;
            if (c1we) golden_mem[a1[ADDR_W-1:2]] = d1;
            @(negedge clk);
            drive_idle();
        end
    endtask

    task automatic directed_default;
        begin
            $display("\n--- Directed coherence tests ---");
            do_single(0, 0, 8'h20, 32'h0, "seq01");
            do_single(1, 0, 8'h20, 32'h0, "seq02");
            do_single(0, 1, 8'h20, 32'hCAFE_0001, "seq03");
            do_single(1, 0, 8'h20, 32'h0, "seq04");
            do_single(1, 1, 8'h20, 32'hBEEF_0002, "seq05");
            do_single(0, 0, 8'h20, 32'h0, "seq06");
            do_single(0, 0, 8'h20, 32'h0, "seq07");
            do_single(0, 0, 8'h30, 32'h0, "seq08");
            do_single(0, 0, 8'h20, 32'h0, "seq09");
            do_dual(0, 8'h24, 32'h0, 1, 8'h24, 32'hFACE_1111, "seq10");
            do_single(0, 0, 8'h24, 32'h0, "seq11");
        end
    endtask

    task automatic random_stress(input int n);
        int k;
        int core;
        int word_idx;
        bit we;
        logic [ADDR_W-1:0] addr;
        logic [DATA_W-1:0] data;
        begin
            $display("\n--- Random stress tests ---");
            for (k = 0; k < n; k = k + 1) begin
                core = $urandom_range(0, 1);
                we = ($urandom_range(0, 99) < 35);
                word_idx = $urandom_range(0, 15);
                addr = {2'b00, word_idx[3:0], 2'b00};
                data = 32'hD000_0000 | k;
                do_single(core, we, addr, data, $sformatf("rnd%0d", k));
            end
        end
    endtask

    task automatic trace_replay(input string fname);
        int fd;
        int code;
        string op;
        string line;
        int core;
        int addr_i;
        int data_i;
        int lineno;
        int fstatus;
        begin
            fd = $fopen(fname, "r");
            if (fd == 0) begin
                $display("WARN: Could not open trace '%s'; falling back to directed_default", fname);
                directed_default();
                return;
            end
            $display("\n--- Trace replay: %s ---", fname);
            lineno = 0;
            fstatus = $fgets(line, fd);
            while (fstatus != 0) begin
                lineno++;
                op = ""; core = 0; addr_i = 0; data_i = 0;
                code = $sscanf(line, "%s %d %h %h", op, core, addr_i, data_i);
                if (code == 0 || op == "#") begin
                    fstatus = $fgets(line, fd);
                    continue;
                end
                if (code == 4) begin
                    if (op == "R") begin
                        do_single(core, 0, addr_i[ADDR_W-1:0], '0, $sformatf("trace line %0d", lineno));
                    end else if (op == "W") begin
                        do_single(core, 1, addr_i[ADDR_W-1:0], data_i[DATA_W-1:0], $sformatf("trace line %0d", lineno));
                    end else if (op == "D") begin
                        // D line format: D ignored_addr ignored_data, followed by hard-coded simultaneous race.
                        do_dual(0, 8'h24, 32'h0, 1, 8'h24, 32'hFACE_1111, $sformatf("trace line %0d", lineno));
                    end else begin
                        $display("WARN: ignored unknown trace op '%s' on line %0d", op, lineno);
                    end
                end else begin
                    $display("WARN: ignored malformed trace line %0d: %s", lineno, line);
                end
                fstatus = $fgets(line, fd);
            end
            $fclose(fd);
        end
    endtask

    initial begin
        if (!$value$plusargs("TRACE=%s", trace_file)) trace_file = "";

        reset_dut();

        if (trace_file.len() > 0) trace_replay(trace_file);
        else directed_default();

        random_stress(20);
        $display("\nSUMMARY: LAB_VARIANT=%0d checks=%0d errors=%0d", LAB_VARIANT, checks, errors);

        if (errors == 0) begin
            $display("RESULT: PASS");
            $finish;
        end else begin
            $display("RESULT: FAIL");
            $fatal(1, "Self-checking testbench detected failures");
        end
    end
endmodule
