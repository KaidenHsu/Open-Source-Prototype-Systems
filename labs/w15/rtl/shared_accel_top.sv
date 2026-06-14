`timescale 1ns/1ps

module shared_accel_top #(
    parameter int TAG_W        = 8,
    parameter int OPCODE_W     = 4,
    parameter int LEN_W        = 8,
    parameter int RESULT_W     = 32,
    parameter int METRIC_W     = 16,
    parameter int LANE_LATENCY = 4,
    parameter int ARB_POLICY   = 0,
    parameter int AGE_LIMIT    = 8
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

    output logic                  rsp_valid,
    output logic                  rsp_src,
    output logic [TAG_W-1:0]      rsp_tag,
    output logic [RESULT_W-1:0]   rsp_result,

    output logic [METRIC_W-1:0]   grant_count0,
    output logic [METRIC_W-1:0]   grant_count1,
    output logic [METRIC_W-1:0]   max_wait0,
    output logic [METRIC_W-1:0]   max_wait1
);
    logic                cmd_valid;
    logic                cmd_ready;
    logic                cmd_src;
    logic [TAG_W-1:0]    cmd_tag;
    logic [OPCODE_W-1:0] cmd_opcode;
    logic [LEN_W-1:0]    cmd_len;

    shared_accel_arbiter #(
        .TAG_W(TAG_W),
        .OPCODE_W(OPCODE_W),
        .LEN_W(LEN_W),
        .METRIC_W(METRIC_W),
        .ARB_POLICY(ARB_POLICY),
        .AGE_LIMIT(AGE_LIMIT)
    ) u_arbiter (
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
        .cmd_valid(cmd_valid),
        .cmd_ready(cmd_ready),
        .cmd_src(cmd_src),
        .cmd_tag(cmd_tag),
        .cmd_opcode(cmd_opcode),
        .cmd_len(cmd_len),
        .grant_count0(grant_count0),
        .grant_count1(grant_count1),
        .max_wait0(max_wait0),
        .max_wait1(max_wait1)
    );

    shared_accel_lane #(
        .TAG_W(TAG_W),
        .OPCODE_W(OPCODE_W),
        .LEN_W(LEN_W),
        .RESULT_W(RESULT_W),
        .LANE_LATENCY(LANE_LATENCY)
    ) u_lane (
        .clk(clk),
        .rst(rst),
        .cmd_valid(cmd_valid),
        .cmd_ready(cmd_ready),
        .cmd_src(cmd_src),
        .cmd_tag(cmd_tag),
        .cmd_opcode(cmd_opcode),
        .cmd_len(cmd_len),
        .rsp_valid(rsp_valid),
        .rsp_src(rsp_src),
        .rsp_tag(rsp_tag),
        .rsp_result(rsp_result)
    );
endmodule
