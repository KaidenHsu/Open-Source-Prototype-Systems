module hazard_unit(
    // Consumer (ID Stage)
    input  logic        if_id_valid,
    input  logic [31:0] if_id_instr, 
    input  logic [4:0]  if_id_rs1,
    input  logic [4:0]  if_id_rs2,

    // Producer (EX Stage)
    input  logic        id_ex_valid,
    input  logic        id_ex_mem_read,
    input  logic [4:0]  id_ex_rd,
    
    // Control
    input  logic        jump_or_branch_taken_ex,

    // Outputs
    output logic        stall,
    output logic        flush_if_id,
    output logic        flush_id_ex
);
    logic [6:0] id_opcode;
    assign id_opcode = if_id_instr[6:0];

    // 1. Determine if the instruction in ID actually reads the registers
    logic rs1_used;
    logic rs2_used;
    
    assign rs1_used = (id_opcode == 7'b011_0011) | // R-type
                      (id_opcode == 7'b001_0011) | // I-type ALU
                      (id_opcode == 7'b000_0011) | // Load
                      (id_opcode == 7'b010_0011) | // Store
                      (id_opcode == 7'b110_0011) | // Branch
                      (id_opcode == 7'b110_0111);  // JALR

    assign rs2_used = (id_opcode == 7'b011_0011) | // R-type
                      (id_opcode == 7'b010_0011) | // Store
                      (id_opcode == 7'b110_0011);  // Branch

    // 2. Detect REAL load-use hazards
    logic load_use_hazard;
    
    // The Ultimate Guardrail: Both instructions MUST be valid!
    assign load_use_hazard = id_ex_valid & if_id_valid & 
                             id_ex_mem_read & (id_ex_rd != 0) & (
                             (rs1_used & (id_ex_rd == if_id_rs1)) | 
                             (rs2_used & (id_ex_rd == if_id_rs2))
                             );

    assign stall = load_use_hazard;

    // 3. Flush younger instructions after a taken branch.
    assign flush_if_id = jump_or_branch_taken_ex & ~stall; 
    assign flush_id_ex = jump_or_branch_taken_ex | stall; 

endmodule
