`timescale 1ns/1ps

module shared_memory #(
    parameter AW = 8,
    parameter DW = 32,
    parameter LINE_WORDS = 4
)(
    input  logic clk,
    input  logic reset,

    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [AW-1:0] line_addr,
    /* verilator lint_off UNUSEDSIGNAL */
    output logic [DW*LINE_WORDS-1:0] line_rdata,

    input  logic word_we,
    input  logic [AW-1:0] word_addr,
    input  logic [DW-1:0] word_wdata,

    input  logic word_we1,
    input  logic [AW-1:0] word_addr1,
    input  logic [DW-1:0] word_wdata1,

    output logic [DW-1:0] dbg_mem0,
    output logic [DW-1:0] dbg_mem1,
    output logic [DW-1:0] dbg_mem4,
    output logic [DW-1:0] dbg_mem16,
    output logic [DW-1:0] dbg_mem17,
    output logic [DW-1:0] dbg_mem18,
    output logic [DW-1:0] dbg_mem19,
    output logic [DW-1:0] dbg_mem32,
    output logic [DW-1:0] dbg_mem33,
    output logic [DW-1:0] dbg_mem34,
    output logic [DW-1:0] dbg_mem35
);
    logic [DW-1:0] mem_array [0:(1<<AW)-1];
    integer i;

    always_ff @(posedge clk) begin
        if (reset) begin
            /* verilator lint_off BLKSEQ */
            for (i = 0; i < (1<<AW); i = i + 1)
                mem_array[i] = '0;
            /* verilator lint_on BLKSEQ */
        end else begin
            if (word_we)  mem_array[word_addr]  <= word_wdata;
            if (word_we1) mem_array[word_addr1] <= word_wdata1;
        end
    end

    wire [AW-1:0] base_addr = {line_addr[AW-1:2], 2'b00};

    always_comb begin
        line_rdata = '0;
        line_rdata[0*DW +: DW] = mem_array[base_addr + 0];
        line_rdata[1*DW +: DW] = mem_array[base_addr + 1];
        line_rdata[2*DW +: DW] = mem_array[base_addr + 2];
        line_rdata[3*DW +: DW] = mem_array[base_addr + 3];
    end

    assign dbg_mem0  = mem_array[0];
    assign dbg_mem1  = mem_array[1];
    assign dbg_mem4  = mem_array[4];
    assign dbg_mem16 = mem_array[16];
    assign dbg_mem17 = mem_array[17];
    assign dbg_mem18 = mem_array[18];
    assign dbg_mem19 = mem_array[19];
    assign dbg_mem32 = mem_array[32];
    assign dbg_mem33 = mem_array[33];
    assign dbg_mem34 = mem_array[34];
    assign dbg_mem35 = mem_array[35];
endmodule
