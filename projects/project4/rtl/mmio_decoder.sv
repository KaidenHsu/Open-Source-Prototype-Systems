module mmio_decoder (
    // input  logic        clk,

    // cpu side
    input  logic        valid,
    input  logic        write,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,

    // ram side
    output logic        ram_valid,
    output logic        ram_write,
    output logic [31:0] ram_addr,
    output logic [31:0] ram_wdata,
    input  logic [31:0] ram_rdata,

    // accel side
    output logic        accel_valid,
    output logic        accel_write,
    output logic [7:0]  accel_addr,
    output logic [31:0] accel_wdata,
    input  logic [31:0] accel_rdata
);
    wire is_accel = addr[31:16] == 16'h8000;

    assign ram_valid   = valid && !is_accel;
    assign ram_write   = write;
    assign ram_addr    = addr;
    assign ram_wdata   = wdata;

    assign accel_valid = valid && is_accel;
    assign accel_write = write;
    assign accel_addr  = addr[7:0];
    assign accel_wdata = wdata;

    assign rdata       = is_accel ? accel_rdata : ram_rdata;
endmodule
