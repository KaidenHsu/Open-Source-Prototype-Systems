module data_mem #(
    parameter WORDS = 256
)(
    input  logic        clk,
    input  logic        valid,
    input  logic        write,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [31:0] addr,
    /* verilator lint_on UNUSEDSIGNAL */
    input  logic [31:0] wdata,
    output logic [31:0] rdata
);
    logic [31:0] mem_array [0:WORDS-1];
    integer i;

    initial begin
        for (i = 0; i < WORDS; i = i + 1) mem_array[i] = 32'd0;
    end

    assign rdata = mem_array[addr[9:2]];

    always_ff @(posedge clk) begin
        if (valid && write) mem_array[addr[9:2]] <= wdata;
    end
endmodule
