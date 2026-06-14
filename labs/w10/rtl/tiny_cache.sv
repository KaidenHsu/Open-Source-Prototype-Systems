`timescale 1ns/1ps

module tiny_cache #(
  parameter int ADDR_W = 8,
  parameter int DATA_W = 32,
  /* verilator lint_off UNUSEDPARAM */
  parameter int CORE_ID = 0
  /* verilator lint_off UNUSEDPARAM */
)(
  input  logic              clk,
  input  logic              rst,

  input  logic              core_req_valid,
  input  logic              core_req_write,
  input  logic [ADDR_W-1:0] core_req_addr,
  input  logic [DATA_W-1:0] core_req_wdata,
  output logic              core_resp_valid,
  output logic [DATA_W-1:0] core_resp_rdata,

  input  logic [DATA_W-1:0] mem_rdata,
  output logic              mem_we,
  output logic [ADDR_W-1:0] mem_waddr,
  output logic [DATA_W-1:0] mem_wdata,

  output logic              inv_req_valid,
  output logic [ADDR_W-1:0] inv_req_addr,

  input  logic              snoop_inv_valid,
  input  logic [ADDR_W-1:0] snoop_inv_addr,

  output logic              debug_valid,
  output logic [ADDR_W-1:0] debug_tag,
  output logic [DATA_W-1:0] debug_data
);

  logic              line_valid;
  logic [ADDR_W-1:0] line_tag;
  logic [DATA_W-1:0] line_data;
  logic              hit;

  assign hit = line_valid && (line_tag == core_req_addr);

  assign mem_we    = core_req_valid && core_req_write;
  assign mem_waddr = core_req_addr;
  assign mem_wdata = core_req_wdata;

  assign inv_req_valid = core_req_valid && core_req_write;
  assign inv_req_addr  = core_req_addr;

  assign core_resp_valid = core_req_valid;

  always_comb begin
    if (core_req_write) begin
      core_resp_rdata = core_req_wdata;
    end else if (hit) begin
      core_resp_rdata = line_data;
    end else begin
      core_resp_rdata = mem_rdata;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      line_valid <= 1'b0;
      line_tag   <= '0;
      line_data  <= '0;
    end else begin
      if (snoop_inv_valid && line_valid && (line_tag == snoop_inv_addr)) begin
        line_valid <= 1'b0;
      end

      if (core_req_valid) begin
        line_valid <= 1'b1;
        line_tag   <= core_req_addr;
        if (core_req_write) begin
          line_data <= core_req_wdata;
        end else if (!hit) begin
          line_data <= mem_rdata;
        end
      end
    end
  end

  assign debug_valid = line_valid;
  assign debug_tag   = line_tag;
  assign debug_data  = line_data;

endmodule
