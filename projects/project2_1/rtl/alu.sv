module alu(
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  op,

    output logic [31:0] y,
    output logic        zero
);
    localparam ALU_ADD = 4'd0;
    localparam ALU_SUB = 4'd1;

    always_comb begin
        unique case (op)
            ALU_SUB: y = a - b;
            default: y = a + b;
        endcase
    end

    assign zero = (y == 32'b0);
endmodule
