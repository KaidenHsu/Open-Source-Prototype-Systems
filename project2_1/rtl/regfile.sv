module regfile(
    input  logic        clk,
    input  logic        we,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] wdata,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2
);
    logic [31:0] regs [0:31];
    integer i;
    initial begin
        for (i = 0; i < 32; i++) regs[i] = 32'b0;
    end
    always_ff @(posedge clk) begin
        if (we && rd != 5'd0)
            regs[rd] <= wdata;
        regs[0] <= 32'b0;
    end
    assign rdata1 = (rs1 == 5'd0) ? 32'b0 : regs[rs1];
    assign rdata2 = (rs2 == 5'd0) ? 32'b0 : regs[rs2];
endmodule
