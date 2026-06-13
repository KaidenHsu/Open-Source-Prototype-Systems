module project4_top (
    input  logic clk,
    input  logic reset,
    output logic halted
);
    logic [31:0] imem_addr, imem_rdata;
    logic        dmem_valid, dmem_write;
    logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;

    logic        ram_valid, ram_write;
    logic [31:0] ram_addr, ram_wdata, ram_rdata;
    logic        accel_valid, accel_write;
    logic [7:0]  accel_addr;
    logic [31:0] accel_wdata, accel_rdata;

    // single-cycle RV32I pipeline core
    rv32i_core core (
        .clk(clk), .reset(reset),
        .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .dmem_valid(dmem_valid), .dmem_write(dmem_write), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_rdata(dmem_rdata),
        .halted(halted)
    );

    instr_mem #(
        .INIT_FILE("rtl/program_conv.hex")
    ) imem (
        .addr(imem_addr), .rdata(imem_rdata)
    );

    mmio_decoder decoder (
        // .clk(clk),
        .valid(dmem_valid), .write(dmem_write), .addr(dmem_addr), .wdata(dmem_wdata), .rdata(dmem_rdata), // cpu side
        .ram_valid(ram_valid), .ram_write(ram_write), .ram_addr(ram_addr), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata), // ram side
        .accel_valid(accel_valid), .accel_write(accel_write), .accel_addr(accel_addr), .accel_wdata(accel_wdata), .accel_rdata(accel_rdata) // accel side
    );

    data_mem data_memory (
        .clk(clk), 
        .valid(ram_valid), .write(ram_write), .addr(ram_addr), .wdata(ram_wdata), .rdata(ram_rdata)
    );

    conv_accel accel (
        .clk(clk), .reset(reset),
        .valid(accel_valid), .write(accel_write), .addr(accel_addr), .wdata(accel_wdata), .rdata(accel_rdata)
    );
endmodule
