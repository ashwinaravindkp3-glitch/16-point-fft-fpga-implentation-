`timescale 1ns / 1ps

module fft_radix2_2_top #(
    parameter WIDTH = 16
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    input  wire signed [WIDTH*16-1:0] data_in_real,
    input  wire signed [WIDTH*16-1:0] data_in_imag,

    output wire signed [WIDTH*16-1:0] data_out_real,
    output wire signed [WIDTH*16-1:0] data_out_imag,

    output wire done,
    output wire valid
);

    //------------------------------------------------------------------
    // Control
    //------------------------------------------------------------------

    wire stage;
    wire bf_enable;
    wire reg_we;
    wire mux_sel;

    control_radix2_2 #(.WIDTH(WIDTH)) ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .stage(stage),
        .bf_enable(bf_enable),
        .reg_we(reg_we),
        .mux_sel(mux_sel),
        .done(done),
        .valid(valid)
    );

    //------------------------------------------------------------------
    // Register bank for intermediate storage
    //------------------------------------------------------------------

    wire signed [WIDTH*16-1:0] reg_out_real;
    wire signed [WIDTH*16-1:0] reg_out_imag;

    reg  signed [WIDTH*16-1:0] bf_out_real;
    reg  signed [WIDTH*16-1:0] bf_out_imag;

    register_bank #(.WIDTH(WIDTH), .DEPTH(16)) reg_bank (
        .clk(clk),
        .rst_n(rst_n),
        .we(reg_we),
        .data_in_real(bf_out_real),
        .data_in_imag(bf_out_imag),
        .data_out_real(reg_out_real),
        .data_out_imag(reg_out_imag)
    );

    //------------------------------------------------------------------
    // Input MUX: choose fresh input or feedback
    //------------------------------------------------------------------

    wire signed [WIDTH*16-1:0] mux_out_real = mux_sel ? reg_out_real : data_in_real;
    wire signed [WIDTH*16-1:0] mux_out_imag = mux_sel ? reg_out_imag : data_in_imag;

    //------------------------------------------------------------------
    // Per-butterfly outputs (4 butterflies x 4 outputs)
    //------------------------------------------------------------------

    wire signed [WIDTH-1:0] y0_real_arr [0:3];
    wire signed [WIDTH-1:0] y0_imag_arr [0:3];
    wire signed [WIDTH-1:0] y1_real_arr [0:3];
    wire signed [WIDTH-1:0] y1_imag_arr [0:3];
    wire signed [WIDTH-1:0] y2_real_arr [0:3];
    wire signed [WIDTH-1:0] y2_imag_arr [0:3];
    wire signed [WIDTH-1:0] y3_real_arr [0:3];
    wire signed [WIDTH-1:0] y3_imag_arr [0:3];

    //------------------------------------------------------------------
    // 4 radix-2^2 butterflies
    //------------------------------------------------------------------

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : butterfly_array
            // Indices into 16-point data vector for this butterfly
            reg [3:0] idx0, idx1, idx2, idx3;

            always @(*) begin
                if (stage == 0) begin
                    // Stage 0: stride-4 groups: {i, i+4, i+8, i+12}
                    idx0 = i[3:0];
                    idx1 = i[3:0] + 4'd4;
                    idx2 = i[3:0] + 4'd8;
                    idx3 = i[3:0] + 4'd12;
                end else begin
                    // Stage 1: contiguous groups: {4i, 4i+1, 4i+2, 4i+3}
                    idx0 = {i[1:0], 2'd0};
                    idx1 = {i[1:0], 2'd0} + 4'd1;
                    idx2 = {i[1:0], 2'd0} + 4'd2;
                    idx3 = {i[1:0], 2'd0} + 4'd3;
                end
            end

            // Extract inputs
            wire signed [WIDTH-1:0] x0_real = mux_out_real[(idx0+1)*WIDTH-1 -: WIDTH];
            wire signed [WIDTH-1:0] x0_imag = mux_out_imag[(idx0+1)*WIDTH-1 -: WIDTH];
            wire signed [WIDTH-1:0] x1_real = mux_out_real[(idx1+1)*WIDTH-1 -: WIDTH];
            wire signed [WIDTH-1:0] x1_imag = mux_out_imag[(idx1+1)*WIDTH-1 -: WIDTH];
            wire signed [WIDTH-1:0] x2_real = mux_out_real[(idx2+1)*WIDTH-1 -: WIDTH];
            wire signed [WIDTH-1:0] x2_imag = mux_out_imag[(idx2+1)*WIDTH-1 -: WIDTH];
            wire signed [WIDTH-1:0] x3_real = mux_out_real[(idx3+1)*WIDTH-1 -: WIDTH];
            wire signed [WIDTH-1:0] x3_imag = mux_out_imag[(idx3+1)*WIDTH-1 -: WIDTH];

            //------------------------------------------------------------------
            // Twiddle addresses
            //------------------------------------------------------------------

            reg [3:0] tw1_addr, tw2_addr, tw3_addr;

            always @(*) begin
                if (stage == 0) begin
                    // Stage 0: use non-trivial twiddles (same schedule as radix-4)
                    tw1_addr = i[3:0];          // W^(i*1)
                    tw2_addr = (i*2) & 4'hF;    // W^(i*2)
                    tw3_addr = (i*3) & 4'hF;    // W^(i*3)
                end else begin
                    // Stage 1: no twiddles (identity)
                    tw1_addr = 4'd0;
                    tw2_addr = 4'd0;
                    tw3_addr = 4'd0;
                end
            end

            wire signed [WIDTH-1:0] w1_real, w1_imag;
            wire signed [WIDTH-1:0] w2_real, w2_imag;
            wire signed [WIDTH-1:0] w3_real, w3_imag;

            twiddle_rom_radix2_2 #(.WIDTH(WIDTH)) tw1 (
                .addr(tw1_addr),
                .tw_real(w1_real),
                .tw_imag(w1_imag)
            );

            twiddle_rom_radix2_2 #(.WIDTH(WIDTH)) tw2 (
                .addr(tw2_addr),
                .tw_real(w2_real),
                .tw_imag(w2_imag)
            );

            twiddle_rom_radix2_2 #(.WIDTH(WIDTH)) tw3 (
                .addr(tw3_addr),
                .tw_real(w3_real),
                .tw_imag(w3_imag)
            );

            //------------------------------------------------------------------
            // Butterfly instance
            //------------------------------------------------------------------

            wire signed [WIDTH-1:0] y0_r, y0_i, y1_r, y1_i, y2_r, y2_i, y3_r, y3_i;

            butterfly_radix2_2 #(.WIDTH(WIDTH)) bf (
                .clk(clk),
                .rst_n(rst_n),
                .enable(bf_enable),
                .x0_real(x0_real), .x0_imag(x0_imag),
                .x1_real(x1_real), .x1_imag(x1_imag),
                .x2_real(x2_real), .x2_imag(x2_imag),
                .x3_real(x3_real), .x3_imag(x3_imag),
                .w1_real(w1_real), .w1_imag(w1_imag),
                .w2_real(w2_real), .w2_imag(w2_imag),
                .w3_real(w3_real), .w3_imag(w3_imag),
                .y0_real(y0_r), .y0_imag(y0_i),
                .y1_real(y1_r), .y1_imag(y1_i),
                .y2_real(y2_r), .y2_imag(y2_i),
                .y3_real(y3_r), .y3_imag(y3_i),
                .valid()
            );

            // Export outputs into arrays
            assign y0_real_arr[i] = y0_r;
            assign y0_imag_arr[i] = y0_i;
            assign y1_real_arr[i] = y1_r;
            assign y1_imag_arr[i] = y1_i;
            assign y2_real_arr[i] = y2_r;
            assign y2_imag_arr[i] = y2_i;
            assign y3_real_arr[i] = y3_r;
            assign y3_imag_arr[i] = y3_i;
        end
    endgenerate

    //------------------------------------------------------------------
    // Flatten butterfly outputs into bf_out_* buses
    //------------------------------------------------------------------

    integer k;
    reg [3:0] o0, o1, o2, o3;

    always @(*) begin
        bf_out_real = {(WIDTH*16){1'b0}};
        bf_out_imag = {(WIDTH*16){1'b0}};

        for (k = 0; k < 4; k = k + 1) begin

            if (stage == 0) begin
                // Stage 0: stride-4 groups
                o0 = k[3:0];
                o1 = k[3:0] + 4'd4;
                o2 = k[3:0] + 4'd8;
                o3 = k[3:0] + 4'd12;
            end else begin
                // Stage 1: contiguous groups
                o0 = {k[1:0], 2'd0};
                o1 = {k[1:0], 2'd0} + 4'd1;
                o2 = {k[1:0], 2'd0} + 4'd2;
                o3 = {k[1:0], 2'd0} + 4'd3;
            end

            bf_out_real[(o0+1)*WIDTH-1 -: WIDTH] = y0_real_arr[k];
            bf_out_imag[(o0+1)*WIDTH-1 -: WIDTH] = y0_imag_arr[k];

            bf_out_real[(o1+1)*WIDTH-1 -: WIDTH] = y1_real_arr[k];
            bf_out_imag[(o1+1)*WIDTH-1 -: WIDTH] = y1_imag_arr[k];

            bf_out_real[(o2+1)*WIDTH-1 -: WIDTH] = y2_real_arr[k];
            bf_out_imag[(o2+1)*WIDTH-1 -: WIDTH] = y2_imag_arr[k];

            bf_out_real[(o3+1)*WIDTH-1 -: WIDTH] = y3_real_arr[k];
            bf_out_imag[(o3+1)*WIDTH-1 -: WIDTH] = y3_imag_arr[k];
        end
    end

    //------------------------------------------------------------------
    // Outputs (final contents of register bank)
    //------------------------------------------------------------------

    assign data_out_real = reg_out_real;
    assign data_out_imag = reg_out_imag;

endmodule
