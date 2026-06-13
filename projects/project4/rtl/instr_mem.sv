module instr_mem #(
    parameter WORDS = 256,
    parameter INIT_FILE = "program_conv.hex"
)(
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [31:0] addr,
    /* verilator lint_on UNUSEDSIGNAL */
    output logic [31:0] rdata
);
    logic [31:0] mem_array [0:WORDS-1];
    integer i;
    initial begin
        for (i = 0; i < WORDS; i = i + 1) mem_array[i] = 32'h00000013; // nop
        $readmemh(INIT_FILE, mem_array);
    end
    assign rdata = mem_array[addr[9:2]];
endmodule
