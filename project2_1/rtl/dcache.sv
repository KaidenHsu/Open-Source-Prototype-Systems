module dcache #(
    parameter CAPACITY = 4 // 4 lines
)(
    input  logic        clk,
    input  logic        reset,

    input  logic        cpu_req,
    input  logic        cpu_we,
    input  logic [31:0] cpu_addr,
    input  logic [31:0] cpu_wdata,
    output logic [31:0] cpu_rdata,
    output logic        cpu_ready,

    output logic        mem_req,
    output logic        mem_we,
    output logic [31:0] mem_addr,
    // output logic [31:0] mem_wdata,
    // input  logic [31:0] mem_rdata,
    output logic [127:0] mem_wdata,
    input  logic [127:0] mem_rdata,
    input  logic        mem_ready,


    output logic [31:0] access_count,
    output logic [31:0] read_count,
    output logic [31:0] write_count,
    output logic [31:0] hit_count,
    output logic [31:0] miss_count
);
    // TODO: Project 2: implement blocking D-cache. Minimum required:
    // direct-mapped, write-through, write-allocate.

    // ============================================================
    // my implementation: direct-mapped, write-back, write-allocate,
    //                    capacity = 4, 4 words/line
    // ============================================================

    localparam INDEX_WIDTH  = $clog2(CAPACITY);
    localparam OFFSET_WIDTH = 4; // 2 bits for word offset, 2 bits for byte offset
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;

    typedef struct packed {
        logic [TAG_WIDTH-1:0] tag;                   
        logic [3:0][31:0]     payload; // 4 words per cache line   
    } cache_line_t;

    cache_line_t dcache [0:CAPACITY-1];
    
    // metadata arrays
    logic [CAPACITY-1:0] valid_array;
    logic [CAPACITY-1:0] dirty_array;

    // 1. Address Decoding
    logic [TAG_WIDTH-1:0]   req_tag;
    logic [INDEX_WIDTH-1:0] req_index;
    logic [1:0]             req_word_offset;

    assign req_word_offset = cpu_addr[3:2]; 
    assign req_index       = cpu_addr[OFFSET_WIDTH +: INDEX_WIDTH]; 
    assign req_tag         = cpu_addr[31 : 32-TAG_WIDTH];

    // 2. Cache Hit Conditionals
    logic equal, valid, dirty, miss;
    
    assign equal = (dcache[req_index].tag == req_tag);
    assign valid = valid_array[req_index];
    assign dirty = dirty_array[req_index];
    assign miss  = (!equal || !valid);

    // 3. FSM
    typedef enum logic [1:0] {
        S_COMPARE = 2'b00,
        S_EVICT   = 2'b01,
        S_ALLOC   = 2'b10
    } state_t;

    state_t state, n_state;

    always_ff @(posedge clk) begin
        if (reset) state <= S_COMPARE;
        else       state <= n_state;
    end

    always_comb begin
        case (state)
            S_COMPARE: begin
                if (cpu_req && miss) begin
                    // Diverge based on the dirtiness of the victim line
                    n_state = (valid && !equal && dirty) ? S_EVICT : S_ALLOC;
                end else begin
                    n_state = S_COMPARE;
                end
            end
            S_EVICT: n_state = mem_ready ? S_ALLOC : S_EVICT;
            S_ALLOC: n_state = mem_ready ? S_COMPARE : S_ALLOC;
            default: n_state = S_COMPARE;
        endcase
    end

    // combinationally injects the CPU's write word into the fetched memory block
    logic [3:0][31:0] spliced_block;
    always_comb begin
        spliced_block = mem_rdata; 
        spliced_block[req_word_offset] = cpu_wdata;
    end

    // 4. Memory Updates
    always_ff @(posedge clk) begin
        if (reset) begin
            valid_array <= '0;
            dirty_array <= '0;
        end else begin
            /* verilator lint_off CASEINCOMPLETE */
            case (state)
                S_COMPARE: begin
                    // Scenario A: Write Hit (Update SRAM, mark Dirty)
                    if (cpu_req && !miss && cpu_we) begin
                        dcache[req_index].payload[req_word_offset] <= cpu_wdata;
                        dirty_array[req_index] <= 1'b1;
                    end
                end
                S_ALLOC: begin
                    // Scenario B: Miss Allocation (Fill line, evaluate Write-Combine)
                    if (mem_ready) begin
                        valid_array[req_index] <= 1'b1;
                        dcache[req_index].tag  <= req_tag;
                        
                        if (cpu_we) begin
                            // Zero-penalty write implementation
                            dcache[req_index].payload <= spliced_block;
                            dirty_array[req_index]    <= 1'b1; 
                        end else begin
                            // Standard read miss implementation
                            dcache[req_index].payload <= mem_rdata;
                            dirty_array[req_index]    <= 1'b0; 
                        end
                    end
                end
            endcase
            /* verilator lint_off CASEINCOMPLETE */
        end
    end

    // 5. Output Logic (CPU Facing)
    assign cpu_ready = (state == S_COMPARE) ? (!cpu_req || !miss) : 
                    (state == S_ALLOC)   ? mem_ready :
                    1'b0;

    // Cast mem_rdata to a 2D array for easy word-bypassing
    logic [3:0][31:0] bypass_block;
    assign bypass_block = mem_rdata;
    
    assign cpu_rdata = (state == S_ALLOC && mem_ready) ? bypass_block[req_word_offset] : dcache[req_index].payload[req_word_offset];


    // 6. 128-Bit System Bus Interface (Memory Facing)
    
    logic evict_trigger;
    assign evict_trigger = (state == S_COMPARE && cpu_req && miss && valid && !equal && dirty);

    assign mem_req   = (state == S_COMPARE && cpu_req && miss) || 
                    (state == S_EVICT && mem_ready);
    
    assign mem_we    = evict_trigger;
    
    assign mem_addr  = evict_trigger ? {dcache[req_index].tag, req_index, 4'b0000} : 
                    mem_req       ? {req_tag, req_index, 4'b0000} : 32'b0; 
    
    assign mem_wdata = evict_trigger ? dcache[req_index].payload : 128'b0;

    // performance counters
    // always_ff @(posedge clk or posedge reset) begin
    //     if (reset) begin
    //         access_count<=0; read_count<=0; write_count<=0; hit_count<=0; miss_count<=0;
    //     end else if (cpu_req) begin
    //         access_count <= access_count + 1;

    //         if (cpu_we) write_count <= write_count + 1;
    //         else        read_count  <= read_count + 1;

    //         if (mem_ready) miss_count <= miss_count + 1;
    //     end
    // end

    // -----------------------------------------
    // UNIFIED PERFORMANCE COUNTERS
    // -----------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            access_count <= 0; 
            read_count   <= 0; 
            write_count  <= 0; 
            hit_count    <= 0; 
            miss_count   <= 0;
        end else if (cpu_req) begin
            // Because of the one_pulser, cpu_req is high for exactly 1 cycle per access.
            // We can safely increment our base counters the moment the pulse arrives.
            access_count <= access_count + 1;
            
            if (cpu_we) write_count <= write_count + 1;
            else        read_count  <= read_count + 1;

            if (miss) miss_count <= miss_count + 1;
            else      hit_count  <= hit_count + 1;
        end
    end    
endmodule
