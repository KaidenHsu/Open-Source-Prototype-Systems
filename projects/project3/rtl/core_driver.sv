`timescale 1ns/1ps

module core_driver #(
    parameter CORE_ID = 0,
    parameter VARIANT = 0,
    parameter ITERATIONS = 16,
    parameter AW = 8,
    parameter DW = 32
)(
    input  logic clk,
    input  logic reset,

    output logic        req_valid,
    output logic        req_write,
    output logic [AW-1:0] req_addr,
    output logic [DW-1:0] req_wdata,
    input  logic        req_ready,
    input  logic [DW-1:0] resp_rdata,

    output logic done,
    output logic [31:0] op_count
);
    typedef enum logic [1:0] {S_LOAD, S_STORE, S_NEXT, S_DONE} state_t;
    state_t state;

    logic [31:0] iter;
    logic [DW-1:0] loaded;
    logic [AW-1:0] current_addr;
    logic [AW-1:0] trace_addr [0:ITERATIONS-1];
    string trace_file;
    integer t;

    initial begin
        for (t = 0; t < ITERATIONS; t = t + 1) begin
            trace_addr[t] = '0;
        end

        case (VARIANT)
            0: trace_file = (CORE_ID == 0) ? "workloads/shared_bins_core0.trace"  : "workloads/shared_bins_core1.trace";
            1: trace_file = (CORE_ID == 0) ? "workloads/false_sharing_core0.trace": "workloads/false_sharing_core1.trace";
            2: trace_file = (CORE_ID == 0) ? "workloads/padded_bins_core0.trace"   : "workloads/padded_bins_core1.trace";
            3: trace_file = (CORE_ID == 0) ? "workloads/local_bins_core0.trace"    : "workloads/local_bins_core1.trace";
            default: trace_file = (CORE_ID == 0) ? "workloads/shared_bins_core0.trace"  : "workloads/shared_bins_core1.trace";
        endcase

        $display("Core %0d loading workload trace: %s", CORE_ID, trace_file);
        $readmemh(trace_file, trace_addr);
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= S_LOAD;
            iter <= 0;
            loaded <= 0;
            current_addr <= trace_addr[0];
            done <= 1'b0;
            op_count <= 0;
        end else begin
            case (state)
                S_LOAD: begin
                    current_addr <= trace_addr[iter];
                    if (req_ready) begin
                        loaded <= resp_rdata;
                        op_count <= op_count + 1;
                        state <= S_STORE;
                    end
                end
                S_STORE: begin
                    if (req_ready) begin
                        op_count <= op_count + 1;
                        state <= S_NEXT;
                    end
                end
                S_NEXT: begin
                    if (iter == ITERATIONS-1) begin
                        done <= 1'b1;
                        state <= S_DONE;
                    end else begin
                        iter <= iter + 1;
                        state <= S_LOAD;
                    end
                end
                default: done <= 1'b1;
            endcase
        end
    end

    always_comb begin
        req_valid = (state == S_LOAD) || (state == S_STORE);
        req_write = (state == S_STORE);
        req_addr  = (state == S_LOAD) ? trace_addr[iter] : current_addr;
        req_wdata = loaded + 1;
    end
endmodule
