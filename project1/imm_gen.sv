typedef enum logic [3-1 : 0] {
    IMM_I = 3'd0,
    IMM_S = 3'd1,
    IMM_B = 3'd2,
    IMM_U = 3'd3,
    IMM_J = 3'd4
} imm_type_t;

module imm_gen(
    input  logic [31:0] instr,
    input  imm_type_t   ImmSel,
    output logic [31:0] imm_out
);

    // TODO: Implement immediate generation.
    // Required support for this project:
    // - I-type immediates
    // - S-type immediates
    // - B-type immediates
    // - J-type immediates for jal
    // Keep the U-type case declared for future extensibility if you wish.
    // Make sure branch and jump immediates are assembled in the correct bit order.
    always_comb begin
        unique case (ImmSel)
            0: imm_out = {{20{instr[31]}}, instr[31:20]}; // I-type
            1: imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-type
            2: imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type
            3: imm_out = {{12{instr[31]}}, instr[31:12]}; // U-type (not supported by this processor)
            4: imm_out = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type
            5: imm_out = 0;
        endcase
    end

endmodule
