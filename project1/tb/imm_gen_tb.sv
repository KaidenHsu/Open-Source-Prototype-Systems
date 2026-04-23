module imm_gen_tb;

  logic [31:0] instr;
  imm_type_t   imm_sel;

  logic [31:0] imm;

  imm_gen dut (
    .instr(instr),
    .ImmSel(imm_sel),
    .imm_out(imm)
  );

  initial begin
    /* ----------------- I-type --------------------*/
    // addi
    instr   = 32'b111111111100_00000_000_00000_0010011;
    imm_sel = IMM_I;
    #1 assert (imm == 32'hFFFF_FFFC) // -4
        else $fatal("I-type imm gen (addi) failed, imm=%0h", imm);

    // lw
    instr   = 32'b000000011100_00000_010_00000_0000011;
    imm_sel = IMM_I;
    #1 assert (imm == 32'h0000_001C) // 28
        else $fatal("I-type imm gen (lw) failed, imm=%0h", imm);

    /* ----------------- S-type --------------------*/
    // sw
    instr   = 32'b0000000_00000_00000_000_10100_0100011;
    imm_sel = IMM_S;
    #1 assert (imm == 32'h0000_0014) // 20
        else $fatal("S-type imm gen (sw) failed, imm=%0h", imm);

    /* ----------------- B-type --------------------*/
    // beq
    instr   = 32'b0_000000_00000_00000_000_1000_0_1100011;
    imm_sel = IMM_B;
    #1 assert (imm == 32'h0000_0010) // 16
        else $fatal("B-type imm gen (beq) failed, imm=%0h", imm);

    /* ----------------- J-type --------------------*/
    // jal
    instr   = 32'b0_0000000000_1_00000000_00000_1101111;
    imm_sel = IMM_J;
    #1 assert (imm == 32'h0000_0800) // 2048
        else $fatal("J-type imm gen (jal) failed, imm=%0h", imm);

    #1 $finish;
  end

endmodule
