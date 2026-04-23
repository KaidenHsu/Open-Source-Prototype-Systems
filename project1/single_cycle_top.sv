// a 32-bit single-cycle, in-order, single-issue processor that supports a subset of the RISC-V ISA
module single_cycle_top(
    input  logic clk,
    input  logic reset
);

    // IF
    logic [31:0] pc_current, pc_next;
    logic [31:0] instr;

    // ID
    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;
    logic [6:0] funct7;

    // control signals
    logic        RegWrite, MemRead, MemWrite, Branch, Jump;
    logic [1:0]  ResultSel, ALUSrc;
    logic [2:0]  ImmSel;
    logic [3:0]  ALUControl;

    // EX, MEM
    logic [31:0] reg_read1, reg_read2, reg_write_data;
    logic [31:0] imm_value;
    logic [31:0] alu_op1, alu_op2;
    logic [31:0] alu_result;
    logic        alu_zero;
    logic [31:0] mem_read_data;
    logic        branch_taken;

    // WB
    logic [31:0] pc_plus4;
    logic [31:0] branch_target;
    logic [31:0] next_after_branch;
    logic [31:0] jump_target;

    pc u_pc(
        .clk   (clk),
        .reset (reset),
        .pc_in (pc_next),
        .pc_out(pc_current)
    );

    instr_mem u_imem(
        .addr (pc_current),
        .instr(instr)
    );

    // TODO: Extract instruction fields from instr.
    // Suggested fields: opcode, rd, funct3, rs1, rs2, funct7
    instr_parser u_ipsr(
        .instr(instr),

        .opcode(opcode),
        .rd(rd), .rs1(rs1), .rs2(rs2),
        .funct3(funct3), .funct7(funct7)
    );

    control_unit u_ctrl(
        .opcode    (opcode),
        .funct3    (funct3),
        .funct7    (funct7),
        .RegWrite  (RegWrite),
        .MemRead   (MemRead),
        .MemWrite  (MemWrite),
        .ResultSel (ResultSel),
        .ALUSrc    (ALUSrc),
        .ImmSel    (ImmSel),
        .ALUControl(ALUControl),
        .Branch    (Branch),
        .Jump      (Jump)
    );

    regfile u_regs(
        .clk       (clk),
        .reset     (reset),
        .RegWrite  (RegWrite),
        .rs1       (rs1),
        .rs2       (rs2),
        .rd        (rd),
        .write_data(reg_write_data),
        .read_data1(reg_read1),
        .read_data2(reg_read2)
    );

    imm_gen u_imm(
        .instr  (instr),
        .ImmSel (ImmSel),
        .imm_out(imm_value)
    );

    // TODO: Select ALU operand 1.
    // For the baseline project, op1 should normally be reg_read1.
    assign alu_op1 = reg_read1;

    mux2 u_alu_src_mux(
        .sel(ALUSrc[0]),
        .a  (reg_read2),
        .b  (imm_value),
        .y  (alu_op2)
    );

    alu u_alu(
        .op1       (alu_op1),
        .op2       (alu_op2),
        .ALUControl(ALUControl),
        .result    (alu_result),
        .zero      (alu_zero)
    );

    data_mem u_dmem(
        .clk       (clk),
        .MemWrite  (MemWrite),
        .MemRead   (MemRead),
        .addr      (alu_result),
        .write_data(reg_read2),
        .read_data (mem_read_data)
    );

    branch_unit u_branch(
        .branch_en   (Branch),
        .funct3      (funct3),
        .rs1_val     (reg_read1),
        .rs2_val     (reg_read2),
        .branch_taken(branch_taken)
    );

    adder u_pc_plus4(
        .a  (pc_current),
        .b  (32'd4),
        .sum(pc_plus4)
    );

    adder u_branch_target(
        .a  (pc_current),
        .b  (imm_value),
        .sum(branch_target)
    );

    // TODO: Compute the jal target.
    // For this baseline, use pc_current + imm_value.
    adder u_jump_target(
        .a  (pc_current),
        .b  (imm_value),
        .sum(jump_target)
    );

    mux2 u_branch_mux(
        .sel(branch_taken),
        .a  (pc_plus4),
        .b  (branch_target),
        .y  (next_after_branch)
    );

    mux2 u_jump_mux(
        .sel(Jump),
        .a  (next_after_branch),
        .b  (jump_target),
        .y  (pc_next)
    );

    // TODO: Implement the register writeback mux.
    // ResultSel meaning:
    // 00 -> ALU result
    // 01 -> memory read data
    // 10 -> PC + 4
    always_comb begin
        unique case (ResultSel) 
            2'b00: reg_write_data = alu_result; // R-type, I-type (except for lw), sw
            2'b01: reg_write_data = mem_read_data; // lw
            2'b10: reg_write_data = pc_plus4; // jal
            default: reg_write_data = 0; // B-type, J-type
        endcase
    end
endmodule
