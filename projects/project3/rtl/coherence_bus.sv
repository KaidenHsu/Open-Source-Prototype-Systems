`timescale 1ns/1ps

module coherence_bus #(
    parameter AW = 8
)(
    input  logic clk,
    input  logic reset,

    input  logic        req_valid0,
    input  logic [1:0]  req_cmd0,
    input  logic [AW-1:0] req_line0,
    output logic        grant0,

    input  logic        req_valid1,
    input  logic [1:0]  req_cmd1,
    input  logic [AW-1:0] req_line1,
    output logic        grant1,

    output logic        snoop_valid,
    output logic [1:0]  snoop_cmd,
    output logic [0:0]  snoop_src,
    output logic [AW-1:0] snoop_line,

    output logic [31:0] busrd_count,
    output logic [31:0] busrdx_count
);
    /* verilator lint_off UNUSEDPARAM */
    localparam CMD_NONE  = 2'd0;
    /* verilator lint_on UNUSEDPARAM */
    localparam CMD_BUSRD = 2'd1;
    localparam CMD_BUSRDX = 2'd2;

    // Fixed-priority arbitration: core 0 > core 1
    assign grant0 = req_valid0;
    assign grant1 = req_valid1 && !req_valid0;

    // Broadcast the winning request as a snoop to both caches
    assign snoop_valid = grant0 || grant1;
    assign snoop_cmd   = grant0 ? req_cmd0  : req_cmd1;
    assign snoop_src   = grant0 ? 1'b0      : 1'b1;
    assign snoop_line  = grant0 ? req_line0 : req_line1;

    always_ff @(posedge clk) begin
        if (reset) begin
            busrd_count  <= 32'b0;
            busrdx_count <= 32'b0;
        end else begin
            if (snoop_valid && snoop_cmd == CMD_BUSRD)
                busrd_count  <= busrd_count  + 1;
            if (snoop_valid && snoop_cmd == CMD_BUSRDX)
                busrdx_count <= busrdx_count + 1;
        end
    end
endmodule
