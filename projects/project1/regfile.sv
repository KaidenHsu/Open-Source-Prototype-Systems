module regfile(
    input  logic        clk,
    input  logic        reset,
    input  logic        RegWrite,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] write_data,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);

    logic [31:0] regs [0:31];
    integer i;

    // TODO: Implement the sequential write and reset behavior.
    // Required behavior:
    // - Reset all registers to zero
    // - On RegWrite, write write_data into regs[rd] on the clock edge
    // - Register x0 must always remain zero
    
    // regs
    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i++) begin
                regs[i] <= 0;
            end
        end else begin
            if (RegWrite) begin
                regs[rd] <= write_data;
            end
        end
    end

    // TODO: Implement the two combinational read ports.
    // Required behavior:
    // - read_data1 returns regs[rs1], except x0 must read as 0
    // - read_data2 returns regs[rs2], except x0 must read as 0
    assign read_data1 = (rs1 == 5'd0)? 32'd0 : regs[rs1];
    assign read_data2 = (rs2 == 5'd0)? 32'd0 : regs[rs2];

endmodule
