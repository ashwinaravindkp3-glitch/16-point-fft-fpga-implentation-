`timescale 1ns/1ps

module fft_fpga_top_radix4 #(
    parameter WIDTH = 16
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 start,

    // ---- 16 complex scalar inputs ----
    input  wire signed [WIDTH-1:0] x_real [0:15],
    input  wire signed [WIDTH-1:0] x_imag [0:15],

    // ---- 16 complex scalar outputs ----
    output wire signed [WIDTH-1:0] y_real [0:15],
    output wire signed [WIDTH-1:0] y_imag [0:15],

    output wire                 done,
    output wire                 valid
);

    // ----------------------------------------------------------------
    // Flatten inputs (convert arrays → 256-bit buses)
    // ----------------------------------------------------------------
    wire signed [WIDTH*16-1:0] data_in_real_flat;
    wire signed [WIDTH*16-1:0] data_in_imag_flat;

    genvar i;
    generate 
        for (i = 0; i < 16; i = i + 1) begin : PACK_INPUTS
            assign data_in_real_flat[(i+1)*WIDTH-1 -: WIDTH] = x_real[i];
            assign data_in_imag_flat[(i+1)*WIDTH-1 -: WIDTH] = x_imag[i];
        end
    endgenerate

    // ----------------------------------------------------------------
    // Instantiate the Radix-4 FFT Core
    // ----------------------------------------------------------------
    wire signed [WIDTH*16-1:0] data_out_real_flat;
    wire signed [WIDTH*16-1:0] data_out_imag_flat;

    fft_radix4_top #(
        .WIDTH(WIDTH)
    ) u_fft_radix4 (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .data_in_real(data_in_real_flat),
        .data_in_imag(data_in_imag_flat),
        .data_out_real(data_out_real_flat),
        .data_out_imag(data_out_imag_flat),
        .done(done),
        .valid(valid)
    );

    // ----------------------------------------------------------------
    // Unpack outputs (256-bit buses → 16 scalar bins)
    // ----------------------------------------------------------------
    generate 
        for (i = 0; i < 16; i = i + 1) begin : UNPACK_OUTPUTS
            assign y_real[i] = data_out_real_flat[(i+1)*WIDTH-1 -: WIDTH];
            assign y_imag[i] = data_out_imag_flat[(i+1)*WIDTH-1 -: WIDTH];
        end
    endgenerate

endmodule
