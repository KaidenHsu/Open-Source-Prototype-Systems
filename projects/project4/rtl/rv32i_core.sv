module rv32i_core (
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,
    output logic        dmem_valid,
    output logic        dmem_write,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input  logic [31:0] dmem_rdata,
    output logic        halted
);
    logic [31:0] pc;
    logic [31:0] regs [0:31]; // regfile

    assign imem_addr = pc;

    // instruction decoder
    wire [31:0] instr = imem_rdata;
    wire [6:0]  opcode = instr[6:0];
    wire [4:0]  rd     = instr[11:7];
    wire [2:0]  funct3 = instr[14:12];
    wire [4:0]  rs1    = instr[19:15];
    wire [4:0]  rs2    = instr[24:20];
    /* verilator lint_off UNUSEDSIGNAL */
    wire [6:0]  funct7 = instr[31:25];
    /* verilator lint_on UNUSEDSIGNAL */

    wire signed [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire signed [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire signed [31:0] imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    wire [31:0] imm_u = {instr[31:12], 12'b0};

    // hardwire a0 to GND
    wire [31:0] rs1_val = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    wire [31:0] rs2_val = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

    logic [31:0] next_pc;
    logic [31:0] wb_data;
    logic        reg_write;

    always_comb begin
        dmem_valid = 1'b0;
        dmem_write = 1'b0;
        dmem_addr  = 32'd0;
        dmem_wdata = 32'd0;
        next_pc    = pc + 32'd4;
        wb_data    = 32'd0;
        reg_write  = 1'b0;

        unique case (opcode)
            7'b0010011: begin // OP-IMM: addi only in this teaching core
                if (funct3 == 3'b000) begin
                    wb_data   = rs1_val + imm_i;
                    reg_write = 1'b1;
                end
            end
            7'b0110111: begin // LUI
                wb_data   = imm_u;
                reg_write = 1'b1;
            end
            7'b0000011: begin // LW
                if (funct3 == 3'b010) begin
                    dmem_valid = 1'b1;
                    dmem_write = 1'b0;
                    dmem_addr  = rs1_val + imm_i;
                    wb_data    = dmem_rdata;
                    reg_write  = 1'b1;
                end
            end
            7'b0100011: begin // SW
                if (funct3 == 3'b010) begin
                    dmem_valid = 1'b1;
                    dmem_write = 1'b1;
                    dmem_addr  = rs1_val + imm_s;
                    dmem_wdata = rs2_val;
                end
            end
            7'b1100011: begin // BEQ/BNE
                if (funct3 == 3'b000 && rs1_val == rs2_val) next_pc = pc + imm_b;
                if (funct3 == 3'b001 && rs1_val != rs2_val) next_pc = pc + imm_b;
            end
            7'b1110011: begin
                // ebreak is used as a simple halt instruction for the project test program.
            end
            default: begin end
        endcase
    end

    integer i;
    always_ff @(posedge clk) begin
        if (reset) begin
            pc     <= 32'd0;
            halted <= 1'b0;
            for (i = 0; i < 32; i = i + 1) regs[i] <= 32'd0;
        end else if (!halted) begin
            if (instr == 32'h00100073) begin
                halted <= 1'b1;
            end else begin
                pc <= next_pc;
                if (reg_write && rd != 5'd0) regs[rd] <= wb_data;
                regs[0] <= 32'd0;
            end
        end
    end
endmodule
