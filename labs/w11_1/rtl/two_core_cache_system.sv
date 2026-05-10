`timescale 1ns/1ps

module two_core_cache_system #(
    parameter int ADDR_W = 8,
    parameter int DATA_W = 32,
    parameter int CACHE_LINES = 4,
    parameter int LAB_VARIANT = 0
)(
    input  logic clk,
    input  logic rst_n,

    input  logic              c0_valid,
    input  logic              c0_we,
    input  logic [ADDR_W-1:0] c0_addr,
    input  logic [DATA_W-1:0] c0_wdata,
    output logic              c0_ready,
    output logic [DATA_W-1:0] c0_rdata,
    output logic              c0_hit,

    input  logic              c1_valid,
    input  logic              c1_we,
    input  logic [ADDR_W-1:0] c1_addr,
    input  logic [DATA_W-1:0] c1_wdata,
    output logic              c1_ready,
    output logic [DATA_W-1:0] c1_rdata,
    output logic              c1_hit,

    // here 0 and 1 are invalidate targets
    output logic              dbg_inv0,
    output logic              dbg_inv1,

    output logic [DATA_W-1:0] dbg_mem_c0_addr,
    output logic [DATA_W-1:0] dbg_mem_c1_addr
);
    localparam int IDX_W = $clog2(CACHE_LINES);
    localparam int WORD_BITS = 2;
    localparam int TAG_W = ADDR_W - WORD_BITS - IDX_W;
    localparam int MEM_WORDS = 1 << (ADDR_W - WORD_BITS);

    typedef struct packed {
        logic valid;
        logic [TAG_W-1:0] tag;
        logic [DATA_W-1:0] data;
    } cache_line_t;

    cache_line_t c0_cache [CACHE_LINES];
    cache_line_t c1_cache [CACHE_LINES];
    logic [DATA_W-1:0] mem [MEM_WORDS];

    wire [IDX_W-1:0] c0_idx = c0_addr[WORD_BITS +: IDX_W];
    wire [IDX_W-1:0] c1_idx = c1_addr[WORD_BITS +: IDX_W];
    wire [TAG_W-1:0] c0_tag = c0_addr[ADDR_W-1 -: TAG_W];
    wire [TAG_W-1:0] c1_tag = c1_addr[ADDR_W-1 -: TAG_W];
    wire [ADDR_W-WORD_BITS-1:0] c0_word = c0_addr[ADDR_W-1:WORD_BITS];
    wire [ADDR_W-WORD_BITS-1:0] c1_word = c1_addr[ADDR_W-1:WORD_BITS];

    function automatic logic same_line(input logic [ADDR_W-1:0] a, input logic [ADDR_W-1:0] b);
        same_line = (a[ADDR_W-1:WORD_BITS] == b[ADDR_W-1:WORD_BITS]);
    endfunction

    function automatic logic line_addr_matches_cache(input cache_line_t line, input logic [TAG_W-1:0] tag);
        // if (LAB_VARIANT == 2) begin
        //     line_addr_matches_cache = line.valid;
        // end else begin
            line_addr_matches_cache = line.valid && (line.tag == tag);
        // end
    endfunction

    integer i;
    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            mem[i] = 32'h1000_0000 + i;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c0_ready <= 1'b0;
            c1_ready <= 1'b0;
            c0_rdata <= '0;
            c1_rdata <= '0;
            c0_hit <= 1'b0;
            c1_hit <= 1'b0;
            dbg_inv0 <= 1'b0;
            dbg_inv1 <= 1'b0;
            dbg_mem_c0_addr <= '0;
            dbg_mem_c1_addr <= '0;
            for (i = 0; i < CACHE_LINES; i = i + 1) begin
                c0_cache[i].valid <= 1'b0;
                c0_cache[i].tag <= '0;
                c0_cache[i].data <= '0;
                c1_cache[i].valid <= 1'b0;
                c1_cache[i].tag <= '0;
                c1_cache[i].data <= '0;
            end
        end else begin
            c0_ready <= c0_valid;
            c1_ready <= c1_valid;
            dbg_inv0 <= 1'b0;
            dbg_inv1 <= 1'b0;
            dbg_mem_c0_addr <= mem[c0_word];
            dbg_mem_c1_addr <= mem[c1_word];

            c0_hit <= c0_valid && line_addr_matches_cache(c0_cache[c0_idx], c0_tag);
            c1_hit <= c1_valid && line_addr_matches_cache(c1_cache[c1_idx], c1_tag);

            // Core 0 transaction
            if (c0_valid) begin
                if (c0_we) begin
                    mem[c0_word] <= c0_wdata;
                    c0_cache[c0_idx].valid <= 1'b1;
                    c0_cache[c0_idx].tag <= c0_tag;
                    c0_cache[c0_idx].data <= c0_wdata;
                    c0_rdata <= c0_wdata;
                    // if (LAB_VARIANT != 1) begin
                        if (c1_cache[c0_idx].valid && (c1_cache[c0_idx].tag == c0_tag)) begin
                            // if (!(LAB_VARIANT == 3 && c1_valid)) begin
                                c1_cache[c0_idx].valid <= 1'b0;
                                dbg_inv1 <= 1'b1;
                            // end
                        end
                    // end
                end else begin
                    if (line_addr_matches_cache(c0_cache[c0_idx], c0_tag)) begin
                        c0_rdata <= c0_cache[c0_idx].data;
                    end else begin
                        c0_cache[c0_idx].valid <= 1'b1;
                        c0_cache[c0_idx].tag <= c0_tag;
                        c0_cache[c0_idx].data <= mem[c0_word];
                        c0_rdata <= mem[c0_word];
                    end
                end
            end

            // Core 1 transaction
            if (c1_valid) begin
                if (c1_we) begin
                    mem[c1_word] <= c1_wdata;
                    c1_cache[c1_idx].valid <= 1'b1;
                    c1_cache[c1_idx].tag <= c1_tag;
                    c1_cache[c1_idx].data <= c1_wdata;
                    c1_rdata <= c1_wdata;
                    // if (LAB_VARIANT != 1) begin
                        if (c0_cache[c1_idx].valid && (c0_cache[c1_idx].tag == c1_tag)) begin
                            // if (!(LAB_VARIANT == 3 && c0_valid)) begin
                                c0_cache[c1_idx].valid <= 1'b0;
                                dbg_inv0 <= 1'b1;
                            // end
                        end
                    // end
                end else begin
                    if (line_addr_matches_cache(c1_cache[c1_idx], c1_tag)) begin
                        c1_rdata <= c1_cache[c1_idx].data;
                    end else begin
                        c1_cache[c1_idx].valid <= 1'b1;
                        c1_cache[c1_idx].tag <= c1_tag;
                        c1_cache[c1_idx].data <= mem[c1_word];
                        c1_rdata <= mem[c1_word];
                    end
                end
            end
        end
    end

    // Classroom invariant checks used by the baseline build. Students add extra checks during the lab.
    property c0_write_invalidates_c1;
        @(posedge clk) disable iff (!rst_n)
        (c0_valid && c0_we && c1_cache[c0_idx].valid && (c1_cache[c0_idx].tag == c0_tag)) |=>
        (!c1_cache[$past(c0_idx)].valid || (LAB_VARIANT != 0));
    endproperty

    property c1_write_invalidates_c0;
        @(posedge clk) disable iff (!rst_n)
        (c1_valid && c1_we && c0_cache[c1_idx].valid && (c0_cache[c1_idx].tag == c1_tag)) |=>
        (!c0_cache[$past(c1_idx)].valid || (LAB_VARIANT != 0));
    endproperty

    assert property (c0_write_invalidates_c1)
        else $error("CONTRACT CHECK FAILED: peer cache state remained readable after a write");
    assert property (c1_write_invalidates_c0)
        else $error("CONTRACT CHECK FAILED: peer cache state remained readable after a write");

    // F1: Core 0 must not report a hit for a line identity mismatch.
    property c0_hit_requires_line_identity;
        @(posedge clk) disable iff (!rst_n)
        (c0_valid && !c0_we) |-> (!c0_hit || (c0_cache[c0_idx].valid && c0_cache[c0_idx].tag == c0_tag));
    endproperty

    // F2: Core 1 must not report a hit for a line identity mismatch.
    property c1_hit_requires_line_identity;
        @(posedge clk) disable iff (!rst_n)
        (c1_valid && !c1_we) |-> (!c1_hit || (c1_cache[c1_idx].valid && c1_cache[c1_idx].tag == c1_tag));
    endproperty

    // F3: A Core 0 write to a shared line must make Core 1's stale copy unreadable.
    property c0_write_blocks_c1_stale_copy;
        @(posedge clk) disable iff (!rst_n)
        (c0_valid && c0_we && c1_cache[c0_idx].valid && (c1_cache[c0_idx].tag == c0_tag)) |=>
        (!c1_cache[$past(c0_idx)].valid || (c1_cache[$past(c0_idx)].tag != $past(c0_tag)));
    endproperty

    // F4: A Core 1 write to a shared line must make Core 0's stale copy unreadable.
    property c1_write_blocks_c0_stale_copy;
        @(posedge clk) disable iff (!rst_n)
        (c1_valid && c1_we && c0_cache[c1_idx].valid && (c0_cache[c1_idx].tag == c1_tag)) |=>
        (!c0_cache[$past(c1_idx)].valid || (c0_cache[$past(c1_idx)].tag != $past(c1_tag)));
    endproperty

    // F5a: If C0 reads while C1 writes the same line in the same cycle, C0 must not keep stale line state.
    property c0_read_c1_write_same_cycle_visibility;
        @(posedge clk) disable iff (!rst_n)
        (c0_valid && !c0_we && c1_valid && c1_we && same_line(c0_addr, c1_addr)) |=>
        (!c0_cache[$past(c0_idx)].valid ||
         (c0_cache[$past(c0_idx)].tag != $past(c0_tag)) ||
         (c0_cache[$past(c0_idx)].data == $past(c1_wdata)));
    endproperty

    // F5b: If C1 reads while C0 writes the same line in the same cycle, C1 must not keep stale line state.
    property c1_read_c0_write_same_cycle_visibility;
        @(posedge clk) disable iff (!rst_n)
        (c1_valid && !c1_we && c0_valid && c0_we && same_line(c1_addr, c0_addr)) |=>
        (!c1_cache[$past(c1_idx)].valid ||
         (c1_cache[$past(c1_idx)].tag != $past(c1_tag)) ||
         (c1_cache[$past(c1_idx)].data == $past(c0_wdata)));
    endproperty

    assert property (c0_hit_requires_line_identity)
        else $error("ASSERTION F1 FAILED: Core 0 reported hit without matching line identity");
    assert property (c1_hit_requires_line_identity)
        else $error("ASSERTION F2 FAILED: Core 1 reported hit without matching line identity");
    assert property (c0_write_blocks_c1_stale_copy)
        else $error("ASSERTION F3 FAILED: Core 1 retained readable stale copy after Core 0 write");
    assert property (c1_write_blocks_c0_stale_copy)
        else $error("ASSERTION F4 FAILED: Core 0 retained readable stale copy after Core 1 write");
    assert property (c0_read_c1_write_same_cycle_visibility)
        else $error("ASSERTION F5 FAILED: Core 0 same-cycle read/write interaction lost visibility");
    assert property (c1_read_c0_write_same_cycle_visibility)
        else $error("ASSERTION F5 FAILED: Core 1 same-cycle read/write interaction lost visibility");

endmodule
