`timescale 1ns/1ps

// ============================================================================
// COMPLETE RADIX-2 MULTI-MODE FOLDED FFT IMPLEMENTATION
// Educational Version with Extensive Comments
// 
// OVERVIEW:
// This is a 16-point FFT implementation using Radix-2 Decimation-In-Frequency
// (DIF) algorithm with a folded architecture. The design uses 8 butterfly units
// that are time-multiplexed to compute the complete FFT through multiple passes.
//
// KEY CONCEPTS:
// - Radix-2: Each butterfly processes 2 inputs
// - Folded: Hardware is reused across multiple FFT stages
// - Multi-mode: Different control signals select different operation modes
// - Packed format: Real and imaginary parts stored in single 16-bit word
//
// DATA FORMAT:
// - Each complex number is packed as [15:8]=Real(8-bit), [7:0]=Imag(8-bit)
// - Both real and imaginary parts are 8-bit signed integers
// ============================================================================


// ============================================================================
// MODULE 1: 2-to-1 MULTIPLEXER
// 
// PURPOSE: Selects between two 16-bit inputs based on control signal
// 
// PARAMETERS:
//   W = bit width (default 16)
//
// OPERATION:
//   sel=0 → output = in0
//   sel=1 → output = in1
// ============================================================================
module mux2to1 #(parameter W=16)(
    input [W-1:0] in0,      // First input
    input [W-1:0] in1,      // Second input
    input sel,               // Select signal
    output [W-1:0] out      // Output (selected input)
);
    // Combinational selection using ternary operator
    assign out = (sel == 1'b0) ? in0 : in1;
endmodule


// ============================================================================
// MODULE 2: 3-to-1 MULTIPLEXER
//
// PURPOSE: Selects between three 16-bit inputs based on 2-bit control signal
// Used for selecting between: fresh input, feedback data, or alternate routing
//
// OPERATION:
//   sel=00 → output = in0  (usually fresh input)
//   sel=01 → output = in1  (usually feedback from previous stage)
//   sel=10 → output = in2  (usually alternate routing)
//   sel=11 → output = 0    (default/safe state)
// ============================================================================
module mux3to1 #(parameter W=16)(
    input [W-1:0] in0,
    input [W-1:0] in1,
    input [W-1:0] in2,
    input [1:0] sel,         // 2-bit select (supports 4 states)
    output reg [W-1:0] out
);
    // Combinational always block for multiplexing
    always @(*) begin
        case(sel)
            2'b00: out = in0;
            2'b01: out = in1;
            2'b10: out = in2;
            default: out = {W{1'b0}};  // All zeros as safe default
        endcase
    end
endmodule


// ============================================================================
// MODULE 3: 4-to-1 MULTIPLEXER
//
// PURPOSE: Selects between four 16-bit inputs based on 2-bit control signal
// Provides maximum flexibility for multi-mode operation
//
// OPERATION:
//   sel=00 → output = in0
//   sel=01 → output = in1
//   sel=10 → output = in2
//   sel=11 → output = in3
// ============================================================================
module mux4to1 #(parameter W=16)(
    input [W-1:0] in0,
    input [W-1:0] in1,
    input [W-1:0] in2,
    input [W-1:0] in3,
    input [1:0] sel,
    output reg [W-1:0] out
);
    always @(*) begin
        case(sel)
            2'b00: out = in0;
            2'b01: out = in1;
            2'b10: out = in2;
            2'b11: out = in3;
            default: out = {W{1'b0}};
        endcase
    end
endmodule


// ============================================================================
// MODULE 4: COMPLEX MULTIPLIER (Fixed-Point Q1.15 Format)
//
// PURPOSE: Multiplies two complex numbers in fixed-point arithmetic
//
// THEORY:
// Complex multiplication: (a + jb) × (c + jd) = (ac - bd) + j(ad + bc)
//   Real part:      ac - bd
//   Imaginary part: ad + bc
//
// FIXED-POINT ARITHMETIC:
// - Inputs are 16-bit signed (Q1.15 format means 1 sign bit, 15 fractional bits)
// - Multiplication produces 32-bit result (Q2.30)
// - Right shift by 15 bits converts back to Q1.15 format
// - This maintains precision while preventing overflow
//
// EXAMPLE:
//   a_r = 0.5 (represented as 16384 in Q1.15)
//   b_r = 0.707 (represented as 23170 in Q1.15)
//   Product = 0.5 × 0.707 = 0.3535
//   Computation: (16384 × 23170) >> 15 = 11585 (≈ 0.3535 in Q1.15)
// ============================================================================
module complex_mult #(parameter W=16)(
    input signed [W-1:0] a_r,     // Real part of first operand
    input signed [W-1:0] a_i,     // Imaginary part of first operand
    input signed [W-1:0] b_r,     // Real part of second operand
    input signed [W-1:0] b_i,     // Imaginary part of second operand
    output signed [W-1:0] p_r,    // Real part of product
    output signed [W-1:0] p_i     // Imaginary part of product
);
    // Four multiplications needed for complex multiply
    // Each multiplication produces 32-bit result (16-bit × 16-bit = 32-bit)
    wire signed [2*W-1:0] mult_rr = a_r * b_r;  // Real × Real
    wire signed [2*W-1:0] mult_ii = a_i * b_i;  // Imag × Imag
    wire signed [2*W-1:0] mult_ri = a_r * b_i;  // Real × Imag
    wire signed [2*W-1:0] mult_ir = a_i * b_r;  // Imag × Real
    
    // Combine according to complex multiplication formula
    wire signed [2*W-1:0] result_r = mult_rr - mult_ii;  // Real result
    wire signed [2*W-1:0] result_i = mult_ri + mult_ir;  // Imaginary result

    // Scale back from Q2.30 to Q1.15 by right-shifting 15 bits
    // The >>> operator is arithmetic right shift (preserves sign)
    assign p_r = result_r >>> 15;
    assign p_i = result_i >>> 15;
endmodule


// ============================================================================
// MODULE 5: RADIX-2 DIF BUTTERFLY WITH PACKED COMPLEX FORMAT
//
// PURPOSE: Core computational element of the FFT
//
// RADIX-2 BUTTERFLY THEORY:
// The Radix-2 DIF butterfly is the fundamental building block of FFT algorithms.
// It takes two complex inputs (X0, X1) and produces two complex outputs (Y0, Y1):
//
//   Y0 = X0 + X1              (Addition path - no twiddle multiplication)
//   Y1 = (X0 - X1) × W^k      (Subtraction path - includes twiddle factor)
//
// Where W^k is the twiddle factor (complex exponential): W^k = e^(-j2πk/N)
//
// TWIDDLE FACTORS FOR 16-POINT FFT:
//   W^0 = e^(j0)      = 1 + j0         = (1.000, 0.000)
//   W^1 = e^(-jπ/8)   ≈ 0.924 - j0.383 ≈ (0.707, -0.707) simplified
//   W^2 = e^(-jπ/4)   ≈ 0.707 - j0.707 = (0.000, -1.000) approximation
//   W^3 = e^(-j3π/8)  ≈ 0.383 - j0.924 ≈ (-0.707, -0.707) simplified
//
// DATA PACKING:
// To save bandwidth, real and imaginary parts are packed into single 16-bit word:
//   Bits [15:8] = Real part (8-bit signed)
//   Bits [7:0]  = Imaginary part (8-bit signed)
//
// EXAMPLE:
//   Complex number: 5 + j(-3)
//   Packed format: {8'sd5, -8'sd3} = 16'h05FD
// ============================================================================
module butterfly_radix2_packed #(parameter W=16)(
    input [W-1:0] x0,              // First complex input (packed)
    input [W-1:0] x1,              // Second complex input (packed)
    input [1:0] twiddle_sel,       // Selects which twiddle factor to use
    
    // Four twiddle factor options (all packed format)
    input signed [W-1:0] m0,       // W^0 = 1 + j0
    input signed [W-1:0] m1,       // W^1
    input signed [W-1:0] m2,       // W^2
    input signed [W-1:0] m3,       // W^3
    
    output [W-1:0] y0,             // First complex output (packed)
    output [W-1:0] y1              // Second complex output (packed)
);

    // ========== STEP 1: UNPACK INPUT DATA ==========
    // Extract 8-bit real and imaginary components from packed 16-bit format
    wire signed [7:0] x0_re8 = x0[15:8];   // Upper 8 bits = Real part of x0
    wire signed [7:0] x0_im8 = x0[7:0];    // Lower 8 bits = Imag part of x0
    wire signed [7:0] x1_re8 = x1[15:8];   // Upper 8 bits = Real part of x1
    wire signed [7:0] x1_im8 = x1[7:0];    // Lower 8 bits = Imag part of x1
    
    // ========== STEP 2: SIGN-EXTEND TO 16-BIT ==========
    // We need to extend 8-bit signed values to 16-bit signed for arithmetic
    // Sign extension: replicate the MSB (sign bit) to fill upper bits
    // Example: 8'b1111_1010 (-6) → 16'b1111_1111_1111_1010 (-6)
    //          8'b0000_0101 (+5) → 16'b0000_0000_0000_0101 (+5)
    wire signed [15:0] x0_re = {{8{x0_re8[7]}}, x0_re8};  // Replicate sign bit 8 times
    wire signed [15:0] x0_im = {{8{x0_im8[7]}}, x0_im8};
    wire signed [15:0] x1_re = {{8{x1_re8[7]}}, x1_re8};
    wire signed [15:0] x1_im = {{8{x1_im8[7]}}, x1_im8};

    // ========== STEP 3: BUTTERFLY COMPUTATION ==========
    // Compute the two main butterfly operations
    
    // Addition path: Y0 = X0 + X1 (complex addition)
    wire signed [15:0] sum_re = x0_re + x1_re;  // Real part: Re{X0} + Re{X1}
    wire signed [15:0] sum_im = x0_im + x1_im;  // Imag part: Im{X0} + Im{X1}
    
    // Subtraction path: Difference = X0 - X1 (will be multiplied by twiddle)
    wire signed [15:0] diff_re = x0_re - x1_re; // Real part: Re{X0} - Re{X1}
    wire signed [15:0] diff_im = x0_im - x1_im; // Imag part: Im{X0} - Im{X1}

    // ========== STEP 4: TWIDDLE FACTOR SELECTION ==========
    // Use a multiplexer to select which twiddle factor to apply
    // This allows the same butterfly hardware to be used with different twiddles
    reg signed [W-1:0] twiddle_packed;
    
    always @(*) begin
        case(twiddle_sel)
            2'b00: twiddle_packed = m0;  // Select W^0
            2'b01: twiddle_packed = m1;  // Select W^1
            2'b10: twiddle_packed = m2;  // Select W^2
            2'b11: twiddle_packed = m3;  // Select W^3
        endcase
    end
    
    // ========== STEP 5: UNPACK AND EXTEND TWIDDLE FACTOR ==========
    wire signed [7:0] tw_re8 = twiddle_packed[15:8];  // Extract real part
    wire signed [7:0] tw_im8 = twiddle_packed[7:0];   // Extract imag part
    wire signed [15:0] tw_re = {{8{tw_re8[7]}}, tw_re8};  // Sign-extend
    wire signed [15:0] tw_im = {{8{tw_im8[7]}}, tw_im8};  // Sign-extend

    // ========== STEP 6: COMPLEX MULTIPLICATION ==========
    // Multiply the difference by the twiddle factor: Y1 = (X0 - X1) × W^k
    // This is the heart of the FFT butterfly computation
    wire signed [15:0] mult_re, mult_im;
    
    complex_mult #(.W(16)) cmult (
        .a_r(diff_re),        // Real part of difference
        .a_i(diff_im),        // Imaginary part of difference
        .b_r(tw_re),          // Real part of twiddle
        .b_i(tw_im),          // Imaginary part of twiddle
        .p_r(mult_re),        // Real part of product
        .p_i(mult_im)         // Imaginary part of product
    );

    // ========== STEP 7: SATURATION TO 8-BIT ==========
    // After computation, we need to convert 16-bit results back to 8-bit
    // Saturation prevents overflow by clamping values to [-128, +127] range
    //
    // WHY SATURATION?
    // - FFT operations can cause values to grow beyond 8-bit range
    // - Simply truncating would cause wraparound (e.g., 130 → -126)
    // - Saturation clips to max/min values, preserving signal characteristics
    //
    // EXAMPLE:
    //   Input:  150 (too large for 8-bit signed)
    //   Output: 127 (maximum positive 8-bit signed value)
    function [7:0] saturate8;
        input signed [15:0] value;
        begin
            if (value > 16'sd127)           // If too large
                saturate8 = 8'sd127;        // Clip to +127
            else if (value < -16'sd128)     // If too small
                saturate8 = -8'sd128;       // Clip to -128
            else
                saturate8 = value[7:0];     // Keep lower 8 bits
        end
    endfunction

    // ========== STEP 8: PACK OUTPUTS ==========
    // Convert 16-bit intermediate results back to packed 8-bit format
    wire [7:0] y0_re8 = saturate8(sum_re);    // Saturate real part of Y0
    wire [7:0] y0_im8 = saturate8(sum_im);    // Saturate imag part of Y0
    wire [7:0] y1_re8 = saturate8(mult_re);   // Saturate real part of Y1
    wire [7:0] y1_im8 = saturate8(mult_im);   // Saturate imag part of Y1
    
    // Pack the 8-bit components back into 16-bit words
    assign y0 = {y0_re8, y0_im8};  // Y0 = sum (no twiddle multiplication)
    assign y1 = {y1_re8, y1_im8};  // Y1 = product (after twiddle multiplication)

endmodule


// ============================================================================
// MODULE 6: TOP-LEVEL FFT CORE (16-POINT RADIX-2 MULTI-MODE FOLDED FFT)
//
// PURPOSE: Complete FFT processor with multi-mode operation capability
//
// ARCHITECTURE OVERVIEW:
// This is a "folded" FFT architecture, meaning it reuses hardware across
// multiple FFT stages through time-multiplexing. The 16-point FFT normally
// requires log2(16) = 4 stages, but we fold these stages to use only 8
// butterfly units that are reused multiple times.
//
// DATA FLOW:
// 1. Input Selection Stage:
//    - Multiple multiplexer layers (3-to-1, 2-to-1, 4-to-1)
//    - Select between: fresh inputs, feedback data, or alternate routing
//    - Different mode control signals (s1, s2, s3, sel) enable different
//      data flow patterns
//
// 2. Butterfly Processing:
//    - 8 Radix-2 butterflies operate in parallel
//    - Each butterfly processes 2 complex numbers
//    - Total: 16 complex numbers processed simultaneously
//
// 3. Feedback and Output:
//    - Results stored in registers
//    - Fed back to input multiplexers for next iteration
//    - Also presented as outputs
//
// MULTI-MODE OPERATION:
// Different combinations of control signals (s1, s2, s3, sel) create
// different data routing patterns, allowing:
//   - Different FFT sizes (16-point, 8-point, 4-point)
//   - Different stage processing
//   - Iterative computation through multiple passes
//
// FEEDBACK ARCHITECTURE:
// The feedback registers (fb0-fb15) store intermediate FFT results and
// feed them back to the input multiplexers. This allows the same butterfly
// hardware to be reused across multiple FFT stages, reducing hardware cost.
//
// TIMING:
// - 1 clock cycle: Input selection through multiplexers
// - 1 clock cycle: Butterfly computation
// - 1 clock cycle: Register update
// Total: 3 cycles per FFT stage, multiple stages for complete FFT
// ============================================================================
module top_radix2(
    input clk,                      // System clock
    input rst_n,                    // Active-low reset
    
    // ========== 16 COMPLEX INPUTS (PACKED FORMAT) ==========
    // Each input is 16 bits: [15:8]=Real, [7:0]=Imaginary
    input [15:0] i0, i1, i2, i3, i4, i5, i6, i7,
    input [15:0] i8, i9, i10, i11, i12, i13, i14, i15,
    
    // ========== MODE CONTROL SIGNALS ==========
    // These signals control the multiplexer network to enable different
    // operation modes and data routing patterns
    input s1,                       // Binary mode selector (used for 2-to-1 muxes)
    input [1:0] s2,                // 3-to-1 mux selector
    input [1:0] s3,                // 4-to-1 mux selector (stage 3)
    input [1:0] sel,               // 4-to-1 mux final selector + twiddle selector
    
    // ========== TWIDDLE FACTORS (PACKED FORMAT) ==========
    // Pre-computed complex exponentials for FFT computation
    // Each is 16 bits: [15:8]=Real, [7:0]=Imaginary
    input signed [15:0] m0,        // W^0 = 1 + j0
    input signed [15:0] m1,        // W^1 (typically ≈ 0.707 - j0.707)
    input signed [15:0] m2,        // W^2 (typically 0 - j1)
    input signed [15:0] m3,        // W^3 (typically ≈ -0.707 - j0.707)
    
    // ========== 16 COMPLEX OUTPUTS (PACKED FORMAT) ==========
    output reg [15:0] o0, o1, o2, o3, o4, o5, o6, o7,
    output reg [15:0] o8, o9, o10, o11, o12, o13, o14, o15
);

    // ========== FEEDBACK REGISTERS ==========
    // These store the butterfly outputs and feed them back to inputs
    // This is the KEY to the folded architecture - allowing hardware reuse
    reg [15:0] fb0, fb1, fb2, fb3, fb4, fb5, fb6, fb7;
    reg [15:0] fb8, fb9, fb10, fb11, fb12, fb13, fb14, fb15;
    
    // ========== INTERNAL WIRE DECLARATIONS ==========
    // These connect the various multiplexer stages to each other
    
    // Stage A: Outputs from 3-to-1 multiplexers (controlled by s2)
    wire [15:0] a0, a1, a2, a3, a4, a5, a6, a7;
    wire [15:0] a8, a9, a10, a11, a12, a13, a14, a15;
    
    // Stage C: Outputs from 2-to-1 multiplexers (controlled by s1)
    wire [15:0] c0, c1, c2, c3, c4, c5, c6, c7;
    wire [15:0] c8, c9, c10, c11, c12, c13, c14, c15;
    
    // Stage U: Outputs from 4-to-1 multiplexers (controlled by s3)
    wire [15:0] u0, u1, u2, u3, u4, u5, u6, u7;
    wire [15:0] u8, u9, u10, u11, u12, u13, u14, u15;
    
    // Stage W: Outputs from final 4-to-1 multiplexers (controlled by sel)
    // These feed directly into the butterfly units
    wire [15:0] w0, w1, w2, w3, w4, w5, w6, w7;
    wire [15:0] w8, w9, w10, w11, w12, w13, w14, w15;
    
    // Butterfly outputs
    wire [15:0] bo0, bo1, bo2, bo3, bo4, bo5, bo6, bo7;
    wire [15:0] bo8, bo9, bo10, bo11, bo12, bo13, bo14, bo15;

    // ========================================================================
    // MULTIPLEXER NETWORK - STAGE 1: 3-TO-1 MULTIPLEXERS (s2 control)
    // ========================================================================
    // PURPOSE: First level of input selection
    // These muxes typically select between:
    //   in0 = Fresh input from external source
    //   in1 = Feedback from previous butterfly output
    //   in2 = Alternate feedback routing for different modes
    //
    // ROUTING PATTERNS:
    // Notice how the routing isn't uniform - different muxes connect to
    // different feedback registers. This implements the data permutation
    // required by the FFT algorithm (bit-reversal and stage-specific routing)
    // ========================================================================
    
    mux3to1 #(.W(16)) mux3_0  (.in0(i0),  .in1(fb0), .in2(fb0), .sel(s2), .out(a0));
    mux3to1 #(.W(16)) mux3_1  (.in0(i4),  .in1(fb4), .in2(fb2), .sel(s2), .out(a1));
    mux3to1 #(.W(16)) mux3_2  (.in0(i1),  .in1(fb2), .in2(fb1), .sel(s2), .out(a2));
    mux3to1 #(.W(16)) mux3_3  (.in0(i5),  .in1(fb6), .in2(fb3), .sel(s2), .out(a3));
    mux3to1 #(.W(16)) mux3_4  (.in0(i2),  .in1(fb1), .in2(fb4), .sel(s2), .out(a4));
    mux3to1 #(.W(16)) mux3_5  (.in0(i6),  .in1(fb5), .in2(fb6), .sel(s2), .out(a5));
    mux3to1 #(.W(16)) mux3_6  (.in0(i3),  .in1(fb3), .in2(fb5), .sel(s2), .out(a6));
    mux3to1 #(.W(16)) mux3_7  (.in0(i7),  .in1(fb7), .in2(fb7), .sel(s2), .out(a7));
    
    // Second set of 3-to-1 muxes (similar pattern for upper half)
    mux3to1 #(.W(16)) mux3_8  (.in0(i0),  .in1(fb0), .in2(fb0), .sel(s2), .out(a8));
    mux3to1 #(.W(16)) mux3_9  (.in0(i4),  .in1(fb4), .in2(fb2), .sel(s2), .out(a9));
    mux3to1 #(.W(16)) mux3_10 (.in0(i1),  .in1(fb2), .in2(fb1), .sel(s2), .out(a10));
    mux3to1 #(.W(16)) mux3_11 (.in0(i5),  .in1(fb6), .in2(fb3), .sel(s2), .out(a11));
    mux3to1 #(.W(16)) mux3_12 (.in0(i2),  .in1(fb1), .in2(fb4), .sel(s2), .out(a12));
    mux3to1 #(.W(16)) mux3_13 (.in0(i6),  .in1(fb5), .in2(fb6), .sel(s2), .out(a13));
    mux3to1 #(.W(16)) mux3_14 (.in0(i3),  .in1(fb3), .in2(fb5), .sel(s2), .out(a14));
    mux3to1 #(.W(16)) mux3_15 (.in0(i7),  .in1(fb7), .in2(fb7), .sel(s2), .out(a15));

    // ========================================================================
    // MULTIPLEXER NETWORK - STAGE 2: 2-TO-1 MULTIPLEXERS (s1 control)
    // ========================================================================
    // PURPOSE: Second level of input selection
    // Simpler selection between:
    //   in0 = Fresh input
    //   in1 = Feedback data
    //
    // NOTES:
    // - These provide another level of routing flexibility
    // - Enable different FFT sizes (e.g., 16-point vs 8-point)
    // - Notice the pattern: only uses i0, i1, i2, i3 as fresh inputs
    //   This implements decimation (data reordering) for FFT algorithm
    // ========================================================================
    
    mux2to1 #(.W(16)) mux2_0  (.in0(i0), .in1(fb0), .sel(s1), .out(c0));
    mux2to1 #(.W(16)) mux2_1  (.in0(i2), .in1(fb2), .sel(s1), .out(c1));
    mux2to1 #(.W(16)) mux2_2  (.in0(i1), .in1(fb1), .sel(s1), .out(c2));
    mux2to1 #(.W(16)) mux2_3  (.in0(i3), .in1(fb3), .sel(s1), .out(c3));
    mux2to1 #(.W(16)) mux2_4  (.in0(i0), .in1(fb0), .sel(s1), .out(c4));
    mux2to1 #(.W(16)) mux2_5  (.in0(i2), .in1(fb2), .sel(s1), .out(c5));
    mux2to1 #(.W(16)) mux2_6  (.in0(i1), .in1(fb1), .sel(s1), .out(c6));
    mux2to1 #(.W(16)) mux2_7  (.in0(i3), .in1(fb3), .sel(s1), .out(c7));
    mux2to1 #(.W(16)) mux2_8  (.in0(i0), .in1(fb0), .sel(s1), .out(c8));
    mux2to1 #(.W(16)) mux2_9  (.in0(i2), .in1(fb2), .sel(s1), .out(c9));
    mux2to1 #(.W(16)) mux2_10 (.in0(i1), .in1(fb1), .sel(s1), .out(c10));
    mux2to1 #(.W(16)) mux2_11 (.in0(i3), .in1(fb3), .sel(s1), .out(c11));
    mux2to1 #(.W(16)) mux2_12 (.in0(i0), .in1(fb0), .sel(s1), .out(c12));
    mux2to1 #(.W(16)) mux2_13 (.in0(i2), .in1(fb2), .sel(s1), .out(c13));
    mux2to1 #(.W(16)) mux2_14 (.in0(i1), .in1(fb1), .sel(s1), .out(c14));
    mux2to1 #(.W(16)) mux2_15 (.in0(i3), .in1(fb3), .sel(s1), .out(c15));

    // ========================================================================
    // MULTIPLEXER NETWORK - STAGE 3: 4-TO-1 MULTIPLEXERS (s3 control)
    // ========================================================================
    // PURPOSE: Third level of input selection with maximum routing options
    // Each mux can select from 4 sources, providing great flexibility
    //
    // ROUTING COMPLEXITY:
    // Look at the interconnection pattern:
    //   - Some muxes use all 16 input ports (i0-i15)
    //   - Some use specific feedback combinations
    //   - This complex routing implements the "shuffle" operations required
    //     by the FFT algorithm for different stages and modes
    //
    // EXAMPLE (mux4_1):
    //   in0 = i8  (fresh input 8)
    //   in1 = fb8 (feedback from output 8)
    //   in2 = fb4 (feedback from output 4)
    //   in3 = fb2 (feedback from output 2)
    //   This allows u1 to receive data from 4 different sources depending
    //   on which FFT stage is currently being processed
    // ========================================================================
    
    mux4to1 #(.W(16)) mux4_0  (.in0(i0),  .in1(fb0),  .in2(fb0),  .in3(fb0),  .sel(s3), .out(u0));
    mux4to1 #(.W(16)) mux4_1  (.in0(i8),  .in1(fb8),  .in2(fb4),  .in3(fb2),  .sel(s3), .out(u1));
    mux4to1 #(.W(16)) mux4_2  (.in0(i1),  .in1(fb2),  .in2(fb2),  .in3(fb1),  .sel(s3), .out(u2));
    mux4to1 #(.W(16)) mux4_3  (.in0(i9),  .in1(fb10), .in2(fb6),  .in3(fb3),  .sel(s3), .out(u3));
    mux4to1 #(.W(16)) mux4_4  (.in0(i2),  .in1(fb4),  .in2(fb1),  .in3(fb4),  .sel(s3), .out(u4));
    mux4to1 #(.W(16)) mux4_5  (.in0(i10), .in1(fb12), .in2(fb6),  .in3(fb6),  .sel(s3), .out(u5));
    mux4to1 #(.W(16)) mux4_6  (.in0(i3),  .in1(fb6),  .in2(fb3),  .in3(fb5),  .sel(s3), .out(u6));
    mux4to1 #(.W(16)) mux4_7  (.in0(i11), .in1(fb14), .in2(fb7),  .in3(fb7),  .sel(s3), .out(u7));
    mux4to1 #(.W(16)) mux4_8  (.in0(i4),  .in1(fb1),  .in2(fb8),  .in3(fb8),  .sel(s3), .out(u8));
    mux4to1 #(.W(16)) mux4_9  (.in0(i12), .in1(fb9),  .in2(fb12), .in3(fb10), .sel(s3), .out(u9));
    mux4to1 #(.W(16)) mux4_10 (.in0(i5),  .in1(fb3),  .in2(fb10), .in3(fb9),  .sel(s3), .out(u10));
    mux4to1 #(.W(16)) mux4_11 (.in0(i13), .in1(fb11), .in2(fb14), .in3(fb11), .sel(s3), .out(u11));
    mux4to1 #(.W(16)) mux4_12 (.in0(i6),  .in1(fb5),  .in2(fb9),  .in3(fb12), .sel(s3), .out(u12));
    mux4to1 #(.W(16)) mux4_13 (.in0(i14), .in1(fb13), .in2(fb13), .in3(fb14), .sel(s3), .out(u13));
    mux4to1 #(.W(16)) mux4_14 (.in0(i7),  .in1(fb7),  .in2(fb11), .in3(fb13), .sel(s3), .out(u14));
    mux4to1 #(.W(16)) mux4_15 (.in0(i15), .in1(fb15), .in2(fb15), .in3(fb15), .sel(s3), .out(u15));

    // ========================================================================
    // MULTIPLEXER NETWORK - STAGE 4: FINAL 4-TO-1 MULTIPLEXERS (sel control)
    // ========================================================================
    // PURPOSE: Final input selection stage before butterfly units
    // These muxes combine all previous stages:
    //   in0 = Direct input (bypass all feedback)
    //   in1 = Stage A output (from 3-to-1 muxes)
    //   in2 = Stage C output (from 2-to-1 muxes)
    //   in3 = Stage U output (from 4-to-1 muxes)
    //
    // IMPORTANT NOTE:
    // The 'sel' signal does DOUBLE DUTY:
    //   1. Controls these final multiplexers
    //   2. Also controls twiddle factor selection in butterflies
    //   This ensures data routing and twiddle factors stay synchronized
    //
    // DESIGN INSIGHT:
    // Notice some muxes use only i0 or i1 as direct inputs. This is because
    // in many FFT stages, only a subset of inputs are "fresh" data while
    // others come from feedback paths. This implements the decimation-in-frequency
    // algorithm's data flow pattern.
    // ========================================================================
    
    mux4to1 #(.W(16)) mux4f_0  (.in0(i0), .in1(a0),  .in2(c0),  .in3(u0),  .sel(sel), .out(w0));
    mux4to1 #(.W(16)) mux4f_1  (.in0(i1), .in1(a1),  .in2(c1),  .in3(u1),  .sel(sel), .out(w1));
    mux4to1 #(.W(16)) mux4f_2  (.in0(i0), .in1(a2),  .in2(c2),  .in3(u2),  .sel(sel), .out(w2));
    mux4to1 #(.W(16)) mux4f_3  (.in0(i1), .in1(a3),  .in2(c3),  .in3(u3),  .sel(sel), .out(w3));
    mux4to1 #(.W(16)) mux4f_4  (.in0(i0), .in1(a4),  .in2(c4),  .in3(u4),  .sel(sel), .out(w4));
    mux4to1 #(.W(16)) mux4f_5  (.in0(i1), .in1(a5),  .in2(c5),  .in3(u5),  .sel(sel), .out(w5));
    mux4to1 #(.W(16)) mux4f_6  (.in0(i0), .in1(a6),  .in2(c6),  .in3(u6),  .sel(sel), .out(w6));
    mux4to1 #(.W(16)) mux4f_7  (.in0(i1), .in1(a7),  .in2(c7),  .in3(u7),  .sel(sel), .out(w7));
    mux4to1 #(.W(16)) mux4f_8  (.in0(i0), .in1(a8),  .in2(c8),  .in3(u8),  .sel(sel), .out(w8));
    mux4to1 #(.W(16)) mux4f_9  (.in0(i1), .in1(a9),  .in2(c9),  .in3(u9),  .sel(sel), .out(w9));
    mux4to1 #(.W(16)) mux4f_10 (.in0(i0), .in1(a10), .in2(c10), .in3(u10), .sel(sel), .out(w10));
    mux4to1 #(.W(16)) mux4f_11 (.in0(i1), .in1(a11), .in2(c11), .in3(u11), .sel(sel), .out(w11));
    mux4to1 #(.W(16)) mux4f_12 (.in0(i0), .in1(a12), .in2(c12), .in3(u12), .sel(sel), .out(w12));
    mux4to1 #(.W(16)) mux4f_13 (.in0(i1), .in1(a13), .in2(c13), .in3(u13), .sel(sel), .out(w13));
    mux4to1 #(.W(16)) mux4f_14 (.in0(i0), .in1(a14), .in2(c14), .in3(u14), .sel(sel), .out(w14));
    mux4to1 #(.W(16)) mux4f_15 (.in0(i1), .in1(a15), .in2(c15), .in3(u15), .sel(sel), .out(w15));

    // ========================================================================
    // BUTTERFLY PROCESSING UNITS (8 RADIX-2 BUTTERFLIES)
    // ========================================================================
    // PURPOSE: Core FFT computation elements
    //
    // ORGANIZATION:
    // We have 8 butterflies, each processing 2 inputs:
    //   BF0: w0, w1   → bo0, bo1
    //   BF1: w2, w3   → bo2, bo3
    //   BF2: w4, w5   → bo4, bo5
    //   BF3: w6, w7   → bo6, bo7
    //   BF4: w8, w9   → bo8, bo9
    //   BF5: w10, w11 → bo10, bo11
    //   BF6: w12, w13 → bo12, bo13
    //   BF7: w14, w15 → bo14, bo15
    //
    // Total: 16 inputs → 8 butterflies → 16 outputs
    //
    // BUTTERFLY PAIRING:
    // The pairing is crucial for FFT algorithm correctness:
    // - Stage 1: Pairs separated by 8 (0&8, 1&9, 2&10, etc.)
    // - Stage 2: Pairs separated by 4 (0&4, 1&5, 2&6, etc.)
    // - Stage 3: Pairs separated by 2 (0&2, 1&3, 4&6, etc.)
    // - Stage 4: Adjacent pairs (0&1, 2&3, 4&5, etc.)
    //
    // The multiplexer network handles routing to create these pairings!
    //
    // TWIDDLE FACTORS:
    // All butterflies receive the same twiddle factors (m0-m3) and use 'sel'
    // to choose which one. However, different butterflies in the same stage
    // may need different twiddles, so 'sel' varies between stages/passes.
    // ========================================================================
    
    // Butterfly 0: Processes w0 and w1
    butterfly_radix2_packed #(.W(16)) bf0 (
        .x0(w0), 
        .x1(w1), 
        .twiddle_sel(sel),
        .m0(m0), .m1(m1), .m2(m2), .m3(m3),
        .y0(bo0), 
        .y1(bo1)
    );
    
    // Butterfly 1: Processes w2 and w3
    butterfly_radix2_packed #(.W(16)) bf1 (
        .x0(w2), 
        .x1(w3), 
        .twiddle_sel(sel),
        .m0(m0), .m1(m1), .m2(m2), .m3(m3),
        .y0(bo2), 
        .y1(bo3)
    );
    
    // Butterfly 2: Processes w4 and w5
    butterfly_radix2_packed #(.W(16)) bf2 (
        .x0(w4), 
        .x1(w5), 
        .twiddle_sel(sel),
        .m0(m0), .m1(m1), .m2(m2), .m3(m3),
        .y0(bo4), 
        .y1(bo5)
    );
    
    // Butterfly 3: Processes w6 and w7
    butterfly_radix2_packed #(.W(16)) bf3 (
        .x0(w6), 
        .x1(w7), 
        .twiddle_sel(sel),
        .m0(m0), .m1(m1), .m2(m2), .m3(m3),
        .y0(bo6), 
        .y1(bo7)
    );
    
    // Butterfly 4: Processes w8 and w9
    butterfly_radix2_packed #(.W(16)) bf4 (
        .x0(w8), 
        .x1(w9), 
        .twiddle_sel(sel),
        .m0(m0), .m1(m1), .m2(m2), .m3(m3),
        .y0(bo8), 
        .y1(bo9)
    );
    
    // Butterfly 5: Processes w10 and w11
    butterfly_radix2_packed #(.W(16)) bf5 (
        .x0(w10), 
        .x1(w11), 
        .twiddle_sel(sel),
        .m0(m0), .m1(m1), .m2(m2), .m3(m3),
        .y0(bo10), 
        .y1(bo11)
    );
    
    // Butterfly 6: Processes w12 and w13
    butterfly_radix2_packed #(.W(16)) bf6 (
        .x0(w12), 
        .x1(w13), 
        .twiddle_sel(sel),
        .m0(m0), .m1(m1), .m2(m2), .m3(m3),
        .y0(bo12), 
        .y1(bo13)
    );
    
    // Butterfly 7: Processes w14 and w15
    butterfly_radix2_packed #(.W(16)) bf7 (
        .x0(w14), 
        .x1(w15), 
        .twiddle_sel(sel),
        .m0(m0), .m1(m1), .m2(m2), .m3(m3),
        .y0(bo14), 
        .y1(bo15)
    );

    // ========================================================================
    // REGISTER STAGE: OUTPUT AND FEEDBACK REGISTERS
    // ========================================================================
    // PURPOSE: Store butterfly results and provide feedback for next iteration
    //
    // SYNCHRONOUS OPERATION:
    // This always block triggers on:
    //   1. Positive clock edge (posedge clk)
    //   2. Negative reset edge (negedge rst_n) - active-low reset
    //
    // RESET BEHAVIOR:
    // When rst_n = 0:
    //   - All outputs cleared to 0
    //   - All feedback registers cleared to 0
    //   - This ensures clean startup with no garbage data
    //
    // NORMAL OPERATION:
    // When rst_n = 1:
    //   - Butterfly outputs (bo0-bo15) are captured into:
    //     a) Output registers (o0-o15) - visible to external circuits
    //     b) Feedback registers (fb0-fb15) - fed back to input muxes
    //
    // FEEDBACK MECHANISM:
    // The feedback registers create a "memory" of previous results, allowing:
    //   1. Multi-stage FFT processing with same hardware
    //   2. Iterative refinement algorithms
    //   3. Pipelined operation for continuous data streams
    //
    // TIMING ANALYSIS:
    // Clock cycle N:   Input → Mux → Butterfly → Register
    // Clock cycle N+1: Feedback available at mux inputs
    //
    // This 1-cycle delay is INTENTIONAL and REQUIRED for proper FFT operation
    // ========================================================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // ===== RESET CONDITION =====
            // Clear all outputs to zero
            o0  <= 16'h0; o1  <= 16'h0; o2  <= 16'h0; o3  <= 16'h0;
            o4  <= 16'h0; o5  <= 16'h0; o6  <= 16'h0; o7  <= 16'h0;
            o8  <= 16'h0; o9  <= 16'h0; o10 <= 16'h0; o11 <= 16'h0;
            o12 <= 16'h0; o13 <= 16'h0; o14 <= 16'h0; o15 <= 16'h0;
            
            // Clear all feedback registers to zero
            fb0  <= 16'h0; fb1  <= 16'h0; fb2  <= 16'h0; fb3  <= 16'h0;
            fb4  <= 16'h0; fb5  <= 16'h0; fb6  <= 16'h0; fb7  <= 16'h0;
            fb8  <= 16'h0; fb9  <= 16'h0; fb10 <= 16'h0; fb11 <= 16'h0;
            fb12 <= 16'h0; fb13 <= 16'h0; fb14 <= 16'h0; fb15 <= 16'h0;
        end else begin
            // ===== NORMAL OPERATION =====
            // Update output registers with butterfly results
            o0  <= bo0;  o1  <= bo1;  o2  <= bo2;  o3  <= bo3;
            o4  <= bo4;  o5  <= bo5;  o6  <= bo6;  o7  <= bo7;
            o8  <= bo8;  o9  <= bo9;  o10 <= bo10; o11 <= bo11;
            o12 <= bo12; o13 <= bo13; o14 <= bo14; o15 <= bo15;
            
            // Update feedback registers (same values as outputs)
            // These will be available at mux inputs on NEXT clock cycle
            fb0  <= bo0;  fb1  <= bo1;  fb2  <= bo2;  fb3  <= bo3;
            fb4  <= bo4;  fb5  <= bo5;  fb6  <= bo6;  fb7  <= bo7;
            fb8  <= bo8;  fb9  <= bo9;  fb10 <= bo10; fb11 <= bo11;
            fb12 <= bo12; fb13 <= bo13; fb14 <= bo14; fb15 <= bo15;
        end
    end

endmodule


// ============================================================================
// SUMMARY OF OPERATION
// ============================================================================
//
// COMPLETE DATA FLOW (One FFT Pass):
// 1. Inputs arrive at i0-i15
// 2. Multiplexer network routes data (controlled by s1, s2, s3, sel)
// 3. Data flows through 4 mux stages: Stage A → C → U → W
// 4. Final muxed data (w0-w15) enters 8 butterfly units
// 5. Butterflies compute FFT butterfly operations using twiddle factors
// 6. Results (bo0-bo15) are stored in registers
// 7. Results appear at outputs (o0-o15)
// 8. Results also stored in feedback registers (fb0-fb15)
// 9. On next clock cycle, feedback data available at mux inputs
//
// MULTI-STAGE FFT PROCESSING:
// For a complete 16-point FFT, you need log2(16) = 4 stages.
// The folded architecture reuses the 8 butterflies across all stages:
//
// Stage 1: Apply one set of control signals, process data
// Stage 2: Change control signals, feedback data flows back through
// Stage 3: Change control signals again, process feedback
// Stage 4: Final stage with last set of control signals
//
// CONTROL SIGNAL PATTERNS:
// Different combinations of (s1, s2, s3, sel) create different data flows:
// - sel=00: Might process stage 1 with W^0 twiddles
// - sel=01: Might process stage 2 with W^1 twiddles  
// - sel=10: Might process stage 3 with W^2 twiddles
// - sel=11: Might process stage 4 with W^3 twiddles
//
// (Exact control sequences depend on the specific FFT algorithm variant)
//
// ADVANTAGES OF THIS ARCHITECTURE:
// ✓ Hardware efficiency: Reuses 8 butterflies for all stages
// ✓ Flexibility: Multiple operation modes via control signals
// ✓ Scalability: Easy to extend to larger FFT sizes
// ✓ Low latency: Pipeline operation possible
//
// DISADVANTAGES:
// ✗ Requires multiple clock cycles for complete FFT
// ✗ Complex control logic needed externally
// ✗ Feedback paths can limit maximum clock frequency
//
// ============================================================================
