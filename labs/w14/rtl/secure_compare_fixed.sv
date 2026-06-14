`timescale 1ns/1ps

// Student task: replace the insecure early-exit behavior with fixed-latency
// comparison and safe public debug behavior.
module secure_compare_fixed #(
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

    // TODO: Add a mismatch accumulator such as:
    // logic mismatch_seen;
    // It should become 1 once any byte mismatches, but the module should still
    // continue scanning all bytes.
    logic mismatch_seen;

    always_ff @(posedge clk) begin
        if (rst) begin
            running     <= 1'b0;
            idx         <= '0;
            done        <= 1'b0;
            match       <= 1'b0;
            debug_count <= 8'd0;
            // TODO: Reset your mismatch accumulator here.
            mismatch_seen <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !running) begin
                running     <= 1'b1;
                idx         <= '0;
                match       <= 1'b0;
                debug_count <= 8'd0;
                // TODO: Clear your mismatch accumulator here.
                mismatch_seen <= 1'b0;
            end else if (running) begin
                // TODO: Public debug_count should not expose byte progress.
                // A safe simple policy is to keep it constant, e.g., 0, until
                // the design is extended with privilege-gated debug access.
                // debug_count <= {{(8-IDX_W){1'b0}}, idx};
                debug_count <= 8'd0;

                // TODO: Remove the early exit below.
                // Required behavior:
                //   1. Process every byte for every request.
                //   2. Assert done only at the fixed final cycle.
                //   3. Set match to 1 only if no byte mismatched.

                // if (!byte_equal || last_byte) begin
                //     running <= 1'b0;
                //     done    <= 1'b1;
                //     match   <= byte_equal && last_byte;
                // end else begin
                //     idx <= idx + IDX_W'(1);
                // end

                if (last_byte) begin
                    running <= 1'b0;
                    done <= 1'b1;
                    match <= !(mismatch_seen || !byte_equal);
                end else begin
                    mismatch_seen <= (mismatch_seen || !byte_equal);
                    idx <= idx + IDX_W'(1);
                end
            end
        end
    end
endmodule
