`timescale 1ns/1ps

// Fixed-latency single-issue accelerator lane used by the Week 15 lab.
// The lane accepts one command at a time and returns a deterministic response.
module shared_accel_lane #(
    parameter int TAG_W        = 8,
    parameter int OPCODE_W     = 4,
    parameter int LEN_W        = 8,
    parameter int RESULT_W     = 32,
    parameter int LANE_LATENCY = 4
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  cmd_valid,
    output logic                  cmd_ready,
    input  logic                  cmd_src,
    input  logic [TAG_W-1:0]      cmd_tag,
    input  logic [OPCODE_W-1:0]   cmd_opcode,
    input  logic [LEN_W-1:0]      cmd_len,

    output logic                  rsp_valid,
    output logic                  rsp_src,
    output logic [TAG_W-1:0]      rsp_tag,
    output logic [RESULT_W-1:0]   rsp_result
);
    localparam int CNT_W = (LANE_LATENCY <= 1) ? 1 : $clog2(LANE_LATENCY + 1);

    logic                busy;
    logic [CNT_W-1:0]    remaining;
    logic                saved_src;
    logic [TAG_W-1:0]    saved_tag;
    logic [OPCODE_W-1:0] saved_opcode;
    logic [LEN_W-1:0]    saved_len;

    assign cmd_ready = !busy;

    function automatic logic [RESULT_W-1:0] make_result(
        input logic src,
        input logic [TAG_W-1:0] tag,
        input logic [OPCODE_W-1:0] opcode,
        input logic [LEN_W-1:0] len
    );
        logic [RESULT_W-1:0] base;
        begin
            base = src ? 32'h2000_0000 : 32'h1000_0000;
            make_result = base ^ RESULT_W'(tag) ^ (RESULT_W'(opcode) << 4) ^ RESULT_W'(len);
        end
    endfunction

    always_ff @(posedge clk) begin
        if (rst) begin
            busy         <= 1'b0;
            remaining    <= '0;
            saved_src    <= 1'b0;
            saved_tag    <= '0;
            saved_opcode <= '0;
            saved_len    <= '0;
            rsp_valid    <= 1'b0;
            rsp_src      <= 1'b0;
            rsp_tag      <= '0;
            rsp_result   <= '0;
        end else begin
            rsp_valid <= 1'b0;

            if (busy) begin
                if (remaining == '0) begin
                    rsp_valid  <= 1'b1;
                    rsp_src    <= saved_src;
                    rsp_tag    <= saved_tag;
                    rsp_result <= make_result(saved_src, saved_tag, saved_opcode, saved_len);
                    busy       <= 1'b0;
                end else begin
                    remaining <= remaining - {{(CNT_W-1){1'b0}}, 1'b1};
                end
            end else if (cmd_valid) begin
                busy         <= 1'b1;
                remaining    <= CNT_W'(LANE_LATENCY - 1);
                saved_src    <= cmd_src;
                saved_tag    <= cmd_tag;
                saved_opcode <= cmd_opcode;
                saved_len    <= cmd_len;
            end
        end
    end
endmodule
