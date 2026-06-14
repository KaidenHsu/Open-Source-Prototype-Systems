module rv32i_core(
    input  logic        clk,
    input  logic        reset,
    output logic        halted,
    output logic [31:0] cycle_count,
    output logic [31:0] retired_count,
    // instruction interface (read-only, single-cycle)
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,
    // data interface (handshake)
    output logic        dmem_req,
    output logic        dmem_we,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input  logic [31:0] dmem_rdata,
    input  logic        dmem_ready
);
    typedef enum logic [2:0] {
        S_FETCH, S_DECODE, S_MEM_WAIT, S_HALT
    } state_t;

    localparam HALT_INSTR = 32'hFFFF_FFFF;
    localparam OP_RTYPE = 7'b0110011;
    localparam OP_ITYPE = 7'b0010011;
    localparam OP_LOAD  = 7'b0000011;
    localparam OP_STORE = 7'b0100011;
    localparam OP_BRANCH= 7'b1100011;
    localparam OP_JAL   = 7'b1101111;

    state_t state;
    logic [31:0] pc, instr;
    logic [6:0] opcode, funct7;
    logic [2:0] funct3;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] rs1_val, rs2_val;
    logic [31:0] imm_i, imm_s, imm_b, imm_j;
    logic reg_we;
    logic [4:0] reg_rd;
    logic [31:0] reg_wdata;
    logic mem_is_load;
    logic [4:0] pending_rd;
    logic [31:0] pending_next_pc;

    regfile u_regfile(
        .clk(clk), .we(reg_we), .rs1(rs1), .rs2(rs2), .rd(reg_rd), .wdata(reg_wdata),
        .rdata1(rs1_val), .rdata2(rs2_val)
    );

    imm_gen u_imm(
        .instr(instr), .imm_i(imm_i), .imm_s(imm_s), .imm_b(imm_b), .imm_j(imm_j)
    );

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    assign imem_addr = pc;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= S_FETCH;
            pc           <= 32'd0;
            instr        <= 32'd0;
            halted       <= 1'b0;
            cycle_count  <= 32'd0;
            retired_count<= 32'd0;
            reg_we       <= 1'b0;
            reg_rd       <= 5'd0;
            reg_wdata    <= 32'd0;
            dmem_req     <= 1'b0;
            dmem_we      <= 1'b0;
            dmem_addr    <= 32'd0;
            dmem_wdata   <= 32'd0;
            mem_is_load  <= 1'b0;
            pending_rd   <= 5'd0;
            pending_next_pc <= 32'd0;
        end else begin
            cycle_count <= cycle_count + 32'd1;
            reg_we      <= 1'b0;

            /* verilator lint_off CASEINCOMPLETE */
            case (state)
                S_FETCH: begin
                    instr <= imem_rdata;
                    if (imem_rdata == HALT_INSTR) begin
                        state <= S_HALT;
                    end else begin
                        state <= S_DECODE;
                    end
                end

                S_DECODE: begin
                    unique case (opcode)
                        OP_ITYPE: begin // addi only
                            reg_we    <= 1'b1;
                            reg_rd    <= rd;
                            reg_wdata <= rs1_val + imm_i;
                            pc        <= pc + 32'd4;
                            retired_count <= retired_count + 32'd1;
                            state     <= S_FETCH;
                        end

                        OP_RTYPE: begin // add only
                            reg_we    <= 1'b1;
                            reg_rd    <= rd;
                            reg_wdata <= rs1_val + rs2_val;
                            pc        <= pc + 32'd4;
                            retired_count <= retired_count + 32'd1;
                            state     <= S_FETCH;
                        end

                        OP_LOAD: begin // lw only
                            dmem_req      <= 1'b1;
                            dmem_we       <= 1'b0;
                            dmem_addr     <= rs1_val + imm_i;
                            dmem_wdata    <= 32'b0;
                            mem_is_load   <= 1'b1;
                            pending_rd    <= rd;
                            pending_next_pc <= pc + 32'd4;
                            state         <= S_MEM_WAIT;
                        end

                        OP_STORE: begin // sw only
                            dmem_req      <= 1'b1;
                            dmem_we       <= 1'b1;
                            dmem_addr     <= rs1_val + imm_s;
                            dmem_wdata    <= rs2_val;
                            mem_is_load   <= 1'b0;
                            pending_next_pc <= pc + 32'd4;
                            state         <= S_MEM_WAIT;
                        end

                        OP_BRANCH: begin // beq/bne only
                            logic take;
                            take = 1'b0;
                            if (funct3 == 3'b000) take = (rs1_val == rs2_val); // beq
                            if (funct3 == 3'b001) take = (rs1_val != rs2_val); // bne
                            pc <= take ? (pc + imm_b) : (pc + 32'd4);
                            retired_count <= retired_count + 32'd1;
                            state <= S_FETCH;
                        end

                        OP_JAL: begin
                            reg_we    <= 1'b1;
                            reg_rd    <= rd;
                            reg_wdata <= pc + 32'd4;
                            pc        <= pc + imm_j;
                            retired_count <= retired_count + 32'd1;
                            state     <= S_FETCH;
                        end

                        default: begin
                            // treat unknown as NOP
                            pc <= pc + 32'd4;
                            retired_count <= retired_count + 32'd1;
                            state <= S_FETCH;
                        end
                    endcase
                end

                S_MEM_WAIT: begin
                    if (dmem_ready) begin
                        dmem_req <= 1'b0;
                        if (mem_is_load) begin
                            reg_we    <= 1'b1;
                            reg_rd    <= pending_rd;
                            reg_wdata <= dmem_rdata;
                        end
                        pc <= pending_next_pc;
                        retired_count <= retired_count + 32'd1;
                        state <= S_FETCH;
                    end
                end

                S_HALT: begin
                    halted <= 1'b1;
                end
            endcase
            /* verilator lint_on CASEINCOMPLETE */
        end
    end
endmodule
