`timescale 1ns / 1ps

// Radix-2^2 butterfly for 16-point FFT
// Architecturally this is equivalent to a radix-4 DIF butterfly, but
// kept separate so you can experiment with radix-2^2 specific optimizations later.

module butterfly_radix2_2 #(
    parameter WIDTH = 16
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     enable,

    // Four complex inputs
    input  wire signed [WIDTH-1:0]  x0_real, x0_imag,
    input  wire signed [WIDTH-1:0]  x1_real, x1_imag,
    input  wire signed [WIDTH-1:0]  x2_real, x2_imag,
    input  wire signed [WIDTH-1:0]  x3_real, x3_imag,

    // Stage twiddle factors (W^0 = 1 is implicit for y0)
    input  wire signed [WIDTH-1:0]  w1_real, w1_imag,
    input  wire signed [WIDTH-1:0]  w2_real, w2_imag,
    input  wire signed [WIDTH-1:0]  w3_real, w3_imag,

    // Four complex outputs
    output wire signed [WIDTH-1:0]  y0_real, y0_imag,
    output wire signed [WIDTH-1:0]  y1_real, y1_imag,
    output wire signed [WIDTH-1:0]  y2_real, y2_imag,
    output wire signed [WIDTH-1:0]  y3_real, y3_imag,

    output wire                     valid
);

    // ---------------------------------------------------------------------
    // Stage 1: compute A,B,C,D
    // A = x0 + x2
    // B = x0 - x2
    // C = x1 + x3
    // D = x1 - x3
    // ---------------------------------------------------------------------

    wire signed [WIDTH-1:0] a_real, a_imag;
    wire signed [WIDTH-1:0] b_real, b_imag;
    wire signed [WIDTH-1:0] c_real, c_imag;
    wire signed [WIDTH-1:0] d_real, d_imag;

    complex_adder #(.WIDTH(WIDTH)) add_a (
        .a_real(x0_real), .a_imag(x0_imag),
        .b_real(x2_real), .b_imag(x2_imag),
        .sum_real(a_real), .sum_imag(a_imag),
        .overflow()
    );

    complex_subtractor #(.WIDTH(WIDTH)) sub_b (
        .a_real(x0_real), .a_imag(x0_imag),
        .b_real(x2_real), .b_imag(x2_imag),
        .diff_real(b_real), .diff_imag(b_imag),
        .overflow()
    );

    complex_adder #(.WIDTH(WIDTH)) add_c (
        .a_real(x1_real), .a_imag(x1_imag),
        .b_real(x3_real), .b_imag(x3_imag),
        .sum_real(c_real), .sum_imag(c_imag),
        .overflow()
    );

    complex_subtractor #(.WIDTH(WIDTH)) sub_d (
        .a_real(x1_real), .a_imag(x1_imag),
        .b_real(x3_real), .b_imag(x3_imag),
        .diff_real(d_real), .diff_imag(d_imag),
        .overflow()
    );

    // ---------------------------------------------------------------------
    // Stage 2: radix-2^2 / radix-4 DIF combination
    //   jD = j * D = -Di + j*Dr
    //   Y0 = A + C
    //   Y2 = A - C
    //   Y1 = B - jD
    //   Y3 = B + jD
    // Then Y1..Y3 are multiplied by W1,W2,W3.
    // ---------------------------------------------------------------------

    wire signed [WIDTH-1:0] sum0_real, sum0_imag;    // A + C
    wire signed [WIDTH-1:0] diff2_real, diff2_imag;  // A - C
    wire signed [WIDTH-1:0] b_jd_real, b_jd_imag;    // B + jD
    wire signed [WIDTH-1:0] b_njd_real, b_njd_imag;  // B - jD

    // jD = j * D = j*(Dr + jDi) = -Di + j*Dr
    wire signed [WIDTH-1:0] jd_real = -d_imag;
    wire signed [WIDTH-1:0] jd_imag =  d_real;

    complex_adder #(.WIDTH(WIDTH)) add_y0 (
        .a_real(a_real), .a_imag(a_imag),
        .b_real(c_real), .b_imag(c_imag),
        .sum_real(sum0_real), .sum_imag(sum0_imag),
        .overflow()
    );

    complex_subtractor #(.WIDTH(WIDTH)) sub_y2 (
        .a_real(a_real), .a_imag(a_imag),
        .b_real(c_real), .b_imag(c_imag),
        .diff_real(diff2_real), .diff_imag(diff2_imag),
        .overflow()
    );

    complex_adder #(.WIDTH(WIDTH)) add_bjd (
        .a_real(b_real), .a_imag(b_imag),
        .b_real(jd_real), .b_imag(jd_imag),
        .sum_real(b_jd_real), .sum_imag(b_jd_imag),
        .overflow()
    );

    complex_subtractor #(.WIDTH(WIDTH)) sub_bnjd (
        .a_real(b_real), .a_imag(b_imag),
        .b_real(jd_real), .b_imag(jd_imag),
        .diff_real(b_njd_real), .diff_imag(b_njd_imag),
        .overflow()
    );

    // ---------------------------------------------------------------------
    // Stage 3: complex multipliers (1-cycle latency)
    // ---------------------------------------------------------------------

    wire signed [WIDTH-1:0] mult1_real, mult1_imag;
    wire signed [WIDTH-1:0] mult2_real, mult2_imag;
    wire signed [WIDTH-1:0] mult3_real, mult3_imag;
    wire                    mult1_valid, mult2_valid, mult3_valid;

    // y0 = Y0 = A + C
    assign y0_real = sum0_real;
    assign y0_imag = sum0_imag;

    // y1 = (B - jD) * W1
    complex_multiplier #(.WIDTH(WIDTH)) mult_y1 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .a_real(b_njd_real),
        .a_imag(b_njd_imag),
        .b_real(w1_real),
        .b_imag(w1_imag),
        .result_real(mult1_real),
        .result_imag(mult1_imag),
        .valid(mult1_valid)
    );

    assign y1_real = mult1_real;
    assign y1_imag = mult1_imag;

    // y2 = (A - C) * W2
    complex_multiplier #(.WIDTH(WIDTH)) mult_y2 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .a_real(diff2_real),
        .a_imag(diff2_imag),
        .b_real(w2_real),
        .b_imag(w2_imag),
        .result_real(mult2_real),
        .result_imag(mult2_imag),
        .valid(mult2_valid)
    );

    assign y2_real = mult2_real;
    assign y2_imag = mult2_imag;

    // y3 = (B + jD) * W3
    complex_multiplier #(.WIDTH(WIDTH)) mult_y3 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .a_real(b_jd_real),
        .a_imag(b_jd_imag),
        .b_real(w3_real),
        .b_imag(w3_imag),
        .result_real(mult3_real),
        .result_imag(mult3_imag),
        .valid(mult3_valid)
    );

    assign y3_real = mult3_real;
    assign y3_imag = mult3_imag;

    // All multipliers have 1-cycle latency; output is valid when they are.
    assign valid = mult1_valid & mult2_valid & mult3_valid;

endmodule
