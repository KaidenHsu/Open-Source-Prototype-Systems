module soc_top(
    input  logic        clk,
    input  logic        reset,
    output logic        halted,
    output logic [31:0] cycle_count,
    output logic [31:0] retired_count,
    output logic [31:0] dc_access_count,
    output logic [31:0] dc_hit_count,
    output logic [31:0] dc_miss_count
);
    logic        ic_req, ic_req_one_pulsed, ic_ready;
    logic [31:0] ic_addr, ic_rdata;
    logic        ic_mem_req, ic_mem_we;
    logic [31:0] ic_mem_addr;
    logic [127:0] ic_mem_wdata, ic_mem_rdata;
    logic        ic_mem_ready;

    logic        dc_req, dc_req_one_pulsed, dc_we, dc_ready;
    logic [31:0] dc_addr, dc_wdata, dc_rdata;
    logic        dc_mem_req, dc_mem_we;
    logic [31:0] dc_mem_addr;
    logic [127:0] dc_mem_wdata, dc_mem_rdata;
    logic        dc_mem_ready;

    logic [31:0] stall_cycles, branch_flush_cycles;
    logic [31:0] ic_hit_count, ic_miss_count, dc_read_count, dc_write_count;

    pipeline_core u_core(
        .clk(clk), .reset(reset), .halted(halted),
        .cycle_count(cycle_count), .retired_count(retired_count),
        .ic_req(ic_req), .ic_addr(ic_addr), .ic_rdata(ic_rdata), .ic_ready(ic_ready),
        .dc_req(dc_req), .dc_we(dc_we), .dc_addr(dc_addr), .dc_wdata(dc_wdata),
        .dc_rdata(dc_rdata), .dc_ready(dc_ready),
        .stall_cycles(stall_cycles), .branch_flush_cycles(branch_flush_cycles)
    );

    one_pulser u_ic_one_pulser(
        .clk(clk), .reset(reset),
        .cpu_req(ic_req),
        .cpu_addr(ic_addr),
        .one_pulsed_req(ic_req_one_pulsed)
    );

    icache #(
        .USE_PASSTHRU(0)
    ) u_icache (
        .clk(clk), .reset(reset),
        .cpu_req(ic_req_one_pulsed), .cpu_addr(ic_addr), .cpu_rdata(ic_rdata), .cpu_ready(ic_ready),
        .mem_req(ic_mem_req), .mem_we(ic_mem_we), .mem_addr(ic_mem_addr), .mem_wdata(ic_mem_wdata),
        .mem_rdata(ic_mem_rdata), .mem_ready(ic_mem_ready),
        .hit_count(ic_hit_count), .miss_count(ic_miss_count)
    );

    one_pulser u_dc_one_pulser(
        .clk(clk), .reset(reset),
        .cpu_req(dc_req),
        .cpu_addr(dc_addr),
        .one_pulsed_req(dc_req_one_pulsed)
    );

    dcache #(
    ) u_dcache (
        .clk(clk), .reset(reset),
        .cpu_req(dc_req_one_pulsed), .cpu_we(dc_we), .cpu_addr(dc_addr), .cpu_wdata(dc_wdata),
        .cpu_rdata(dc_rdata), .cpu_ready(dc_ready),
        .mem_req(dc_mem_req), .mem_we(dc_mem_we), .mem_addr(dc_mem_addr), .mem_wdata(dc_mem_wdata),
        .mem_rdata(dc_mem_rdata), .mem_ready(dc_mem_ready),
        .access_count(dc_access_count), .read_count(dc_read_count), .write_count(dc_write_count),
        .hit_count(dc_hit_count), .miss_count(dc_miss_count)
    );

    // pure Harvard architecture
    backing_ram u_imem_back(
        .clk(clk), .req(ic_mem_req), .we(1'b0), .addr(ic_mem_addr), .wdata(128'b0),
        .rdata(ic_mem_rdata), .ready(ic_mem_ready)
    );

    backing_ram u_dmem_back(
        .clk(clk), .req(dc_mem_req), .we(dc_mem_we), .addr(dc_mem_addr), .wdata(dc_mem_wdata),
        .rdata(dc_mem_rdata), .ready(dc_mem_ready)
    );
endmodule
