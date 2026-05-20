`timescale 1ns/1ps

module project3_top #(
    parameter VARIANT = 0,
    parameter ITERATIONS = 16,
    parameter AW = 8,
    parameter DW = 32,
    parameter LINE_WORDS = 4,
    parameter LINES = 8
)(
    input  logic clk,
    input  logic reset,

    output logic done0,
    output logic done1,

    output logic [31:0] cycles,
    output logic [31:0] c0_hits,
    output logic [31:0] c0_misses,
    output logic [31:0] c0_invalidations,
    output logic [31:0] c0_upgrades,
    output logic [31:0] c1_hits,
    output logic [31:0] c1_misses,
    output logic [31:0] c1_invalidations,
    output logic [31:0] c1_upgrades,
    output logic [31:0] bus_busrd,
    output logic [31:0] bus_busrdx,

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
    // localparam CMD_NONE  = 2'd0;
    // localparam CMD_BUSRD = 2'd1;
    // localparam CMD_BUSRDX = 2'd2;

    logic c0_req_valid, c0_req_write, c0_req_ready;
    logic [AW-1:0] c0_req_addr;
    logic [DW-1:0] c0_req_wdata, c0_resp_rdata;
    logic c1_req_valid, c1_req_write, c1_req_ready;
    logic [AW-1:0] c1_req_addr;
    logic [DW-1:0] c1_req_wdata, c1_resp_rdata;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [31:0] c0_ops, c1_ops;
    /* verilator lint_on UNUSEDSIGNAL */

    logic b_req_valid0, b_req_valid1;
    logic [1:0] b_req_cmd0, b_req_cmd1;
    logic [AW-1:0] b_req_line0, b_req_line1;
    logic b_grant0, b_grant1;
    logic snoop_valid;
    logic [1:0] snoop_cmd;
    logic [0:0] snoop_src;
    logic [AW-1:0] snoop_line;

    logic [AW-1:0] mem_line_addr;
    logic [DW*LINE_WORDS-1:0] mem_line_rdata;
    logic mem_word_we0, mem_word_we1;
    logic [AW-1:0] mem_word_addr0, mem_word_addr1;
    logic [DW-1:0] mem_word_wdata0, mem_word_wdata1;

    always_ff @(posedge clk) begin
        if (reset) cycles <= 0;
        else if (!(done0 && done1)) cycles <= cycles + 1;
    end

    core_driver #(.CORE_ID(0), .VARIANT(VARIANT), .ITERATIONS(ITERATIONS), .AW(AW), .DW(DW)) core0 (
        .clk(clk), .reset(reset), .req_valid(c0_req_valid), .req_write(c0_req_write), .req_addr(c0_req_addr),
        .req_wdata(c0_req_wdata), .req_ready(c0_req_ready), .resp_rdata(c0_resp_rdata), .done(done0), .op_count(c0_ops)
    );

    core_driver #(.CORE_ID(1), .VARIANT(VARIANT), .ITERATIONS(ITERATIONS), .AW(AW), .DW(DW)) core1 (
        .clk(clk), .reset(reset), .req_valid(c1_req_valid), .req_write(c1_req_write), .req_addr(c1_req_addr),
        .req_wdata(c1_req_wdata), .req_ready(c1_req_ready), .resp_rdata(c1_resp_rdata), .done(done1), .op_count(c1_ops)
    );

    msi_cache #(.CORE_ID(0), .AW(AW), .DW(DW), .LINE_WORDS(LINE_WORDS), .LINES(LINES)) cache0 (
        .clk(clk), .reset(reset), .cpu_req_valid(c0_req_valid), .cpu_req_write(c0_req_write), .cpu_req_addr(c0_req_addr),
        .cpu_req_wdata(c0_req_wdata), .cpu_req_ready(c0_req_ready), .cpu_resp_rdata(c0_resp_rdata),
        .bus_req_valid(b_req_valid0), .bus_req_cmd(b_req_cmd0), .bus_req_line(b_req_line0), .bus_grant(b_grant0),
        .snoop_valid(snoop_valid), .snoop_cmd(snoop_cmd), .snoop_src(snoop_src), .snoop_line(snoop_line),
        .mem_line_rdata(mem_line_rdata), .mem_word_we(mem_word_we0), .mem_word_addr(mem_word_addr0), .mem_word_wdata(mem_word_wdata0),
        .done(done0),
        .hit_count(c0_hits), .miss_count(c0_misses), .invalidation_count(c0_invalidations), .upgrade_count(c0_upgrades)
    );

    msi_cache #(.CORE_ID(1), .AW(AW), .DW(DW), .LINE_WORDS(LINE_WORDS), .LINES(LINES)) cache1 (
        .clk(clk), .reset(reset), .cpu_req_valid(c1_req_valid), .cpu_req_write(c1_req_write), .cpu_req_addr(c1_req_addr),
        .cpu_req_wdata(c1_req_wdata), .cpu_req_ready(c1_req_ready), .cpu_resp_rdata(c1_resp_rdata),
        .bus_req_valid(b_req_valid1), .bus_req_cmd(b_req_cmd1), .bus_req_line(b_req_line1), .bus_grant(b_grant1),
        .snoop_valid(snoop_valid), .snoop_cmd(snoop_cmd), .snoop_src(snoop_src), .snoop_line(snoop_line),
        .mem_line_rdata(mem_line_rdata), .mem_word_we(mem_word_we1), .mem_word_addr(mem_word_addr1), .mem_word_wdata(mem_word_wdata1),
        .done(done1),
        .hit_count(c1_hits), .miss_count(c1_misses), .invalidation_count(c1_invalidations), .upgrade_count(c1_upgrades)
    );

    coherence_bus #(.AW(AW)) bus (
        .clk(clk), .reset(reset),
        .req_valid0(b_req_valid0), .req_cmd0(b_req_cmd0), .req_line0(b_req_line0), .grant0(b_grant0),
        .req_valid1(b_req_valid1), .req_cmd1(b_req_cmd1), .req_line1(b_req_line1), .grant1(b_grant1),
        .snoop_valid(snoop_valid), .snoop_cmd(snoop_cmd), .snoop_src(snoop_src), .snoop_line(snoop_line),
        .busrd_count(bus_busrd), .busrdx_count(bus_busrdx)
    );

    assign mem_line_addr = snoop_valid ? snoop_line : 0;

    shared_memory #(.AW(AW), .DW(DW), .LINE_WORDS(LINE_WORDS)) memory (
        .clk(clk), .reset(reset), .line_addr(mem_line_addr), .line_rdata(mem_line_rdata),
        .word_we(mem_word_we0), .word_addr(mem_word_addr0), .word_wdata(mem_word_wdata0),
        .word_we1(mem_word_we1), .word_addr1(mem_word_addr1), .word_wdata1(mem_word_wdata1),
        .dbg_mem0(dbg_mem0), .dbg_mem1(dbg_mem1), .dbg_mem4(dbg_mem4),
        .dbg_mem16(dbg_mem16), .dbg_mem17(dbg_mem17), .dbg_mem18(dbg_mem18), .dbg_mem19(dbg_mem19),
        .dbg_mem32(dbg_mem32), .dbg_mem33(dbg_mem33), .dbg_mem34(dbg_mem34), .dbg_mem35(dbg_mem35)
    );
endmodule
