`timescale 1ns/1ps

module tb_shared_accel_arbiter #(
    parameter int TAG_W        = 8,
    parameter int OPCODE_W     = 4,
    parameter int LEN_W        = 8,
    parameter int RESULT_W     = 32,
    parameter int METRIC_W     = 16,
    parameter int LANE_LATENCY = 4,
    parameter int ARB_POLICY   = 0,
    parameter int AGE_LIMIT    = 8,
    parameter int MAX_CMDS     = 256
);
    logic clk;
    logic rst;

    logic req0_valid;
    logic req0_ready;
    logic [TAG_W-1:0] req0_tag;
    logic [OPCODE_W-1:0] req0_opcode;
    logic [LEN_W-1:0] req0_len;

    logic req1_valid;
    logic req1_ready;
    logic [TAG_W-1:0] req1_tag;
    logic [OPCODE_W-1:0] req1_opcode;
    logic [LEN_W-1:0] req1_len;

    logic rsp_valid;
    logic rsp_src;
    logic [TAG_W-1:0] rsp_tag;
    logic [RESULT_W-1:0] rsp_result;

    logic [METRIC_W-1:0] grant_count0;
    logic [METRIC_W-1:0] grant_count1;
    logic [METRIC_W-1:0] max_wait0;
    logic [METRIC_W-1:0] max_wait1;

    int n0;
    int n1;
    int max_cycles;
    int check_fair;
    int fair_max_wait;
    int trace_en;
    int issued0;
    int issued1;
    int completed0;
    int completed1;
    int cycle_count;
    int error_count;
    bit [MAX_CMDS-1:0] seen0;
    bit [MAX_CMDS-1:0] seen1;

    shared_accel_top #(
        .TAG_W(TAG_W),
        .OPCODE_W(OPCODE_W),
        .LEN_W(LEN_W),
        .RESULT_W(RESULT_W),
        .METRIC_W(METRIC_W),
        .LANE_LATENCY(LANE_LATENCY),
        .ARB_POLICY(ARB_POLICY),
        .AGE_LIMIT(AGE_LIMIT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .req0_valid(req0_valid),
        .req0_ready(req0_ready),
        .req0_tag(req0_tag),
        .req0_opcode(req0_opcode),
        .req0_len(req0_len),
        .req1_valid(req1_valid),
        .req1_ready(req1_ready),
        .req1_tag(req1_tag),
        .req1_opcode(req1_opcode),
        .req1_len(req1_len),
        .rsp_valid(rsp_valid),
        .rsp_src(rsp_src),
        .rsp_tag(rsp_tag),
        .rsp_result(rsp_result),
        .grant_count0(grant_count0),
        .grant_count1(grant_count1),
        .max_wait0(max_wait0),
        .max_wait1(max_wait1)
    );

    /* verilator lint_off BLKSEQ */
    always #5 clk = ~clk;
    /* verilator lint_on BLKSEQ */

    function automatic logic [RESULT_W-1:0] expected_result(
        input logic src,
        input logic [TAG_W-1:0] tag,
        input logic [OPCODE_W-1:0] opcode,
        input logic [LEN_W-1:0] len
    );
        logic [RESULT_W-1:0] base;
        begin
            base = src ? 32'h2000_0000 : 32'h1000_0000;
            expected_result = base ^ RESULT_W'(tag) ^ (RESULT_W'(opcode) << 4) ^ RESULT_W'(len);
        end
    endfunction

    function automatic logic [OPCODE_W-1:0] make_opcode(input int src, input int idx);
        begin
            make_opcode = OPCODE_W'((src + 1) ^ (idx & 32'h7));
        end
    endfunction

    function automatic logic [LEN_W-1:0] make_len(input int src, input int idx);
        begin
            make_len = LEN_W'(8 + src + (idx % 13));
        end
    endfunction

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        n0 = 32;
        n1 = 32;
        max_cycles = 1000;
        check_fair = 0;
        fair_max_wait = 32;
        trace_en = 0;
        issued0 = 0;
        issued1 = 0;
        completed0 = 0;
        completed1 = 0;
        cycle_count = 0;
        error_count = 0;
        seen0 = '0;
        seen1 = '0;
        req0_valid = 1'b0;
        req0_tag = '0;
        req0_opcode = '0;
        req0_len = '0;
        req1_valid = 1'b0;
        req1_tag = '0;
        req1_opcode = '0;
        req1_len = '0;

        void'($value$plusargs("N0=%d", n0));
        void'($value$plusargs("N1=%d", n1));
        void'($value$plusargs("MAX_CYCLES=%d", max_cycles));
        void'($value$plusargs("CHECK_FAIR=%d", check_fair));
        void'($value$plusargs("FAIR_MAX_WAIT=%d", fair_max_wait));
        void'($value$plusargs("TRACE=%d", trace_en));

        if (n0 > MAX_CMDS || n1 > MAX_CMDS) begin
            $display("ERROR requested command count exceeds MAX_CMDS=%0d", MAX_CMDS);
            $fatal;
        end

        if (trace_en != 0) begin
            $dumpfile("waves/shared_accel_arbiter.vcd");
            $dumpvars(0, tb_shared_accel_arbiter);
        end

        repeat (5) @(posedge clk);
        rst = 1'b0;
    end

    // FSMs for two core drivers
    always_ff @(posedge clk) begin
        if (rst) begin
            issued0 <= 0;
            issued1 <= 0;
            req0_valid <= 1'b0;
            req1_valid <= 1'b0;
        end else begin
            if (!req0_valid && issued0 < n0) begin // issue another request
                req0_valid <= 1'b1;
                req0_tag <= TAG_W'(issued0);
                req0_opcode <= make_opcode(0, issued0);
                req0_len <= make_len(0, issued0);
            end else if (req0_valid && req0_ready) begin // handshake accepted
                issued0 <= issued0 + 1;
                if ((issued0 + 1) < n0) begin
                    req0_valid <= 1'b1;
                    req0_tag <= TAG_W'(issued0 + 1);
                    req0_opcode <= make_opcode(0, issued0 + 1);
                    req0_len <= make_len(0, issued0 + 1);
                end else begin
                    req0_valid <= 1'b0;
                end
            end

            if (!req1_valid && issued1 < n1) begin // issue another request
                req1_valid <= 1'b1;
                req1_tag <= TAG_W'(issued1);
                req1_opcode <= make_opcode(1, issued1);
                req1_len <= make_len(1, issued1);
            end else if (req1_valid && req1_ready) begin // handshake accepted
                issued1 <= issued1 + 1;
                if ((issued1 + 1) < n1) begin
                    req1_valid <= 1'b1;
                    req1_tag <= TAG_W'(issued1 + 1);
                    req1_opcode <= make_opcode(1, issued1 + 1);
                    req1_len <= make_len(1, issued1 + 1);
                end else begin
                    req1_valid <= 1'b0;
                end
            end
        end
    end

    // determine response values
    // cyle, error counts
    always_ff @(posedge clk) begin
        if (rst) begin
            completed0 <= 0;
            completed1 <= 0;
            error_count <= 0;
            cycle_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;

            if (rsp_valid) begin
                if (rsp_src == 1'b0) begin
                    if (seen0[rsp_tag]) begin
                        $display("ERROR duplicate response src=0 tag=%0d", rsp_tag);
                        error_count <= error_count + 1;
                    end
                    seen0[rsp_tag] <= 1'b1;
                    completed0 <= completed0 + 1;
                    if (rsp_result != expected_result(1'b0, rsp_tag, make_opcode(0, int'(rsp_tag)), make_len(0, int'(rsp_tag)))) begin
                        $display("ERROR bad result src=0 tag=%0d got=0x%08x", rsp_tag, rsp_result);
                        error_count <= error_count + 1;
                    end
                end else begin
                    if (seen1[rsp_tag]) begin
                        $display("ERROR duplicate response src=1 tag=%0d", rsp_tag);
                        error_count <= error_count + 1;
                    end
                    seen1[rsp_tag] <= 1'b1;
                    completed1 <= completed1 + 1;
                    if (rsp_result != expected_result(1'b1, rsp_tag, make_opcode(1, int'(rsp_tag)), make_len(1, int'(rsp_tag)))) begin
                        $display("ERROR bad result src=1 tag=%0d got=0x%08x", rsp_tag, rsp_result);
                        error_count <= error_count + 1;
                    end
                end
            end

            if ((completed0 == n0) && (completed1 == n1)) begin
                $display("METRIC policy=%0d", ARB_POLICY);
                $display("METRIC cycles=%0d", cycle_count);
                $display("METRIC issued0=%0d", issued0);
                $display("METRIC issued1=%0d", issued1);
                $display("METRIC completed0=%0d", completed0);
                $display("METRIC completed1=%0d", completed1);
                $display("METRIC grants0=%0d", grant_count0);
                $display("METRIC grants1=%0d", grant_count1);
                $display("METRIC max_wait0=%0d", max_wait0);
                $display("METRIC max_wait1=%0d", max_wait1);

                if (error_count == 0) begin
                    $display("PASS correctness");
                end else begin
                    $display("FAIL correctness errors=%0d", error_count);
                    $fatal;
                end

                if (check_fair != 0) begin
                    if ((int'(max_wait0) <= fair_max_wait) && (int'(max_wait1) <= fair_max_wait)) begin
                        $display("PASS fairness max_wait_limit=%0d", fair_max_wait);
                    end else begin
                        $display("FAIL fairness max_wait_limit=%0d", fair_max_wait);
                    end
                end else begin
                    $display("NOTE fairness check disabled; inspect max_wait0 and max_wait1");
                end
                $finish;
            end

            if (cycle_count > max_cycles) begin
                $display("FAIL timeout cycle=%0d completed0=%0d completed1=%0d", cycle_count, completed0, completed1);
                $fatal;
            end
        end
    end
endmodule
