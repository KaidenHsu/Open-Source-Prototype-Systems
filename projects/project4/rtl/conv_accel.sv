module conv_accel (
    input  logic        clk,
    input  logic        reset,
    input  logic        valid,
    input  logic        write,
    input  logic [7:0]  addr,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [31:0] wdata,
    /* verilator lint_on UNUSEDSIGNAL */
    output logic [31:0] rdata
);
    localparam CTRL_OFFSET   = 8'h00;
    localparam STATUS_OFFSET = 8'h04;
    localparam RESULT_OFFSET = 8'h08;
    localparam PIXEL_BASE    = 8'h10;
    localparam KERNEL_BASE   = 8'h40;

    localparam DIM = 3;
    localparam PRECISION = 8;

    // TODO: Declare registers for nine input pixels, nine kernel coefficients,
    //       a signed 32-bit result register, busy/done flags, and optional latency counter.
    logic [31:0] ctrl;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [5:0] offset;
    /* verilator lint_on UNUSEDSIGNAL */
    logic [1:0] row, col;
    logic [PRECISION-1:0] pixels [0:DIM-1][0:DIM-1]; // unsigned image pixels
    logic signed [PRECISION-1:0] coefficients [0:DIM-1][0:DIM-1];
    logic signed [31:0] result_comb;
    logic signed [31:0] result;
    logic [31:0] status; // busy, done
    logic [31:0] latency;
    int i, j, k, l;

    // FSM
    typedef enum logic [1:0] { S_INPUT, S_BUSY, S_DONE } state_t;
    state_t state, n_state;

    always_ff @(posedge clk) begin
        if (reset) state <= S_INPUT;
        else state <= n_state;
    end

    always_comb begin
        unique case (state)
            // TODO: When CTRL bit 0 is written as 1, start one convolution operation.
            S_INPUT: n_state = (valid & ctrl[0])? S_BUSY : S_INPUT;
            S_BUSY: n_state = S_DONE;
            S_DONE: n_state = S_INPUT;
            default: n_state = S_INPUT;
        endcase
    end

    // ctrl
    always_ff @(posedge clk) begin
        if (reset) ctrl <= 0;
        else begin
            unique case (state)
                S_INPUT: ctrl[0] <= ((addr == CTRL_OFFSET) && valid && write && wdata[0]);
                S_BUSY, S_DONE: ctrl <= 0;
                default: ctrl <= 0;
            endcase
        end
    end

    // offset, row, col
    always_comb begin
        /* verilator lint_off WIDTHTRUNC */
        if (addr >= PIXEL_BASE && addr < PIXEL_BASE + 4*9) begin
            offset = addr - PIXEL_BASE;
            row = offset[5:2] / DIM;
            col = offset[5:2] % DIM;
        end else if (addr >= KERNEL_BASE && addr < KERNEL_BASE + 4*9) begin
            offset = addr - KERNEL_BASE;
            row = offset[5:2] / DIM;
            col = offset[5:2] % DIM;
        end else begin
            {offset, row, col} = 0;
        end
        /* verilator lint_on WIDTHTRUNC */
    end

    // TODO: Implement writes to PIXEL0..PIXEL8 and KERNEL0..KERNEL8.
    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < DIM; i++) begin
                for (j = 0; j < DIM; j++) begin
                    pixels[i][j] <= 0;
                    coefficients[i][j] <= 0;
                end
            end
        end else begin
            if (state == S_INPUT && valid && write) begin
                if (addr >= PIXEL_BASE && addr < PIXEL_BASE + 4*9) begin
                    pixels[row][col] <= wdata[7:0];
                end else if (addr >= KERNEL_BASE && addr < KERNEL_BASE + 4*9) begin
                    coefficients[row][col] <= wdata[7:0];
                end
            end
        end
    end

    // TODO: Compute signed 3x3 convolution:
    //       result = sum(pixel[i] * kernel[i]) for i = 0..8.
    always_ff @(posedge clk) begin
        if (reset) result <= 0;
        else result <= result_comb;
    end

    always_comb begin
        result_comb = 0;
        for (k = 0; k < DIM; k++) begin
            for (l = 0; l < DIM; l++) begin
                result_comb += $signed({1'b0, pixels[k][l]}) * coefficients[k][l];
            end
        end
    end

    // TODO: STATUS must return bit0=done and bit1=busy.
    assign status = {30'b0, (state == S_BUSY), (state == S_DONE)};

    // register map
    always_comb begin
        unique case (addr)
            CTRL_OFFSET:   rdata = ctrl;
            STATUS_OFFSET: rdata = status;
            RESULT_OFFSET: rdata = result;
            default:       rdata = 32'd0;
        endcase
    end

    // latency
    always_ff @(posedge clk) begin
        if (reset) latency <= 0;
        else begin
            case (state)
                S_INPUT: latency <= 0;
                S_BUSY: latency <= latency+1;
                default: latency <= latency;
            endcase
        end
    end
endmodule
