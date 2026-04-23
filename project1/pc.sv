module pc(
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] pc_in,
    output logic [31:0] pc_out
);

    // TODO: Implement the program counter register.
    // Required behavior:
    // - On reset, set pc_out to 32'b0
    // - Otherwise, on the active clock edge, load pc_in into pc_out
    always_ff @( posedge clk ) begin
        if (reset) pc_out <= 0;
        else pc_out <= pc_in;
    end
endmodule
