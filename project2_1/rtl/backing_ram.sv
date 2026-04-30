module backing_ram(
    input  logic         clk,
    input  logic         req,
    input  logic         we,
    input  logic [31:0]  addr,
    input  logic [127:0] wdata,   // 128-bit wide input bus (4 words)

    output logic [127:0] rdata,   // 128-bit wide output bus (4 words)
    output logic         ready
);

    logic [31:0]  mem [0:255];    // Maintained as 32-bit array for $readmemh compatibility
    logic [3:0]   delay;
    logic         busy;
    logic [31:0]  addr_q;
    logic [127:0] wdata_q;
    logic         we_q;

    always_ff @(posedge clk) begin
        // Default ready to 0
        ready <= 1'b0;
        
        if (!busy && req) begin
            busy    <= 1'b1; 
            delay   <= 4'd3;
            addr_q  <= addr;
            wdata_q <= wdata;
            we_q    <= we;
            
        end else if (busy) begin
            if (delay != 0) begin
                delay <= delay - 4'd1;
            end else begin
                
                if (we_q) begin
                    // Write all 4 words into the SRAM array simultaneously
                    // {addr_q[9:4], 2'd0} maps to the exact block and word offset
                    mem[{addr_q[9:4], 2'd3}] <= wdata_q[127:96];
                    mem[{addr_q[9:4], 2'd2}] <= wdata_q[95:64];
                    mem[{addr_q[9:4], 2'd1}] <= wdata_q[63:32];
                    mem[{addr_q[9:4], 2'd0}] <= wdata_q[31:0];
                end 
                
                // Read all 4 words out of the SRAM array and pack into the 128-bit bus
                rdata <= { mem[{addr_q[9:4], 2'd3}], 
                           mem[{addr_q[9:4], 2'd2}], 
                           mem[{addr_q[9:4], 2'd1}], 
                           mem[{addr_q[9:4], 2'd0}] };

                ready <= 1'b1;
                busy  <= 1'b0;
            end
        end
    end
endmodule
