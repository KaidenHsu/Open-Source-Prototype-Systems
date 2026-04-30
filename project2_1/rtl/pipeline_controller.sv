module pipeline_controller (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,

    output logic       RegWrite,
    output logic       MemRead,
    output logic       MemWrite,
    output logic       MemToReg,
    output logic [1:0] ResultSel,   // 00=ALU, 01=MEM, 10=PC+4
    output logic       ALUSrc,      // 00=reg, 01=imm
    output logic [2:0] ImmSel,      // 000=I, 001=S, 010=B, 011=U, 100=J
    output logic [3:0] ALUControl,
    output logic       Branch,
    output logic       Jump
);
    logic R;
    logic op_0010011;
    logic lw;
    logic sw;
    logic B;
    logic jal;

    // TODO: Implement instruction decode and control generation.
    // Required instruction groups:
    // - R-type ALU instructions
    assign          R = (opcode == 7'b011_0011); // R-type
    // - I-type ALU-immediate instructions
    assign op_0010011 = (opcode == 7'b001_0011); // a set of I-type instructions that operate on a register and an immediate value
    // - lw and sw
    assign         lw = (opcode == 7'b000_0011); // I-type
    assign         sw = (opcode == 7'b010_0011); // S-type
    // - beq, bne, blt, bge
    assign          B = (opcode == 7'b110_0011); // B-type
    // - jal
    assign        jal = (opcode == 7'b110_1111); // J-type

    // For each instruction, determine the correct values of:
    // RegWrite, MemRead, MemWrite, ResultSel, ALUSrc, ImmSel,
    // ALUControl, Branch, and Jump.
    assign RegWrite = (R || op_0010011 || lw | jal);
    assign MemRead = lw;
    assign MemWrite = sw;
    assign MemToReg = lw;
    
    // ResultSel
    always_comb begin
        unique if (R || op_0010011 || sw) ResultSel = 0; // from alu
        else if (lw) ResultSel = 1; // from dmem
        else if (jal) ResultSel = 2; // from pc+4
        else ResultSel = 3; // 0 (B-type, J-type)
    end

    // ALUSrc
    assign ALUSrc = op_0010011 || lw || sw;

    // ImmSel
    always_comb begin
       unique if (op_0010011 || lw) ImmSel = 0; // I-type
       else if (sw) ImmSel = 1; // S-type
       else if (B) ImmSel = 2; // B-type
       else if (opcode == 7'b001_0111 | opcode == 7'b011_0111) ImmSel = 3; // U-type (not supported by this processor)
       else if (jal) ImmSel = 4; // J-type
       else ImmSel = 5;
    end

    // ALUControl
    always_comb begin
        unique if ((R && funct3 == 0 && funct7 == 7'h00) || // add
            (op_0010011 && funct3 == 0) || // addi
            lw || sw
        ) begin
            ALUControl = 0; // add
        end else if ((R && funct3 == 0 && funct7 == 7'h20) || // sub
            B // branch
        )  begin
            ALUControl = 1; // sub
        end else if ((R && funct3 == 4 && funct7 == 7'h00) || // xor
            (op_0010011 && funct3 == 4) // xori
        ) begin
            ALUControl = 2; // xor
        end else if ((R && funct3 == 6 && funct7 == 7'h00) || // or
            (op_0010011 && funct3 == 6) // ori
        ) begin
            ALUControl = 3; // or
        end else if ((R && funct3 == 7 && funct7 == 7'h00) || // and
            (op_0010011 && funct3 == 7) // andi
        ) begin
            ALUControl = 4; // and
        end else if ((R && funct3 == 1 && funct7 == 7'h00) || // sll
            (op_0010011 && funct3 == 1) // slli
        ) begin
            ALUControl = 5; // sll
        end else if ((R && funct3 == 5 && funct7 == 7'h00) || // srl
            (op_0010011 && funct3 == 5 && funct7 == 7'h00) // srli
        ) begin
            ALUControl = 6; // srl
        end else if ((R && funct3 == 5 && funct7 == 7'h20) || // sra
            (op_0010011 && funct3 == 5 && funct7 == 7'h20) // srai
        ) begin
            ALUControl = 7; // sra
        end else if ((R && funct3 == 2 && funct7 == 7'h00) || // slt
            (op_0010011 && funct3 == 2) // slti
        ) begin
            ALUControl = 8; // slt
        end else if ((R && funct3 == 3 && funct7 == 7'h00) || // sltu
            (op_0010011 && funct3 == 3) // sltiu
        ) begin
            ALUControl = 9; // sltu
        end else ALUControl = 10; // B-type, jal
    end

    // Branch
    assign Branch = B;

    // Jump
    assign Jump = jal;
endmodule
