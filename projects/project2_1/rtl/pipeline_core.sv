module pipeline_core(
    input  logic        clk,
    input  logic        reset,
    output logic        halted,

    output logic [31:0] cycle_count,
    output logic [31:0] retired_count,

    // I-cache CPU side
    output logic        ic_req,
    output logic [31:0] ic_addr,
    input  logic [31:0] ic_rdata,
    input  logic        ic_ready,

    // D-cache CPU side
    output logic        dc_req,
    output logic        dc_we,
    output logic [31:0] dc_addr,
    output logic [31:0] dc_wdata,
    input  logic [31:0] dc_rdata,
    input  logic        dc_ready,

    // performance outputs
    output logic [31:0] stall_cycles,
    output logic [31:0] branch_flush_cycles
);
    // ============================================================
    // Project 2 scaffold note
    // ============================================================
    // This file intentionally preserves the *structure* of a 5-stage
    // pipeline without providing the full final implementation.
    //
    // Students are expected to:
    //   1. Build IF/ID/EX/MEM/WB pipeline register behavior
    //   2. Connect hazard_unit and forwarding_unit meaningfully
    //   3. Generate correct branch flush / stall behavior
    //   4. Drive the I-cache and D-cache ports correctly
    //   5. Retire instructions and update performance counters
    //
    // The utility modules (regfile / alu / imm_gen) are provided.
    // ============================================================

    localparam logic [6:0] OP_RTYPE  = 7'b0110011;
    localparam logic [6:0] OP_ITYPE  = 7'b0010011;
    localparam logic [6:0] OP_LOAD   = 7'b0000011;
    localparam logic [6:0] OP_STORE  = 7'b0100011;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [31:0] HALT_INSTR = 32'hFFFF_FFFF;

    typedef struct packed {
        // IF/ID
        logic [31:0] pc;
        logic [31:0] instr;
        
        // control signals

        // WB
        logic        valid;
    } if_id_t;

    typedef struct packed {
        // ID/EX
        logic [31:0] pc;
        logic [31:0] instr;
        logic [31:0] rs1_val;
        logic [31:0] rs2_val;
        logic [4:0]  rs1;
        logic [4:0]  rs2;
        logic [4:0]  rd;
        logic [31:0] imm;

        // control signals

        // WB
        logic        valid;
        logic        reg_write;
        logic        mem_to_reg;
        logic        is_jal;

        // MEM
        logic        mem_read;
        logic        mem_write;

        // EX
        logic        alu_src_imm;
        logic [3:0]  alu_ctrl;
        logic        is_branch;
        logic [2:0]  funct3;
    } id_ex_t;


    typedef struct packed {
        // EX/MEM
        logic [31:0] pc;
        logic [31:0] instr;
        logic [31:0] alu_result;
        logic [31:0] rs2_forward_val;
        logic [4:0]  rd;

        // control signals

        // WB
        logic        valid;
        logic        reg_write;
        logic        mem_to_reg;
        logic        is_jal;

        // MEM
        logic        mem_read;
        logic        mem_write;
    } ex_mem_t;

    typedef struct packed {
        // MEM/WB
        logic [31:0] pc;
        logic [31:0] instr;
        logic [4:0]  rd;
        logic [31:0] alu_result;
        logic [31:0] mem_data;

        // control signals

        // WB
        logic        valid;
        logic        reg_write;
        logic        mem_to_reg;
        logic        is_jal;

    } mem_wb_t;

    // pipeline registers
    if_id_t if_id;
    id_ex_t id_ex;
    ex_mem_t ex_mem;
    mem_wb_t mem_wb;

    // debug aliases
    logic [31:0] IF_ID_PC, IF_ID_INSTR;
    logic        IF_ID_VALID;

    logic [31:0] ID_EX_PC, ID_EX_INSTR, ID_EX_RS1_VAL, ID_EX_RS2_VAL, ID_EX_IMM;
    logic [4:0]  ID_EX_RS1, ID_EX_RS2, ID_EX_RD;
    logic        ID_EX_VALID, ID_EX_REG_WRITE, ID_EX_MEM_TO_REG, ID_EX_IS_JAL;
    logic        ID_EX_MEM_READ, ID_EX_MEM_WRITE, ID_EX_ALU_SRC_IMM, ID_EX_IS_BRANCH;
    logic [3:0]  ID_EX_ALU_CTRL;
    logic [2:0]  ID_EX_FUNCT3;

    logic [31:0] EX_MEM_PC, EX_MEM_INSTR, EX_MEM_ALU_RESULT, EX_MEM_RS2_FORWARD_VAL;
    logic [4:0]  EX_MEM_RD;
    logic        EX_MEM_VALID, EX_MEM_REG_WRITE, EX_MEM_MEM_TO_REG, EX_MEM_IS_JAL;
    logic        EX_MEM_MEM_READ, EX_MEM_MEM_WRITE;

    logic [31:0] MEM_WB_PC, MEM_WB_INSTR, MEM_WB_ALU_RESULT, MEM_WB_MEM_DATA;
    logic [4:0]  MEM_WB_RD;
    logic        MEM_WB_VALID, MEM_WB_REG_WRITE, MEM_WB_MEM_TO_REG, MEM_WB_IS_JAL;

    assign IF_ID_PC                = if_id.pc;
    assign IF_ID_INSTR             = if_id.instr;
    assign IF_ID_VALID             = if_id.valid;

    assign ID_EX_PC                = id_ex.pc;
    assign ID_EX_INSTR             = id_ex.instr;
    assign ID_EX_RS1_VAL           = id_ex.rs1_val;
    assign ID_EX_RS2_VAL           = id_ex.rs2_val;
    assign ID_EX_RS1               = id_ex.rs1;
    assign ID_EX_RS2               = id_ex.rs2;
    assign ID_EX_RD                = id_ex.rd;
    assign ID_EX_IMM               = id_ex.imm;
    assign ID_EX_VALID             = id_ex.valid;
    assign ID_EX_REG_WRITE         = id_ex.reg_write;
    assign ID_EX_MEM_TO_REG        = id_ex.mem_to_reg;
    assign ID_EX_IS_JAL            = id_ex.is_jal;
    assign ID_EX_MEM_READ          = id_ex.mem_read;
    assign ID_EX_MEM_WRITE         = id_ex.mem_write;
    assign ID_EX_ALU_SRC_IMM       = id_ex.alu_src_imm;
    assign ID_EX_ALU_CTRL          = id_ex.alu_ctrl;
    assign ID_EX_IS_BRANCH         = id_ex.is_branch;
    assign ID_EX_FUNCT3            = id_ex.funct3;

    assign EX_MEM_PC               = ex_mem.pc;
    assign EX_MEM_INSTR            = ex_mem.instr;
    assign EX_MEM_ALU_RESULT       = ex_mem.alu_result;
    assign EX_MEM_RS2_FORWARD_VAL  = ex_mem.rs2_forward_val;
    assign EX_MEM_RD               = ex_mem.rd;
    assign EX_MEM_VALID            = ex_mem.valid;
    assign EX_MEM_REG_WRITE        = ex_mem.reg_write;
    assign EX_MEM_MEM_TO_REG       = ex_mem.mem_to_reg;
    assign EX_MEM_IS_JAL           = ex_mem.is_jal;
    assign EX_MEM_MEM_READ         = ex_mem.mem_read;
    assign EX_MEM_MEM_WRITE        = ex_mem.mem_write;

    assign MEM_WB_PC               = mem_wb.pc;
    assign MEM_WB_INSTR            = mem_wb.instr;
    assign MEM_WB_ALU_RESULT       = mem_wb.alu_result;
    assign MEM_WB_MEM_DATA         = mem_wb.mem_data;
    assign MEM_WB_RD               = mem_wb.rd;
    assign MEM_WB_VALID            = mem_wb.valid;
    assign MEM_WB_REG_WRITE        = mem_wb.reg_write;
    assign MEM_WB_MEM_TO_REG       = mem_wb.mem_to_reg;
    assign MEM_WB_IS_JAL           = mem_wb.is_jal;

    // datapath signals
    logic [31:0] pc_reg;

    // ID
    logic [6:0]  opcode_d, funct7_d;
    logic [2:0]  funct3_d;
    logic [4:0]  rs1_d, rs2_d, rd_d;
    logic [31:0] rs1_val, rs2_val;

    logic       reg_write;
    logic       mem_read, mem_write, mem_to_reg;
    logic       alu_src_imm;
    logic [3:0] alu_ctrl;
    logic       is_branch, is_jal;
    logic [2:0] imm_sel;

    logic [31:0] imm_i, imm_s, imm_b, imm_j;
    logic [31:0] imm;

    // EX
    logic        zero;
    logic        branch_taken;
    logic [31:0] branch_target;

    logic [31:0] rs2_e;
    logic [31:0] alu_a_input, alu_b_input;
    logic [31:0] alu_result;

    logic [31:0] wb_data;

    // forwarding signals
    logic [1:0]  fwd_a_sel, fwd_b_sel;

    // stall and flush signals
    logic        stall, fetch_stall, mem_stall;
    logic        flush_if_id, flush_id_ex;

    assign fetch_stall = ~ic_ready;
    assign mem_stall = (~dc_ready) & (ex_mem.mem_read | ex_mem.mem_write) & ex_mem.valid;

    // -------------------------------
    //            pc_reg
    // -------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) pc_reg <= 32'd0;
        else begin
            if (halted) pc_reg <= pc_reg;
            else if (!fetch_stall && !mem_stall && !stall) begin
                pc_reg <= (branch_taken | id_ex.is_jal)? branch_target : pc_reg+4;
            end
            // if cache stall or load-use hazard, hold current pc
        end
    end

    // -------------------------------
    //              IF
    // -------------------------------

    // I$
    assign ic_req    = !halted & ~mem_stall;
    assign ic_addr = pc_reg;

    // -------------------------------
    //            if/id
    // -------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) if_id <= '0;
        else begin
            if (flush_if_id) if_id <= '0;
            else if (!fetch_stall && !mem_stall && !stall) begin
                if_id.pc    <= pc_reg;
                if_id.instr <= ic_rdata;
                if_id.valid <= 1'b1;
            end
            // if cache stall or load-use hazard, hold current values
        end
    end

    // -------------------------------
    //              ID
    // -------------------------------

    // instruction parser
    assign opcode_d = if_id.instr[ 6: 0];
    assign rd_d     = if_id.instr[11: 7];
    assign funct3_d = if_id.instr[14:12];
    assign rs1_d    = if_id.instr[19:15];
    assign rs2_d    = if_id.instr[24:20];
    assign funct7_d = if_id.instr[31:25];

    pipeline_controller u_pipeline_controller (
        .opcode(opcode_d), .funct3(funct3_d), .funct7(funct7_d),

        .RegWrite(reg_write),
        .MemRead(mem_read), .MemWrite(mem_write), .MemToReg(mem_to_reg),
        .ALUSrc(alu_src_imm), .ALUControl(alu_ctrl),
        .Branch(is_branch), .Jump(is_jal),
        .ResultSel(), .ImmSel(imm_sel)
    );
    
    regfile u_regfile(
        .clk(clk), .we(mem_wb.valid && mem_wb.reg_write),
        .rs1(rs1_d), .rs2(rs2_d), .rd(mem_wb.rd), .wdata(wb_data),
        .rdata1(rs1_val), .rdata2(rs2_val)
    );

    imm_gen u_imm(
        .instr(if_id.instr), .imm_i(imm_i), .imm_s(imm_s), .imm_b(imm_b), .imm_j(imm_j)
    );

    always_comb begin
        unique case (imm_sel)
            0: imm = imm_i;
            1: imm = imm_s;
            2: imm = imm_b;
            4: imm = imm_j;
            default: imm = 0;
        endcase
    end

    // -------------------------------
    //            id/ex
    // -------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) id_ex <= '0;
        else begin
            if (halted) id_ex <= id_ex;
            else if (flush_id_ex) id_ex <= '0; // inject bubble, load-use hazard (stall) is handled here
            else if (!fetch_stall && !mem_stall) begin
                id_ex.pc      <= if_id.pc;
                id_ex.instr   <= if_id.instr;

                id_ex.rs1 <= rs1_d;
                id_ex.rs2 <= rs2_d;
                id_ex.rd <= rd_d;

                id_ex.rs1_val <= rs1_val;
                id_ex.rs2_val <= rs2_val;

                id_ex.imm <= imm;

                // WB
                id_ex.valid   <= if_id.valid;
                id_ex.reg_write <= reg_write;
                id_ex.is_jal <= is_jal;

                // MEM
                id_ex.mem_write <= mem_write;
                id_ex.mem_read  <= mem_read;
                id_ex.mem_to_reg  <= mem_to_reg;

                // EX
                id_ex.alu_src_imm <= alu_src_imm;
                id_ex.alu_ctrl <= alu_ctrl;
                id_ex.is_branch <= is_branch;
                id_ex.funct3 <= funct3_d;
            end
            // if cache stall, hold current values
        end
    end

    // -------------------------------
    //              EX
    // -------------------------------

    // alu_a_input
    always_comb begin
        unique case (fwd_a_sel)
            0: alu_a_input = id_ex.rs1_val;
            1: alu_a_input = wb_data;
            2: alu_a_input = ex_mem.alu_result;
            default: alu_a_input = 0;
        endcase
    end

    // rs2_e
    always_comb begin
        unique case (fwd_b_sel)
            0: rs2_e = id_ex.rs2_val;
            1: rs2_e = wb_data;
            2: rs2_e = ex_mem.alu_result;
            default: rs2_e = 0;
        endcase
    end

    assign alu_b_input = (id_ex.alu_src_imm)? id_ex.imm : rs2_e;

    alu u_alu (
        .a(alu_a_input), .b(alu_b_input), .op(id_ex.alu_ctrl),
        .y(alu_result), .zero(zero)
    );

    // branch_taken (branch unit)
    always_comb begin
        case (id_ex.funct3)
            0: branch_taken =  zero & id_ex.is_branch; // beq
            1: branch_taken = ~zero & id_ex.is_branch; // bne
            default: branch_taken = 0;
        endcase
    end

    assign branch_target = id_ex.pc + id_ex.imm;

    // -------------------------------
    //            ex/mem
    // -------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) ex_mem <= '0;
        else begin
            if (halted) ex_mem <= ex_mem;
            else if (!fetch_stall && !mem_stall) begin
                ex_mem.pc <= id_ex.pc;
                ex_mem.instr <= id_ex.instr;

                ex_mem.alu_result <= alu_result;
                ex_mem.rs2_forward_val <= rs2_e;
                ex_mem.rd <= id_ex.rd;

                // control signals

                // WB
                ex_mem.valid <= id_ex.valid;
                ex_mem.reg_write <= id_ex.reg_write;
                ex_mem.mem_to_reg <= id_ex.mem_to_reg;
                ex_mem.is_jal <= id_ex.is_jal;

                // MEM
                ex_mem.mem_read <= id_ex.mem_read;
                ex_mem.mem_write <= id_ex.mem_write;
            end
            // if cache stall, hold current values
        end
    end

    // -------------------------------
    //              MEM
    // -------------------------------

    assign dc_req    = !halted & ex_mem.valid & (ex_mem.mem_read | ex_mem.mem_write);
    assign dc_addr   = (ex_mem.valid)? ex_mem.alu_result : 0;
    assign dc_we     = ex_mem.valid & ex_mem.mem_write;
    assign dc_wdata  = (ex_mem.valid)? ex_mem.rs2_forward_val : 0;

    // -------------------------------
    //            mem/wb
    // -------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) mem_wb <= '0;
        else begin
            if (halted) mem_wb <= mem_wb;
            else if (!fetch_stall && !mem_stall) begin
                mem_wb.pc <= ex_mem.pc;
                mem_wb.instr <= ex_mem.instr;
                mem_wb.rd <= ex_mem.rd;
                mem_wb.alu_result <= ex_mem.alu_result;
                mem_wb.mem_data <= dc_rdata;

                // control signals

                // WB
                mem_wb.valid <= ex_mem.valid;
                mem_wb.reg_write <= ex_mem.reg_write;
                mem_wb.mem_to_reg <= ex_mem.mem_to_reg;
                mem_wb.is_jal <= ex_mem.is_jal;
            end
            // if cache stall, hold current values
        end
    end

    // -------------------------------
    //              WB
    // -------------------------------

    // writeback mux
    always_comb begin
        unique if (mem_wb.is_jal) wb_data = mem_wb.pc + 4; // jal
        else if (mem_wb.mem_to_reg) wb_data = mem_wb.mem_data; // lw
        else wb_data = mem_wb.alu_result;
    end

    // -------------------------------
    //      forwarding & hazard
    // -------------------------------
    forwarding_unit u_fwd(
        .ex_mem_valid(ex_mem.valid), .ex_mem_reg_write(ex_mem.reg_write), .ex_mem_rd(ex_mem.rd),
        .mem_wb_valid(mem_wb.valid), .mem_wb_reg_write(mem_wb.reg_write), .mem_wb_rd(mem_wb.rd),
        .id_ex_rs1(id_ex.rs1), .id_ex_rs2(id_ex.rs2),

        .fwd_a_sel(fwd_a_sel), .fwd_b_sel(fwd_b_sel)
    );

    hazard_unit u_hzd(
        .if_id_valid(if_id.valid), .if_id_instr(if_id.instr), .if_id_rs1(rs1_d), .if_id_rs2(rs2_d),
        .id_ex_valid(id_ex.valid), .id_ex_mem_read(id_ex.mem_read), .id_ex_rd(id_ex.rd),
        .jump_or_branch_taken_ex(branch_taken | id_ex.is_jal),

        .stall(stall), .flush_if_id(flush_if_id), .flush_id_ex(flush_id_ex)
    );

    // -------------------------------
    // halted and performance counters
    // -------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            halted              <= 1'b0;
            cycle_count         <= 32'd0;
            retired_count       <= 32'd0;
            stall_cycles        <= 32'd0;
            branch_flush_cycles <= 32'd0;
        end else begin
            cycle_count <= cycle_count + 32'd1;

            if (mem_wb.valid && (mem_wb.instr == HALT_INSTR)) halted <= 1'b1;

            if (!fetch_stall && !mem_stall && !halted) begin
                if (mem_wb.valid && (mem_wb.instr != HALT_INSTR)) begin
                    retired_count <= retired_count + 32'd1;
                end

                if (branch_taken) begin
                    branch_flush_cycles <= branch_flush_cycles + 32'd1;
                end
            end

            if (!halted) begin
                if (!ic_ready || !dc_ready || stall) begin
                    stall_cycles <= stall_cycles + 32'd1;
                end
            end
        end
    end
endmodule
