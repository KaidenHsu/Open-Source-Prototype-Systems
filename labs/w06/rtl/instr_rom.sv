module instr_rom(
    input  logic [31:0] addr,
    output logic [31:0] instr
);
    logic [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i++) mem[i] = 32'h00000013; // nop
    end
    assign instr = mem[addr[9:2]];
endmodule
