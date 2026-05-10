module one_pulser(
    input clk, reset,

    input cpu_req,
    input [31:0] cpu_addr,

    output one_pulsed_req
);
    logic prev_req;
    logic [31:0] prev_addr;

    // prev_req
    always_ff @(posedge clk) begin
        if (reset) prev_req  <= 0;
        else prev_req <= cpu_req;
    end

    // prev_addr
    always_ff @(posedge clk) begin
        if (reset) prev_addr  <= 0;
        else prev_addr <= cpu_addr;
    end

    // one_pulsed_req
    assign one_pulsed_req = (
        (cpu_req & ~prev_req) |
        (cpu_req & prev_req & (cpu_addr != prev_addr))
    );
endmodule
