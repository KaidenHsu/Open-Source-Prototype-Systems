module backing_ram #(
    parameter LATENCY = 3
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        req,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    output logic        ready
);
    logic [31:0] mem [0:255];
    integer i;
    logic busy;
    logic [31:0] addr_q, wdata_q;
    logic we_q;
    integer count;

    initial begin
        for (i = 0; i < 256; i++) mem[i] = 32'd0;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            busy  <= 1'b0;
            ready <= 1'b0;
            count <= 0;
            rdata <= 32'b0;
        end else begin
            ready <= 1'b0;
            if (!busy && req) begin
                busy    <= 1'b1;
                count   <= LATENCY;
                addr_q  <= addr;
                wdata_q <= wdata;
                we_q    <= we;
            end else if (busy) begin
                if (count > 1) begin
                    count <= count - 1;
                end else begin
                    busy  <= 1'b0;
                    ready <= 1'b1;
                    if (we_q) begin
                        mem[addr_q[9:2]] <= wdata_q;
                    end else begin
                        rdata <= mem[addr_q[9:2]];
                    end
                end
            end
        end
    end
endmodule
