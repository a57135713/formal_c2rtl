//------------------------------------------------------------------------------
// fir_filter.sv — 8-tap FIR filter, 4-stage pipeline
//------------------------------------------------------------------------------
// Matches C reference model: c_model/fir_filter.cpp
//
// Pipeline stages:
//   S1: shift register — latch input, shift delay line
//   S2: multiply      — 8 parallel 16×16→32 multipliers
//   S3: sum           — adder tree (8→4→2→1)
//   S4: quantize      — arithmetic right shift 16, output register
//
// Latency: 4 cycles from data_in to data_out
//------------------------------------------------------------------------------

module fir_filter (
    input  logic        clk,
    input  logic        rst_n,

    // data input
    input  logic [15:0] data_in,          // signed 16-bit sample
    input  logic        data_in_valid,

    // coefficients (static, set before operation)
    input  logic [15:0] coeff [0:7],      // 8 signed 16-bit coefficients

    // data output (4-cycle pipeline latency)
    output logic [31:0] data_out,         // signed 32-bit quantized result
    output logic        data_out_valid
);

    //--------------------------------------------------------------------------
    // Stage 1: Shift Register
    //--------------------------------------------------------------------------
    logic [15:0] state_reg [0:7];         // delay line (same as C state[])
    logic        s1_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 8; i++) state_reg[i] <= 16'd0;
            s1_valid <= 1'b0;
        end else begin
            // shift: state[7]←state[6], ..., state[0]←data_in
            for (int i = 7; i > 0; i--) state_reg[i] <= state_reg[i-1];
            state_reg[0] <= data_in;
            s1_valid <= data_in_valid;
        end
    end

    //--------------------------------------------------------------------------
    // Stage 2: Multiply (8 parallel 16×16 signed multipliers)
    //--------------------------------------------------------------------------
    logic signed [31:0] mult [0:7];       // 8 products
    logic               s2_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 8; i++) mult[i] <= 32'd0;
            s2_valid <= 1'b0;
        end else begin
            for (int i = 0; i < 8; i++)
                mult[i] <= $signed(state_reg[i]) * $signed(coeff[i]);
            s2_valid <= s1_valid;
        end
    end

    //--------------------------------------------------------------------------
    // Stage 3: Sum — adder tree (8→4→2→1)
    //--------------------------------------------------------------------------
    logic signed [34:0] sum_l1 [0:3];     // level 1: 32b + 32b → 33b, headroom→34b
    logic signed [35:0] sum_l2 [0:1];     // level 2: 34b + 34b → 35b
    logic signed [36:0] sum_total;        // level 3: 35b + 35b → 36b
    logic               s3_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 4; i++) sum_l1[i] <= 35'd0;
            sum_l2[0] <= 36'd0;
            sum_l2[1] <= 36'd0;
            sum_total <= 37'd0;
            s3_valid <= 1'b0;
        end else begin
            // level 1: 8 → 4
            for (int i = 0; i < 4; i++)
                sum_l1[i] <= $signed(mult[2*i]) + $signed(mult[2*i+1]);

            // level 2: 4 → 2
            sum_l2[0] <= $signed(sum_l1[0]) + $signed(sum_l1[1]);
            sum_l2[1] <= $signed(sum_l1[2]) + $signed(sum_l1[3]);

            // level 3: 2 → 1
            sum_total <= $signed(sum_l2[0]) + $signed(sum_l2[1]);

            s3_valid <= s2_valid;
        end
    end

    //--------------------------------------------------------------------------
    // Stage 4: Quantize — arithmetic right shift 16
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out       <= 32'd0;
            data_out_valid <= 1'b0;
        end else begin
            // arithmetic shift: preserve sign, matches C: acc >> 16
            data_out       <= sum_total >>> 16;
            data_out_valid <= s3_valid;
        end
    end

endmodule
