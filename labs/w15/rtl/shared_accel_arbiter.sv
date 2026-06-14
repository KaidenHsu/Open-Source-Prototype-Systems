`timescale 1ns/1ps

// Week 15 in-class lab starter RTL.
// Student task: replace fixed-priority behavior with a fair policy while
// preserving correctness and useful measurement hooks.
module shared_accel_arbiter #(
    parameter int TAG_W      = 8,
    parameter int OPCODE_W   = 4,
    parameter int LEN_W      = 8,
    parameter int METRIC_W   = 16,
    // 0 = fixed priority baseline, 1 = round-robin TODO, 2 = aging TODO
    parameter int ARB_POLICY = 0,
    parameter int AGE_LIMIT  = 8
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  req0_valid,
    output logic                  req0_ready,
    input  logic [TAG_W-1:0]      req0_tag,
    input  logic [OPCODE_W-1:0]   req0_opcode,
    input  logic [LEN_W-1:0]      req0_len,

    input  logic                  req1_valid,
    output logic                  req1_ready,
    input  logic [TAG_W-1:0]      req1_tag,
    input  logic [OPCODE_W-1:0]   req1_opcode,
    input  logic [LEN_W-1:0]      req1_len,

    output logic                  cmd_valid,
    input  logic                  cmd_ready,
    output logic                  cmd_src,
    output logic [TAG_W-1:0]      cmd_tag,
    output logic [OPCODE_W-1:0]   cmd_opcode,
    output logic [LEN_W-1:0]      cmd_len,

    output logic [METRIC_W-1:0]   grant_count0,
    output logic [METRIC_W-1:0]   grant_count1,
    output logic [METRIC_W-1:0]   max_wait0,
    output logic [METRIC_W-1:0]   max_wait1
);
    localparam logic [METRIC_W-1:0] ONE_METRIC = {{(METRIC_W-1){1'b0}}, 1'b1};
    /* verilator lint_off WIDTHTRUNC */
    localparam logic [METRIC_W-1:0] AGE_LIMIT_SIZED = AGE_LIMIT;
    /* verilator lint_on WIDTHTRUNC */

    logic grant0_sel;
    logic grant1_sel;
    logic last_grant;
    logic [METRIC_W-1:0] cur_wait0;
    logic [METRIC_W-1:0] cur_wait1;

    // helper signals to implement aging arbitration
    logic aged0, aged1;

    // ---------------------------------------------------------------------
    // TODO 1: Replace the ARB_POLICY==1 branch with round-robin arbitration.
    // Hint: when both requesters are valid, grant the requester that was not
    // granted last time. Update last_grant only on an accepted command.
    //
    // TODO 2: Optional challenge for ARB_POLICY==2. Add an aging rule that
    // overrides round-robin when one requester has waited AGE_LIMIT cycles.
    // ---------------------------------------------------------------------
    always_comb begin
        grant0_sel = 1'b0;
        grant1_sel = 1'b0;

        if (ARB_POLICY == 0) begin
            // Baseline: fixed priority favors requester 0.
            if (req0_valid) begin
                grant0_sel = 1'b1;
            end else if (req1_valid) begin
                grant1_sel = 1'b1;
            end
        end else if (ARB_POLICY == 1) begin
            // TODO: implement fair round-robin here.
            if (req0_valid && req1_valid) begin
                // both want the bus =>
                // alternate based on who went last
                grant0_sel = (last_grant == 1'b1);
                grant1_sel = (last_grant == 1'b0);
            end else if (req0_valid) begin
                grant0_sel = 1'b1;
            end else if (req1_valid) begin
                grant1_sel = 1'b1;
            end
        end else begin
            // TODO: implement aging-aware arbitration here.
            aged0 = req0_valid & & (cur_wait0 >= AGE_LIMIT_SIZED);
            aged1 = req1_valid & & (cur_wait1 >= AGE_LIMIT_SIZED);

            if (aged0 && aged1) begin
                // both starved - grant the longer waiter (ties go to req0)
                grant0_sel = (cur_wait0 >= cur_wait1);
                grant1_sel = (cur_wait1 > cur_wait0);
            end else if (aged0) begin
                grant0_sel = 1'b1;
            end else if (aged1) begin
                grant1_sel = 1'b1;
            end else if (req0_valid && req1_valid) begin
                // neither aged - fall back to RR
                grant0_sel = (last_grant == 1'b1);
                grant1_sel = (last_grant == 1'b0);
            end else if (req0_valid) begin
                grant0_sel = 1'b1;
            end else if (req1_valid) begin
                grant1_sel = 1'b1;
            end
        end
    end

    assign cmd_valid  = grant0_sel | grant1_sel;
    assign cmd_src    = grant1_sel;
    assign cmd_tag    = grant1_sel ? req1_tag    : req0_tag;
    assign cmd_opcode = grant1_sel ? req1_opcode : req0_opcode;
    assign cmd_len    = grant1_sel ? req1_len    : req0_len;

    assign req0_ready = cmd_ready & grant0_sel;
    assign req1_ready = cmd_ready & grant1_sel;

    always_ff @(posedge clk) begin
        if (rst) begin
            last_grant   <= 1'b0;
            grant_count0 <= '0;
            grant_count1 <= '0;
            cur_wait0    <= '0;
            cur_wait1    <= '0;
            max_wait0    <= '0;
            max_wait1    <= '0;
        end else begin
            if (cmd_ready && grant0_sel) begin
                last_grant   <= 1'b0;
                grant_count0 <= grant_count0 + ONE_METRIC;
            end
            if (cmd_ready && grant1_sel) begin
                last_grant   <= 1'b1;
                grant_count1 <= grant_count1 + ONE_METRIC;
            end

            if (req0_valid && !req0_ready) begin
                cur_wait0 <= cur_wait0 + ONE_METRIC;
                if ((cur_wait0 + ONE_METRIC) > max_wait0) begin
                    max_wait0 <= cur_wait0 + ONE_METRIC;
                end
            end else begin
                cur_wait0 <= '0;
            end

            if (req1_valid && !req1_ready) begin
                cur_wait1 <= cur_wait1 + ONE_METRIC;
                if ((cur_wait1 + ONE_METRIC) > max_wait1) begin
                    max_wait1 <= cur_wait1 + ONE_METRIC;
                end
            end else begin
                cur_wait1 <= '0;
            end
        end
    end
endmodule
