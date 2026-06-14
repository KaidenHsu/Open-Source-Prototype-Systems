`timescale 1ns/1ps

module tiny_system_todo #(
  parameter int ADDR_W = 8,
  parameter int DATA_W = 32
)(
  input  logic              clk,
  input  logic              rst,

  // core 0 interface
  input  logic              c0_req_valid,
  input  logic              c0_req_write,
  input  logic [ADDR_W-1:0] c0_req_addr,
  input  logic [DATA_W-1:0] c0_req_wdata,
  output logic              c0_resp_valid,
  output logic [DATA_W-1:0] c0_resp_rdata,

  // core 1 interface
  input  logic              c1_req_valid,
  input  logic              c1_req_write,
  input  logic [ADDR_W-1:0] c1_req_addr,
  input  logic [DATA_W-1:0] c1_req_wdata,
  output logic              c1_resp_valid,
  output logic [DATA_W-1:0] c1_resp_rdata,

  // debug ports
  output logic [DATA_W-1:0] debug_mem_24,
  output logic              debug_c0_valid,
  output logic [ADDR_W-1:0] debug_c0_tag,
  output logic [DATA_W-1:0] debug_c0_data,
  output logic              debug_c1_valid,
  output logic [ADDR_W-1:0] debug_c1_tag,
  output logic [DATA_W-1:0] debug_c1_data,
  output logic              debug_c0_inv_valid,
  output logic [ADDR_W-1:0] debug_c0_inv_addr,
  output logic              debug_c1_inv_valid,
  output logic [ADDR_W-1:0] debug_c1_inv_addr,
  output logic              debug_snoop_to_c0_valid,
  output logic [ADDR_W-1:0] debug_snoop_to_c0_addr,
  output logic              debug_snoop_to_c1_valid,
  output logic [ADDR_W-1:0] debug_snoop_to_c1_addr
);

  // main memory
  logic [DATA_W-1:0] mem [0:255];

  logic [DATA_W-1:0] c0_mem_rdata;
  logic [DATA_W-1:0] c1_mem_rdata;
  logic              c0_mem_we;
  logic [ADDR_W-1:0] c0_mem_waddr;
  logic [DATA_W-1:0] c0_mem_wdata;
  logic              c1_mem_we;
  logic [ADDR_W-1:0] c1_mem_waddr;
  logic [DATA_W-1:0] c1_mem_wdata;

  logic              c0_inv_valid;
  logic [ADDR_W-1:0] c0_inv_addr;
  logic              c1_inv_valid;
  logic [ADDR_W-1:0] c1_inv_addr;

  logic              snoop_to_c0_valid;
  logic [ADDR_W-1:0] snoop_to_c0_addr;
  logic              snoop_to_c1_valid;
  logic [ADDR_W-1:0] snoop_to_c1_addr;

  assign c0_mem_rdata = mem[c0_req_addr];
  assign c1_mem_rdata = mem[c1_req_addr];

  // --------------------------------------------------------------------------
  // STUDENT TODO AREA: three integration bugs are seeded below.
  // Do not edit tiny_cache.sv or the testbench.
  //
  // Correct interface contract:
  //   Core 0 write -> invalidate Core 1 using the full write address.
  //   Core 1 write -> invalidate Core 0 using the full write address.
  // --------------------------------------------------------------------------

  // TODO 1: Core 1 write invalidation is accidentally suppressed.
  // Correct fix: assign snoop_to_c0_valid = c1_inv_valid;
  assign snoop_to_c0_valid = c1_inv_valid;
  // assign snoop_to_c0_valid = 1'b0; // bug 1: c1 write invalidation toward c0 is suppressed

  // TODO 2: Core 1 invalidation address is accidentally truncated.
  // Correct fix: assign snoop_to_c0_addr = c1_inv_addr;
  assign snoop_to_c0_addr = c1_inv_addr;
  // assign snoop_to_c0_addr  = {4'b0000, c1_inv_addr[3:0]}; // bug 2: c1 invalidation addr towards c0 is truncated

  // TODO 3: Core 0 invalidation address is accidentally truncated.
  // Correct fix: assign snoop_to_c1_addr = c0_inv_addr;
  assign snoop_to_c1_valid = c0_inv_valid;
  assign snoop_to_c1_addr = c0_inv_addr;
  // assign snoop_to_c1_addr  = {4'b0000, c0_inv_addr[3:0]}; // bug 3: c0 invalidation addr toward c1 is truncated

  // --------------------------------------------------------------------------
  // End of student TODO area.
  // --------------------------------------------------------------------------

  tiny_cache #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .CORE_ID(0)) cache0 (
    .clk(clk), .rst(rst),
    .core_req_valid(c0_req_valid), .core_req_write(c0_req_write),
    .core_req_addr(c0_req_addr), .core_req_wdata(c0_req_wdata),
    .core_resp_valid(c0_resp_valid), .core_resp_rdata(c0_resp_rdata),
    .mem_rdata(c0_mem_rdata), .mem_we(c0_mem_we),
    .mem_waddr(c0_mem_waddr), .mem_wdata(c0_mem_wdata),
    .inv_req_valid(c0_inv_valid), .inv_req_addr(c0_inv_addr),
    .snoop_inv_valid(snoop_to_c0_valid), .snoop_inv_addr(snoop_to_c0_addr),
    .debug_valid(debug_c0_valid), .debug_tag(debug_c0_tag), .debug_data(debug_c0_data)
  );

  tiny_cache #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .CORE_ID(1)) cache1 (
    .clk(clk), .rst(rst),
    .core_req_valid(c1_req_valid), .core_req_write(c1_req_write),
    .core_req_addr(c1_req_addr), .core_req_wdata(c1_req_wdata),
    .core_resp_valid(c1_resp_valid), .core_resp_rdata(c1_resp_rdata),
    .mem_rdata(c1_mem_rdata), .mem_we(c1_mem_we),
    .mem_waddr(c1_mem_waddr), .mem_wdata(c1_mem_wdata),
    .inv_req_valid(c1_inv_valid), .inv_req_addr(c1_inv_addr),
    .snoop_inv_valid(snoop_to_c1_valid), .snoop_inv_addr(snoop_to_c1_addr),
    .debug_valid(debug_c1_valid), .debug_tag(debug_c1_tag), .debug_data(debug_c1_data)
  );

  integer i;
  initial begin
    for (i = 0; i < 256; i = i + 1) begin
      mem[i] = '0;
    end
    mem[8'h24] = 32'd10;
  end

  always_ff @(posedge clk) begin
    if (!rst) begin
      if (c0_mem_we) begin
        mem[c0_mem_waddr] <= c0_mem_wdata;
      end
      if (c1_mem_we) begin
        mem[c1_mem_waddr] <= c1_mem_wdata;
      end
    end
  end

  assign debug_mem_24 = mem[8'h24];
  assign debug_c0_inv_valid = c0_inv_valid;
  assign debug_c0_inv_addr = c0_inv_addr;
  assign debug_c1_inv_valid = c1_inv_valid;
  assign debug_c1_inv_addr = c1_inv_addr;
  assign debug_snoop_to_c0_valid = snoop_to_c0_valid;
  assign debug_snoop_to_c0_addr = snoop_to_c0_addr;
  assign debug_snoop_to_c1_valid = snoop_to_c1_valid;
  assign debug_snoop_to_c1_addr = snoop_to_c1_addr;

endmodule
