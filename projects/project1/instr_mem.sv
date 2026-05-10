module instr_mem(
    input  logic [31:0] addr,
    output logic [31:0] instr
);

    logic [31:0] mem_array [0:255];
    integer i;

    // TODO: Initialize instruction memory.
    // Suggested behavior:
    // - Fill unused locations with NOP (32'h00000013)
    // - Allow the testbench to load program.hex using $readmemh
    initial begin
        for (i = 0; i < 256; i++) begin
            mem_array[i] = 32'h00000013;
        end
    end

    // TODO: Implement word-addressed instruction fetch.
    // For a 256-word memory, use addr[9:2] as the word index.
    // (memory is byte-addressable)
    always_comb begin
        instr = mem_array[addr[9:2]];
    end
    
endmodule
