module soc_top(
    input  logic        clk,
    input  logic        reset,
    output logic        halted,
    output logic [31:0] cycle_count,
    output logic [31:0] retired_count,
    output logic [31:0] access_count,
    output logic [31:0] read_count,
    output logic [31:0] write_count,
    output logic [31:0] hit_count,
    output logic [31:0] miss_count
);
    logic [31:0] imem_addr, imem_rdata;
    logic        dmem_req, dmem_we, mem_req, mem_we;
    logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    logic        dmem_ready, mem_ready;
    logic [31:0] mem_addr, mem_wdata, mem_rdata;

    rv32i_core u_core(
        .clk(clk), .reset(reset), .halted(halted),
        .cycle_count(cycle_count), .retired_count(retired_count),
        .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .dmem_req(dmem_req), .dmem_we(dmem_we), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata), .dmem_ready(dmem_ready)
    );

    instr_rom u_imem(
        .addr(imem_addr), .instr(imem_rdata)
    );

    memory_hierarchy u_hierarchy(
        .clk(clk), .reset(reset),
        .core_req(dmem_req), .core_we(dmem_we), .core_addr(dmem_addr), .core_wdata(dmem_wdata),
        .core_rdata(dmem_rdata), .core_ready(dmem_ready),
        .mem_req(mem_req), .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata), .mem_ready(mem_ready),
        .access_count(access_count), .read_count(read_count), .write_count(write_count),
        .hit_count(hit_count), .miss_count(miss_count)
    );

    backing_ram #(.LATENCY(3)) u_dram(
        .clk(clk), .reset(reset), .req(mem_req), .we(mem_we), .addr(mem_addr), .wdata(mem_wdata),
        .rdata(mem_rdata), .ready(mem_ready)
    );
endmodule
