module branch_unit(
    input  logic        branch_en,
    input  logic [2:0]  funct3,
    input  logic [31:0] rs1_val,
    input  logic [31:0] rs2_val,
    output logic        branch_taken
);
    logic cond_met;

    // TODO: Implement branch decision logic for:
    // - beq
    // - bne
    // - blt  (signed)
    // - bge  (signed)
    always_comb begin
        unique case (funct3)
            0: cond_met = (rs1_val == rs2_val);
            1: cond_met = (rs1_val != rs2_val);
            2: cond_met = ($signed(rs1_val) < $signed(rs2_val));
            default: cond_met = ($signed(rs1_val) >= $signed(rs2_val));
        endcase
    end
    
    // If branch_en is low, branch_taken must be 0.
    assign branch_taken = branch_en & cond_met;

endmodule
