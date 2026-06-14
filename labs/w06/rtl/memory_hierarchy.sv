module memory_hierarchy #(
    parameter LINES = 4,
    parameter WORDS_PER_LINE = 2
)(
    input  logic        clk,
    input  logic        reset,
    // core-side port
    input  logic        core_req,
    input  logic        core_we,
    input  logic [31:0] core_addr,
    input  logic [31:0] core_wdata,
    output logic [31:0] core_rdata,
    output logic        core_ready,
    // backing-memory port
    output logic        mem_req,
    output logic        mem_we,
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    input  logic [31:0] mem_rdata,
    input  logic        mem_ready,
    // statistics
    output logic [31:0] access_count,
    output logic [31:0] read_count,
    output logic [31:0] write_count,
    output logic [31:0] hit_count,
    output logic [31:0] miss_count
);
    localparam int WORD_OFF_BITS = (WORDS_PER_LINE > 1) ? $clog2(WORDS_PER_LINE) : 1;
    localparam int INDEX_BITS    = (LINES > 1) ? $clog2(LINES) : 1;
    localparam int WO_LSB = 2;
    localparam int WO_MSB = WO_LSB + WORD_OFF_BITS - 1;
    localparam int IDX_LSB = WO_MSB + 1;
    localparam int IDX_MSB = IDX_LSB + INDEX_BITS - 1;
    localparam int TAG_LSB = IDX_MSB + 1;
    localparam int TAG_BITS = 32 - TAG_LSB;

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_REFILL_REQ0,
        ST_REFILL_WAIT0,
        ST_REFILL_REQ1,
        ST_REFILL_WAIT1,
        ST_WT_REQ,
        ST_WT_WAIT
    } state_t;

    state_t state;

    logic [31:0] data_array [0:LINES-1][0:WORDS_PER_LINE-1];
    logic [TAG_BITS-1:0] tag_array [0:LINES-1];
    logic                valid_array [0:LINES-1];

    logic [31:0] req_addr_q, req_wdata_q;
    logic        req_we_q;
    logic [INDEX_BITS-1:0] req_index_q;
    logic [WORD_OFF_BITS-1:0] req_word_off_q;
    logic [TAG_BITS-1:0] req_tag_q;
    logic [31:0] line_fill [0:WORDS_PER_LINE-1];

    logic [INDEX_BITS-1:0] core_index;
    logic [WORD_OFF_BITS-1:0] core_word_off;
    logic [TAG_BITS-1:0] core_tag;
    logic hit_now;

    integer i, j;
    logic [31:0] base_addr_q;

    assign core_word_off = core_addr[WO_MSB:WO_LSB];
    assign core_index    = core_addr[IDX_MSB:IDX_LSB];
    assign core_tag      = core_addr[31:TAG_LSB];
    // TODO: restore real direct-mapped hit detection
    // Expected behavior: hit_now is 1 when the indexed line is valid and the stored tag matches core_tag
    // assign hit_now       = 1'b0; // placeholder: current scaffold treats every access as a miss
    assign hit_now = valid_array[core_index] & (tag_array[core_index] == core_tag);

    logic [31:0] core_rdata_r;
    logic        core_ready_r;

    assign core_rdata = core_rdata_r;
    assign core_ready = core_ready_r;

    always_comb begin
        mem_req   = 1'b0;
        mem_we    = 1'b0;
        mem_addr  = 32'b0;
        mem_wdata = 32'b0;

        unique case (state)
            ST_REFILL_REQ0: begin
                mem_req  = 1'b1;
                mem_we   = 1'b0;
                mem_addr = {req_addr_q[31:3], 3'b000};
            end
            ST_REFILL_REQ1: begin
                mem_req  = 1'b1;
                mem_we   = 1'b0;
                mem_addr = {req_addr_q[31:3], 3'b000} + 32'd4;
            end
            ST_WT_REQ: begin
                mem_req   = 1'b1;
                mem_we    = 1'b1;
                mem_addr  = req_addr_q;
                mem_wdata = req_wdata_q;
            end
            default: begin
            end
        endcase
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= ST_IDLE;
            core_rdata_r <= 32'b0;
            core_ready_r <= 1'b0;
            access_count <= 32'd0;
            read_count   <= 32'd0;
            write_count  <= 32'd0;
            hit_count    <= 32'd0;
            miss_count   <= 32'd0;
            req_addr_q   <= 32'd0;
            req_wdata_q  <= 32'd0;
            req_we_q     <= 1'b0;
            req_index_q  <= '0;
            req_word_off_q <= '0;
            req_tag_q    <= '0;
            for (i = 0; i < LINES; i = i + 1) begin
                valid_array[i] <= 1'b0;
                tag_array[i]   <= '0;
                for (j = 0; j < WORDS_PER_LINE; j = j + 1)
                    data_array[i][j] <= 32'd0;
            end
            for (j = 0; j < WORDS_PER_LINE; j = j + 1)
                line_fill[j] <= 32'd0;
        end else begin
            core_ready_r <= 1'b0;

            unique case (state)
                ST_IDLE: begin
                    if (core_req) begin
                        access_count <= access_count + 32'd1;
                        if (core_we)
                            write_count <= write_count + 32'd1;
                        else
                            read_count <= read_count + 32'd1;

                        req_addr_q     <= core_addr;
                        req_wdata_q    <= core_wdata;
                        req_we_q       <= core_we;
                        req_index_q    <= core_index;
                        req_word_off_q <= core_word_off;
                        req_tag_q      <= core_tag;

                        if (hit_now) begin
                            // miss_count <= miss_count + 32'd1; // placeholder keeps behavior simple but incorrect
                            // state <= ST_REFILL_REQ0;          // placeholder forces miss behavior even when line is present

                            // TODO: restore the hit path
                            // Required behavior:
                            // 1. increment hit_count
                            hit_count <= hit_count + 1;

                            if (core_we) begin
                                // 2. on a write hit: update cached word and continue with ST_WT_REQ (write-through)
                                data_array[core_index][core_word_off] <= core_wdata;
                                state <= ST_WT_REQ;
                            end else begin
                                // 3. on a read hit: return cached word immediately via core_rdata_r/core_ready_r
                                core_rdata_r <= data_array[core_index][core_word_off];
                                core_ready_r <= 1'b1;
                                // 4. remain in ST_IDLE after a read hit
                                state <= ST_IDLE;
                            end

                        end else begin
                            miss_count <= miss_count + 32'd1;
                            state <= ST_REFILL_REQ0;
                        end
                    end
                end

                ST_REFILL_REQ0: state <= ST_REFILL_WAIT0;

                ST_REFILL_WAIT0: begin
                    if (mem_ready) begin
                        line_fill[0] <= mem_rdata;
                        state <= ST_REFILL_REQ1;
                    end
                end

                ST_REFILL_REQ1: state <= ST_REFILL_WAIT1;

                ST_REFILL_WAIT1: begin
                    if (mem_ready) begin
                        line_fill[1] <= mem_rdata;
                        tag_array[req_index_q]   <= req_tag_q;
                        valid_array[req_index_q] <= 1'b1;
                        if (req_we_q) begin
                            data_array[req_index_q][0] <= line_fill[0];
                            data_array[req_index_q][1] <= line_fill[1];
                            data_array[req_index_q][req_word_off_q] <= req_wdata_q;
                            state <= ST_WT_REQ;
                        end else begin
                            data_array[req_index_q][0] <= line_fill[0];
                            data_array[req_index_q][1] <= mem_rdata;
                            core_rdata_r <= (req_word_off_q == '0) ? line_fill[0] : mem_rdata;
                            core_ready_r <= 1'b1;
                            state <= ST_IDLE;
                        end
                    end
                end

                ST_WT_REQ: state <= ST_WT_WAIT;

                ST_WT_WAIT: begin
                    if (mem_ready) begin
                        core_ready_r <= 1'b1;
                        state <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
