module icache #(
    parameter USE_PASSTHRU = 0,
    parameter CAPACITY = 4 // should be power of 2
)(
    input  logic        clk,
    input  logic        reset,

    input  logic        cpu_req,
    input  logic [31:0] cpu_addr,
    output logic [31:0] cpu_rdata,
    output logic        cpu_ready,

    output logic        mem_req,
    output logic        mem_we,
    output logic [31:0] mem_addr,
    output logic [127:0] mem_wdata,
    input  logic [127:0] mem_rdata,
    input  logic        mem_ready,

    output logic [31:0] hit_count,
    output logic [31:0] miss_count
);

    generate
        if (USE_PASSTHRU) begin
            // -----------------------------------------
            // PASSTHROUGH CACHE LOGIC
            // -----------------------------------------
            typedef enum logic {
                S_WAIT_REQ = 0,
                S_WAIT_MEM = 1
            } state_t;

            state_t state, n_state;

            always_ff @(posedge clk) begin
                if (reset) state <= S_WAIT_REQ;
                else state <= n_state;
            end

            always_comb begin
                case (state)
                    S_WAIT_REQ: n_state = (cpu_req)? S_WAIT_MEM : S_WAIT_REQ;
                    S_WAIT_MEM: n_state = (mem_ready)? S_WAIT_REQ : S_WAIT_MEM;
                endcase
            end

            // assign cpu_rdata = mem_rdata;
            // Cast the 128-bit flat memory bus into an array of four 32-bit words
            logic [3:0][31:0] bypass_block;
            assign bypass_block = mem_rdata;

            // Multiplex the exact word the CPU asked for
            assign cpu_rdata = bypass_block[cpu_addr[3:2]];

            assign cpu_ready = (state == S_WAIT_REQ & ~cpu_req) | (state == S_WAIT_MEM & mem_ready);

            assign mem_req   = cpu_req;
            assign mem_we    = 1'b0;
            assign mem_addr  = cpu_addr;
            assign mem_wdata = 128'b0;

        end else begin 
            // -----------------------------------------
            // REAL I-CACHE LOGIC
            // -----------------------------------------
            localparam INDEX_WIDTH  = $clog2(CAPACITY);
            localparam OFFSET_WIDTH = 4; // 4 bits total (2 for word offset + 2 for byte offset)
            localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;

            typedef struct packed {
                logic [TAG_WIDTH-1:0]    tag;                   
                logic [3:0][31:0]        payload; // 4 words per cache line   
            } cache_line_t;

            cache_line_t icache [0:CAPACITY-1];
            logic [CAPACITY-1:0] valid_array;

            // 1. Address Decoding
            logic [TAG_WIDTH-1:0]   req_tag;
            logic [INDEX_WIDTH-1:0] req_index;
            logic [1:0]             req_word_offset;

            // extract the 4-word block offset
            assign req_word_offset = cpu_addr[3:2]; 
            assign req_index       = cpu_addr[OFFSET_WIDTH +: INDEX_WIDTH]; 
            assign req_tag         = cpu_addr[31 : 32-TAG_WIDTH];

            // 2. Cache Hit Conditionals
            logic equal;
            logic valid;
            
            assign equal = (icache[req_index].tag == req_tag);
            assign valid = valid_array[req_index];

            // 3. FSM
            typedef enum logic {
                S_COMPARE = 1'b0,
                S_ALLOC   = 1'b1
            } state_t;

            state_t state, n_state;

            always_ff @(posedge clk) begin
                if (reset) state <= S_COMPARE;
                else       state <= n_state;
            end

            always_comb begin
                case (state)
                    S_COMPARE: n_state = (cpu_req & (!equal | !valid)) ? S_ALLOC : S_COMPARE;
                    S_ALLOC:   n_state = mem_ready ? S_COMPARE : S_ALLOC;
                    default:   n_state = S_COMPARE;
                    endcase
            end

            // 4. Memory Updates
            always_ff @(posedge clk) begin
                if (reset) begin
                    valid_array <= '0;
                end else if (state == S_ALLOC && mem_ready) begin
                    valid_array[req_index]    <= 1'b1;
                    // SV automatically packs the flat 128-bit mem_rdata into the 4x32 array
                    icache[req_index].payload <= mem_rdata; 
                    icache[req_index].tag     <= req_tag;
                end
            end

            // 5. Output Logic
            assign cpu_ready = (state == S_COMPARE) ? (!cpu_req | (cpu_req & equal & valid)) : 
                            (state == S_ALLOC)   ? mem_ready : 1'b0;

            // cast mem_rdata to a 2D array to easily index it for the bypass path
            logic [3:0][31:0] bypass_block;
            assign bypass_block = mem_rdata;
            
            assign cpu_rdata = (state == S_ALLOC && mem_ready) ? bypass_block[req_word_offset] : icache[req_index].payload[req_word_offset];

            assign mem_req   = (state == S_COMPARE) && cpu_req && (!equal || !valid);
            
            assign mem_addr  = mem_req ? {cpu_addr[31:4], 4'b0000} : 32'b0; 
            
            assign mem_we    = 1'b0;
            assign mem_wdata = 128'b0; // 128-bit wide tie-off
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (reset) begin
            hit_count  <= 0;
            miss_count <= 0;
        end else begin
            // A hit is defined as: CPU requested, cache is ready immediately, 
            // and we are NOT waiting on the backing memory this cycle.
            if (cpu_req && cpu_ready && !mem_req) begin
                hit_count <= hit_count + 1;
            end
            
            // A miss is completely resolved on the cycle mem_ready is asserted 
            // AND we are completing the transaction (cpu_ready goes high).
            if (cpu_req && cpu_ready && mem_req && mem_ready) begin
                miss_count <= miss_count + 1;
            end
        end
    end
endmodule
