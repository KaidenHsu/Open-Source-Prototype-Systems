module mux2(
    input  logic        sel,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    // TODO: Implement a 2-to-1 multiplexer.
    // Expected behavior: y = sel ? b : a
    assign y = (sel)? b : a;
endmodule
