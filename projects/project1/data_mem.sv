module data_mem(
    input  logic        clk,
    input  logic        MemWrite,
    input  logic        MemRead,
    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);

    logic [31:0] mem_array [0:255];
    integer i;

    // TODO: Initialize the data memory to zero.
    initial begin
        for (i = 0; i < 256; i=i+1) begin
            mem_array[i] = 0;
        end
    end

    // TODO: Implement synchronous word stores for sw.
    // Use addr[9:2] as the word index.
    always_ff @(posedge clk) begin
        if (MemWrite) begin
            mem_array[{22'b0, addr[9:2], 2'b0}] <= write_data;
        end
    end

    // Implement combinational word reads for lw.
    // When MemRead is low, return 32'b0.
    always_comb begin
        if (MemRead) begin
            read_data = mem_array[{22'b0, addr[9:2], 2'b0}];
        end else begin
            read_data = 32'b0;
        end
    end

endmodule
