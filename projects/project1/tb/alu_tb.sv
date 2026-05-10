module alu_tb;

  logic [31:0] a, b, y;
  logic        zero;
  alu_op_t     op;

  alu dut (
    .op1(a),
    .op2(b),
    .ALUControl(op),
    .result(y),
    .zero(zero)
  );

  initial begin
    a = 32'd10; b = 32'd3; op = ALU_ADD; #1;
    assert (y == 32'd13 && zero == 1'b0)
      else $fatal(1, "ADD failed: y=%0d zero=%0b", y, zero);

    a = 32'd10; b = 32'd3; op = ALU_SUB; #1;
    assert (y == 32'd7 && zero == 1'b0)
      else $fatal(1, "SUB failed: y=%0d zero=%0b", y, zero);

    a = 32'hF0F0; b = 32'h0FF0; op = ALU_AND; #1;
    assert (y == 32'h0000_00F0 && zero == 1'b0)
      else $fatal(1, "AND failed: y=%h zero=%0b", y, zero);

    a = 32'hF0F0; b = 32'h0FF0; op = ALU_OR; #1;
    assert (y == 32'h0000_FFF0 && zero == 1'b0)
      else $fatal(1, "OR failed: y=%h zero=%0b", y, zero);

    a = 32'hF0F0; b = 32'h0FF0; op = ALU_XOR; #1;
    assert (y == 32'h0000_FF00 && zero == 1'b0)
      else $fatal(1, "XOR failed: y=%h zero=%0b", y, zero);

    a = 32'd2; b = 32'd5; op = ALU_SLT; #1;
    assert (y == 32'd1 && zero == 1'b0)
      else $fatal(1, "SLT failed: y=%0d zero=%0b", y, zero);

    a = 32'hFFFF_FFFF; b = 32'd1; op = ALU_SLTU; #1;
    assert (y == 32'd0 && zero == 1'b1)
      else $fatal(1, "SLTU failed: y=%0d zero=%0b", y, zero);

    a = 32'd1; b = 32'd4; op = ALU_SLL; #1;
    assert (y == 32'h0000_0010 && zero == 1'b0)
      else $fatal(1, "SLL failed: y=%h zero=%0b", y, zero);

    a = 32'h8000_0000; b = 32'd4; op = ALU_SRL; #1;
    assert (y == 32'h0800_0000 && zero == 1'b0)
      else $fatal(1, "SRL failed: y=%h zero=%0b", y, zero);

    a = 32'h8000_0000; b = 32'd4; op = ALU_SRA; #1;
    assert (y == 32'hF800_0000 && zero == 1'b0)
      else $fatal(1, "SRA failed: y=%h zero=%0b", y, zero);

    $finish;
  end

endmodule
