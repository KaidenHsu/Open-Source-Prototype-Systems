`timescale 1ns/1ps

// Deliberately insecure design for Week 14 exercise.
// It exits as soon as a mismatching byte is found, so completion latency leaks
// the first mismatching byte position.
module secure_compare_buggy #(
    parameter int TOKEN_BYTES = 8,
    parameter logic [TOKEN_BYTES*8-1:0] SECRET_TOKEN = 64'h1122_3344_5566_7788
)(
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic [TOKEN_BYTES*8-1:0] candidate,
    output logic done,
    output logic match,
    output logic [7:0] debug_count
);
    localparam int IDX_W = (TOKEN_BYTES <= 2) ? 1 : $clog2(TOKEN_BYTES);
    localparam logic [IDX_W-1:0] LAST_BYTE_IDX = IDX_W'(TOKEN_BYTES - 1);

    logic running;
    logic [IDX_W-1:0] idx;

    wire [7:0] cand_byte   = candidate[idx*8 +: 8];
    wire [7:0] secret_byte = SECRET_TOKEN[idx*8 +: 8];
    wire byte_equal = (cand_byte == secret_byte);
    wire last_byte  = (idx == LAST_BYTE_IDX);

    always_ff @(posedge clk) begin
        if (rst) begin
            running     <= 1'b0;
            idx         <= '0;
            done        <= 1'b0;
            match       <= 1'b0;
            debug_count <= 8'd0;
        end else begin
            done <= 1'b0;

            if (start && !running) begin
                running     <= 1'b1;
                idx         <= '0;
                match       <= 1'b0;
                debug_count <= 8'd0;
            end else if (running) begin
                // BUG 1: Public debug_count reveals the current byte index.
                debug_count <= {{(8-IDX_W){1'b0}}, idx};

                // BUG 2: Early exit leaks mismatch position through done timing.
                if (!byte_equal || last_byte) begin
                    running <= 1'b0;
                    done    <= 1'b1;
                    match   <= byte_equal && last_byte;
                end else begin
                    idx <= idx + 1'b1;
                end
            end
        end
    end
endmodule
