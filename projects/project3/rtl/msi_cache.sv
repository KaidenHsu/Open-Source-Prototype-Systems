`timescale 1ns/1ps

module msi_cache #(
    parameter CORE_ID = 0,
    parameter AW = 8,
    parameter DW = 32,
    parameter LINE_WORDS = 4,
    parameter LINES = 8
)(
    input  logic clk,
    input  logic reset,

    input  logic        cpu_req_valid,
    input  logic        cpu_req_write,
    input  logic [AW-1:0] cpu_req_addr,
    input  logic [DW-1:0] cpu_req_wdata,
    output logic        cpu_req_ready,
    output logic [DW-1:0] cpu_resp_rdata,

    output logic        bus_req_valid,
    output logic [1:0]  bus_req_cmd,
    output logic [AW-1:0] bus_req_line,
    input  logic        bus_grant,

    input  logic        snoop_valid,
    input  logic [1:0]  snoop_cmd,
    input  logic [0:0]  snoop_src,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [AW-1:0] snoop_line,
    /* verilator lint_off UNUSEDSIGNAL */

    input  logic [DW*LINE_WORDS-1:0] mem_line_rdata,

    output logic        mem_word_we,
    output logic [AW-1:0] mem_word_addr,
    output logic [DW-1:0] mem_word_wdata,

    input  logic        done,

    output logic [31:0] hit_count,
    output logic [31:0] miss_count,
    output logic [31:0] invalidation_count,
    output logic [31:0] upgrade_count
);
    localparam CMD_NONE  = 2'd0;
    localparam CMD_BUSRD = 2'd1;
    localparam CMD_BUSRDX = 2'd2;

    localparam WORD_OFFSET_WIDTH = $clog2(LINE_WORDS);
    localparam INDEX_WIDTH       = $clog2(LINES);
    localparam TAG_WIDTH         = AW - WORD_OFFSET_WIDTH - INDEX_WIDTH;

    // address decode
    logic [TAG_WIDTH-1 : 0]         tag;
    logic [INDEX_WIDTH-1 : 0]       index;
    logic [WORD_OFFSET_WIDTH-1 : 0] word_offset;

    logic hit;

    int i, k;

    // Performance counter signals
    logic hit_this_cycle, miss_this_cycle, upgrade_this_cycle, invalidation_this_cycle;

    // FSM: 5 states → 3 bits
    typedef enum logic [2:0] {
        IDLE, PENDING_MISS, PENDING_UPGRADE, FILL_LINE, WRITEBACK
    } fsm_state_t;
    fsm_state_t state, next_state;

    // pending request
    logic [TAG_WIDTH-1:0]          pending_tag;
    logic [INDEX_WIDTH-1:0]        pending_index;
    logic [WORD_OFFSET_WIDTH-1:0]  pending_word_offset;
    logic                          pending_write;
    logic [DW-1:0]                 pending_wdata;

    // writeback registers
    logic [$clog2(LINE_WORDS)-1:0] wb_word_cnt;
    logic [INDEX_WIDTH-1:0]        wb_index;
    logic                          wb_post_invalidate; // 1=invalidate, 0=downgrade to S
    logic                          wb_then_fill;       // 1=proceed to PENDING_MISS after WB

    // snoop address decode
    logic [INDEX_WIDTH-1:0]        snp_idx;
    logic [TAG_WIDTH-1:0]          snp_tag;
    logic                          snoop_hits_m;

    logic                          done_flush_found;
    logic [INDEX_WIDTH-1:0]        done_flush_idx;

    // MSI state and cache line types
    typedef enum logic [1:0] { STATE_I, STATE_S, STATE_M } msi_state_t;

    typedef struct packed {
        logic valid;
        logic dirty;
        msi_state_t msi_state;
        logic [TAG_WIDTH-1 : 0] tag;
        logic [DW*LINE_WORDS-1:0] data;
    } cache_line_t;

    cache_line_t cache [0 : LINES-1];

    initial begin
        for (i = 0; i < LINES; i++) begin
            cache[i] = '0;
        end
    end

    // address decode
    always_comb begin
        word_offset = cpu_req_addr[0 +: WORD_OFFSET_WIDTH];
        index       = cpu_req_addr[WORD_OFFSET_WIDTH +: INDEX_WIDTH];
        tag         = cpu_req_addr[(WORD_OFFSET_WIDTH+INDEX_WIDTH) +: TAG_WIDTH];
    end

    assign hit = (cache[index].valid && cache[index].msi_state != STATE_I && cache[index].tag == tag);

    // snoop address decode + M-state hit detection
    always_comb begin
        snp_idx      = snoop_line[WORD_OFFSET_WIDTH +: INDEX_WIDTH];
        snp_tag      = snoop_line[(WORD_OFFSET_WIDTH+INDEX_WIDTH) +: TAG_WIDTH];
        snoop_hits_m = snoop_valid && snoop_src != CORE_ID[0] &&
                       cache[snp_idx].valid && cache[snp_idx].tag == snp_tag &&
                       cache[snp_idx].msi_state == STATE_M;
    end

    // done-flush scan: find first dirty M-state line
    always_comb begin
        done_flush_found = 1'b0;
        done_flush_idx   = '0;

        for (k = 0; k < LINES; k++) begin
            if (!done_flush_found && cache[k].valid && cache[k].msi_state == STATE_M) begin
                done_flush_found = 1'b1;
                done_flush_idx   = k[INDEX_WIDTH-1:0];
            end
        end
    end

    // -------------------------------
    //     cache controller FSM
    // -------------------------------

    always_ff @(posedge clk) begin
        if (reset) state <= IDLE;
        else       state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (snoop_hits_m) begin // snoop on M-line
                    next_state = WRITEBACK;
                end else if (cpu_req_valid && !hit && cache[index].valid
                    && cache[index].msi_state == STATE_M) begin // conflict evict dirty line first
                    next_state = WRITEBACK;
                end else if (!cpu_req_valid && done && done_flush_found) begin // flush dirty private lines on done
                    next_state = WRITEBACK;
                end else if (cpu_req_valid) begin
                    if (hit && cpu_req_write && cache[index].msi_state == STATE_S)
                        next_state = PENDING_UPGRADE;
                    else if (!hit)
                        next_state = PENDING_MISS;
                end
            end
            PENDING_MISS, PENDING_UPGRADE: begin
                if (bus_grant) next_state = FILL_LINE;
            end
            FILL_LINE: next_state = IDLE;
            WRITEBACK: begin
                /* verilator lint_off WIDTHEXPAND */
                if (wb_word_cnt == LINE_WORDS - 1)
                /* verilator lint_on WIDTHEXPAND */
                    next_state = wb_then_fill ? PENDING_MISS : IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // -------------------------------
    //        buffered signals
    // -------------------------------

    // pending request capture
    always_ff @(posedge clk) begin
        if (reset) begin
            pending_tag         <= '0;
            pending_index       <= '0;
            pending_word_offset <= '0;
            pending_write       <= 1'b0;
            pending_wdata       <= '0;
        end else begin
            if (cpu_req_valid && (!hit || (cpu_req_write && cache[index].msi_state == STATE_S))) begin
                pending_tag         <= tag;
                pending_index       <= index;
                pending_word_offset <= word_offset;
                pending_write       <= cpu_req_write;
                pending_wdata       <= cpu_req_wdata;
            end
        end
    end

    // writeback
    always_ff @(posedge clk) begin
        if (reset) begin
            wb_word_cnt        <= '0;
            wb_index           <= '0;
            wb_post_invalidate <= 1'b0;
            wb_then_fill       <= 1'b0;
        end else begin
            // ---- capture wb registers when entering WRITEBACK from IDLE ----
            if (state == IDLE && (snoop_hits_m || (cpu_req_valid && !hit && cache[index].valid &&
                cache[index].msi_state == STATE_M) || (!cpu_req_valid && done && done_flush_found))) begin

                wb_word_cnt <= '0;

                if (snoop_hits_m) begin
                    wb_index          <= snp_idx;
                    wb_post_invalidate <= (snoop_cmd == CMD_BUSRDX);
                    wb_then_fill      <= 1'b0;
                end else if (!cpu_req_valid && done && done_flush_found) begin
                    wb_index          <= done_flush_idx;
                    wb_post_invalidate <= 1'b1;
                    wb_then_fill      <= 1'b0;
                end else begin // conflict evict
                    wb_index          <= index;
                    wb_post_invalidate <= 1'b1;
                    wb_then_fill      <= 1'b1;
                end
            end

            // ---- writeback: drain one word per cycle ----
            if (state == WRITEBACK) begin
                /* verilator lint_off WIDTHEXPAND */
                wb_word_cnt <= wb_word_cnt + 1;

                if (wb_word_cnt == LINE_WORDS - 1) begin
                /* verilator lint_on WIDTHEXPAND */
                    cache[wb_index].dirty <= 1'b0;

                    if (wb_post_invalidate) cache[wb_index].valid <= 1'b0;
                    else cache[wb_index].msi_state <= STATE_S;
                end
            end
        end
    end

    // -------------------------------
    //          cache line
    // -------------------------------

    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < LINES; i++) begin
                cache[i].msi_state <= STATE_I;
                cache[i].tag       <= '0;
                cache[i].valid     <= 1'b0;
                cache[i].dirty     <= 1'b0;
                cache[i].data      <= '0;
            end
        end else begin
            // ---- Core side: write-hit to STATE_M ----
            if (state == IDLE && cpu_req_valid && hit && cpu_req_write && cache[index].msi_state == STATE_M) begin
                cache[index].data[word_offset * DW +: DW] <= cpu_req_wdata;
                cache[index].dirty <= 1'b1;
            end

            // ---- Core side: fill cache line from memory on bus_grant ----
            if (bus_grant && (state == PENDING_MISS || state == PENDING_UPGRADE)) begin
                cache[pending_index].tag   <= pending_tag;
                cache[pending_index].valid <= 1'b1;
                cache[pending_index].data  <= mem_line_rdata;

                if (pending_write || state == PENDING_UPGRADE) begin
                    cache[pending_index].msi_state <= STATE_M;
                    cache[pending_index].dirty     <= 1'b1;
                    cache[pending_index].data[pending_word_offset * DW +: DW] <= pending_wdata;
                end else begin
                    cache[pending_index].msi_state <= STATE_S;
                    cache[pending_index].dirty     <= 1'b0;
                end
            end

            // ---- Bus side: snoop handler ----
            if (snoop_valid && snoop_src != CORE_ID[0] && state != WRITEBACK) begin
                if (snoop_cmd == CMD_BUSRDX) begin
                    if (cache[snp_idx].valid && cache[snp_idx].tag == snp_tag) begin
                        cache[snp_idx].msi_state <= STATE_I;
                        cache[snp_idx].valid     <= 1'b0;
                    end
                end else if (snoop_cmd == CMD_BUSRD) begin
                    if (cache[snp_idx].valid && cache[snp_idx].tag == snp_tag &&
                            cache[snp_idx].msi_state == STATE_M && !snoop_hits_m) begin
                        cache[snp_idx].msi_state <= STATE_S;
                        cache[snp_idx].dirty     <= 1'b0;
                    end
                end
            end
        end
    end

    // -------------------------------
    //      bus, cpu, mem sides
    // -------------------------------

    // Bus request generation
    always_comb begin
        bus_req_valid = 1'b0;
        bus_req_cmd   = CMD_NONE;
        bus_req_line  = '0;

        if (state == PENDING_MISS || state == PENDING_UPGRADE) begin
            bus_req_valid = 1'b1;
            bus_req_line  = {pending_tag, pending_index, {WORD_OFFSET_WIDTH{1'b0}}};

            if (state == PENDING_MISS)
                bus_req_cmd = pending_write ? CMD_BUSRDX : CMD_BUSRD;
            else
                bus_req_cmd = CMD_BUSRDX;
        end
    end

    assign cpu_req_ready = (state == IDLE && (hit || !cpu_req_valid)) ||
                           (state == FILL_LINE && !pending_write);

    // cpu_resp_rdata
    always_comb begin
        cpu_resp_rdata = '0;
        if (state == IDLE && hit && cpu_req_valid && !cpu_req_write)
            cpu_resp_rdata = cache[index].data[word_offset * DW +: DW];
        else if (state == FILL_LINE)
            cpu_resp_rdata = mem_line_rdata[pending_word_offset * DW +: DW];
    end

    // Memory write: WRITEBACK drains dirty line; FILL_LINE commits write-miss data
    always_comb begin
        mem_word_we    = 1'b0;
        mem_word_addr  = '0;
        mem_word_wdata = '0;

        if (state == WRITEBACK) begin
            mem_word_we    = 1'b1;
            mem_word_addr  = {cache[wb_index].tag, wb_index, wb_word_cnt};
            mem_word_wdata = cache[wb_index].data[wb_word_cnt * DW +: DW];
        end else if (state == FILL_LINE && pending_write) begin
            mem_word_we    = 1'b1;
            mem_word_addr  = {pending_tag, pending_index, pending_word_offset};
            mem_word_wdata = pending_wdata;
        end
    end

    // -------------------------------
    //      performance counters
    // -------------------------------

    // performance counter helpers
    always_comb begin
        hit_this_cycle     = (state == IDLE) && cpu_req_valid && hit;
        miss_this_cycle    = (state == PENDING_MISS) && bus_grant;
        upgrade_this_cycle = (state == PENDING_UPGRADE) && bus_grant &&
                             (cache[pending_index].msi_state == STATE_S);
        begin
            logic [TAG_WIDTH-1:0]   snoop_tag_c;
            logic [INDEX_WIDTH-1:0] snoop_idx_c;
            snoop_idx_c = snoop_line[WORD_OFFSET_WIDTH +: INDEX_WIDTH];
            snoop_tag_c = snoop_line[(WORD_OFFSET_WIDTH+INDEX_WIDTH) +: TAG_WIDTH];
            invalidation_this_cycle = snoop_valid && snoop_cmd == CMD_BUSRDX &&
                                      snoop_src != CORE_ID[0] &&
                                      cache[snoop_idx_c].valid &&
                                      (cache[snoop_idx_c].tag == snoop_tag_c);
        end
    end

    // performance counter update
    always_ff @(posedge clk) begin
        if (reset) begin
            hit_count          <= 32'b0;
            miss_count         <= 32'b0;
            upgrade_count      <= 32'b0;
            invalidation_count <= 32'b0;
        end else begin
            if (hit_this_cycle && hit_count != 32'hFFFFFFFF)
                hit_count <= hit_count + 1;
            if (miss_this_cycle && miss_count != 32'hFFFFFFFF)
                miss_count <= miss_count + 1;
            if (upgrade_this_cycle && upgrade_count != 32'hFFFFFFFF)
                upgrade_count <= upgrade_count + 1;
            if (invalidation_this_cycle && invalidation_count != 32'hFFFFFFFF)
                invalidation_count <= invalidation_count + 1;
        end
    end
endmodule
