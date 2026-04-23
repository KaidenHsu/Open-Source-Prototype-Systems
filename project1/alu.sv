typedef enum logic [4-1 : 0] { 
    ALU_ADD  = 4'd0,
    ALU_SUB  = 4'd1,
    ALU_AND  = 4'd2,
    ALU_OR   = 4'd3,
    ALU_XOR  = 4'd4,
    ALU_SLL  = 4'd5,
    ALU_SRL  = 4'd6,
    ALU_SRA  = 4'd7,
    ALU_SLT  = 4'd8,
    ALU_SLTU = 4'd9
} alu_op_t;

module alu(
    input  logic [31:0] op1,
    input  logic [31:0] op2,
    input  alu_op_t     ALUControl,
    output logic [31:0] result,
    output logic        zero
);

    // TODO: Implement ALU behavior for the required control codes.
    // Required operations:
    // - ADD, SUB, AND, OR, XOR
    // - SLL, SRL, SRA
    // - SLT, SLTU
    always_comb begin
        unique case (ALUControl)
            ALU_ADD : result = op1 + op2;
            ALU_SUB : result = op1 - op2;
            ALU_AND : result = op1 & op2;
            ALU_OR  : result = op1 | op2;
            ALU_XOR : result = op1 ^ op2;

            ALU_SLL : result = op1 << op2[4:0];
            ALU_SRL : result = op1 >> op2[4:0];
            ALU_SRA : result = $signed(op1) >>> op2[4:0];

            ALU_SLT : result = ($signed(op1) < $signed(op2))? 32'd1 : 32'd0;
            ALU_SLTU: result = (op1 < op2)? 32'd1 : 32'd0;

            default : result = 0;
        endcase
    end

    // You may keep a PASS-B code for future use if you find it helpful.

    // TODO: Drive zero high when result == 0.
    assign zero = (result == 0);

endmodule
