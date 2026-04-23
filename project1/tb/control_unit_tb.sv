module control_unit_tb;

	logic [6:0] opcode;
	logic [2:0] funct3;
	logic [6:0] funct7;

	logic       RegWrite;
	logic       MemRead;
	logic       MemWrite;
	logic [1:0] ResultSel;
	logic [1:0] ALUSrc;
	logic [2:0] ImmSel;
	logic [3:0] ALUControl;
	logic       Branch;
	logic       Jump;

	control_unit dut (
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

	task automatic check(
		input logic [6:0] stim_opcode,
		input logic [2:0] stim_funct3,
		input logic [6:0] stim_funct7,

		input logic       exp_RegWrite,
		input logic       exp_MemRead,
		input logic       exp_MemWrite,
		input logic [1:0] exp_ResultSel,
		input logic [1:0] exp_ALUSrc,
		input logic [2:0] exp_ImmSel,
		input logic [3:0] exp_ALUControl,
		input logic       exp_Branch,
		input logic       exp_Jump,
		input string      name
	);
		begin
			opcode = stim_opcode;
			funct3 = stim_funct3;
			funct7 = stim_funct7;
			#1; // delta cycle

			assert (RegWrite === exp_RegWrite)
				else $fatal(1, "%s: RegWrite failed (got=%0b exp=%0b)", name, RegWrite, exp_RegWrite);
			assert (MemRead === exp_MemRead)
				else $fatal(1, "%s: MemRead failed (got=%0b exp=%0b)", name, MemRead, exp_MemRead);
			assert (MemWrite === exp_MemWrite)
				else $fatal(1, "%s: MemWrite failed (got=%0b exp=%0b)", name, MemWrite, exp_MemWrite);
			assert (ResultSel === exp_ResultSel)
				else $fatal(1, "%s: ResultSel failed (got=%0d exp=%0d)", name, ResultSel, exp_ResultSel);
			assert (ALUSrc === exp_ALUSrc)
				else $fatal(1, "%s: ALUSrc failed (got=%0d exp=%0d)", name, ALUSrc, exp_ALUSrc);
			assert (ImmSel === exp_ImmSel)
				else $fatal(1, "%s: ImmSel failed (got=%0d exp=%0d)", name, ImmSel, exp_ImmSel);
			assert (ALUControl === exp_ALUControl)
				else $fatal(1, "%s: ALUControl failed (got=%0d exp=%0d)", name, ALUControl, exp_ALUControl);
			assert (Branch === exp_Branch)
				else $fatal(1, "%s: Branch failed (got=%0b exp=%0b)", name, Branch, exp_Branch);
			assert (Jump === exp_Jump)
				else $fatal(1, "%s: Jump failed (got=%0b exp=%0b)", name, Jump, exp_Jump);
		end
	endtask

	initial begin
		// R-type ALU instructions
		check(7'b011_0011, 3'b000, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, 3'd5, 4'd0, 1'b0, 1'b0, "add");
		check(7'b011_0011, 3'b000, 7'b010_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, 3'd5, 4'd1, 1'b0, 1'b0, "sub");
		check(7'b011_0011, 3'b111, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, 3'd5, 4'd4, 1'b0, 1'b0, "and");
		check(7'b011_0011, 3'b110, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, 3'd5, 4'd3, 1'b0, 1'b0, "or");
		check(7'b011_0011, 3'b100, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, 3'd5, 4'd2, 1'b0, 1'b0, "xor");
		check(7'b011_0011, 3'b001, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, 3'd5, 4'd5, 1'b0, 1'b0, "sll");
		check(7'b011_0011, 3'b101, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, 3'd5, 4'd6, 1'b0, 1'b0, "srl");
		check(7'b011_0011, 3'b101, 7'b010_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, 3'd5, 4'd7, 1'b0, 1'b0, "sra");
		check(7'b011_0011, 3'b010, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, 3'd5, 4'd8, 1'b0, 1'b0, "slt");
		check(7'b011_0011, 3'b011, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd0, 3'd5, 4'd9, 1'b0, 1'b0, "sltu");

		// I-type ALU-immediate instructions
		check(7'b001_0011, 3'b000, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd1, 3'd0, 4'd0, 1'b0, 1'b0, "addi");
		check(7'b001_0011, 3'b111, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd1, 3'd0, 4'd4, 1'b0, 1'b0, "andi");
		check(7'b001_0011, 3'b110, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd1, 3'd0, 4'd3, 1'b0, 1'b0, "ori");
		check(7'b001_0011, 3'b100, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd1, 3'd0, 4'd2, 1'b0, 1'b0, "xori");
		check(7'b001_0011, 3'b001, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd1, 3'd0, 4'd5, 1'b0, 1'b0, "slli");
		check(7'b001_0011, 3'b101, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd1, 3'd0, 4'd6, 1'b0, 1'b0, "srli");
		check(7'b001_0011, 3'b101, 7'b010_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd1, 3'd0, 4'd7, 1'b0, 1'b0, "srai");
		check(7'b001_0011, 3'b010, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd1, 3'd0, 4'd8, 1'b0, 1'b0, "slti");
		check(7'b001_0011, 3'b011, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd0, 2'd1, 3'd0, 4'd9, 1'b0, 1'b0, "sltiu");

		// Memory instructions
		check(7'b000_0011, 3'b010, 7'b000_0000, 1'b1, 1'b1, 1'b0, 2'd1, 2'd1, 3'd0, 4'd0, 1'b0, 1'b0, "lw");
		check(7'b010_0011, 3'b010, 7'b000_0000, 1'b0, 1'b0, 1'b1, 2'd0, 2'd1, 3'd1, 4'd0, 1'b0, 1'b0, "sw");

		// Branches
		check(7'b110_0011, 3'b000, 7'b000_0000, 1'b0, 1'b0, 1'b0, 2'd3, 2'd0, 3'd2, 4'd10, 1'b1, 1'b0, "beq");
		check(7'b110_0011, 3'b001, 7'b000_0000, 1'b0, 1'b0, 1'b0, 2'd3, 2'd0, 3'd2, 4'd10, 1'b1, 1'b0, "bne");
		check(7'b110_0011, 3'b100, 7'b000_0000, 1'b0, 1'b0, 1'b0, 2'd3, 2'd0, 3'd2, 4'd10, 1'b1, 1'b0, "blt");
		check(7'b110_0011, 3'b101, 7'b000_0000, 1'b0, 1'b0, 1'b0, 2'd3, 2'd0, 3'd2, 4'd10, 1'b1, 1'b0, "bge");

		// Jump
		check(7'b110_1111, 3'b000, 7'b000_0000, 1'b1, 1'b0, 1'b0, 2'd2, 2'd2, 3'd4, 4'd10, 1'b0, 1'b1, "jal");

		$finish;
	end

endmodule
