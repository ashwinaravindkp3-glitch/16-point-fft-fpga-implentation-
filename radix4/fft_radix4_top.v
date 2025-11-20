`timescale 1ns / 1ps

module fft_radix4_top #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    input wire signed [WIDTH*16-1:0] data_in_real,
    input wire signed [WIDTH*16-1:0] data_in_imag,
    
    output wire signed [WIDTH*16-1:0] data_out_real,
    output wire signed [WIDTH*16-1:0] data_out_imag,
    
    output wire done,
    output wire valid
);

    // Control signals
    wire stage;
    wire bf_enable;
    wire reg_we;
    wire mux_sel;
    
    // Control FSM
    control_radix4 #(.WIDTH(WIDTH)) ctrl (
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
    
    // Register bank for intermediate storage
    wire signed [WIDTH*16-1:0] reg_out_real;
    wire signed [WIDTH*16-1:0] reg_out_imag;

    // Flattened butterfly outputs that feed the register bank
    reg  signed [WIDTH*16-1:0] bf_out_real;
    reg  signed [WIDTH*16-1:0] bf_out_imag;

    // Per-butterfly output wires (avoid hierarchical variable indices)
    wire signed [WIDTH-1:0] y0_real_arr [0:3];
    wire signed [WIDTH-1:0] y0_imag_arr [0:3];
    wire signed [WIDTH-1:0] y1_real_arr [0:3];
    wire signed [WIDTH-1:0] y1_imag_arr [0:3];
    wire signed [WIDTH-1:0] y2_real_arr [0:3];
    wire signed [WIDTH-1:0] y2_imag_arr [0:3];
    wire signed [WIDTH-1:0] y3_real_arr [0:3];
    wire signed [WIDTH-1:0] y3_imag_arr [0:3];
    
    register_bank #(.WIDTH(WIDTH)) reg_bank (
        .clk(clk),
        .rst_n(rst_n),
        .we(reg_we),
        .data_in_real(bf_out_real),
        .data_in_imag(bf_out_imag),
        .data_out_real(reg_out_real),
        .data_out_imag(reg_out_imag)
    );
    
    // MUX: select between input and register feedback
    wire signed [WIDTH*16-1:0] mux_out_real = mux_sel ? reg_out_real : data_in_real;
    wire signed [WIDTH*16-1:0] mux_out_imag = mux_sel ? reg_out_imag : data_in_imag;
    
    // Twiddle ROM
    wire signed [WIDTH-1:0] tw_real, tw_imag;
    
    // 4 Radix-4 butterflies (process 16 samples in parallel)
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : butterfly_array
            // Extract 4 inputs for butterfly i
            wire signed [WIDTH-1:0] x0_real, x0_imag;
            wire signed [WIDTH-1:0] x1_real, x1_imag;
            wire signed [WIDTH-1:0] x2_real, x2_imag;
            wire signed [WIDTH-1:0] x3_real, x3_imag;
            
            // Twiddle factors for this butterfly
            wire signed [WIDTH-1:0] w1_real, w1_imag;
            wire signed [WIDTH-1:0] w2_real, w2_imag;
            wire signed [WIDTH-1:0] w3_real, w3_imag;
            
            // Outputs
            wire signed [WIDTH-1:0] y0_real, y0_imag;
            wire signed [WIDTH-1:0] y1_real, y1_imag;
            wire signed [WIDTH-1:0] y2_real, y2_imag;
            wire signed [WIDTH-1:0] y3_real, y3_imag;
            
            // Input mapping for Radix-4 DIF (canonical order)
            // Stage 0: stride-4 groups: BF[i] gets {i, i+4, i+8, i+12}
            // Stage 1: contiguous groups: BF[i] gets {4i, 4i+1, 4i+2, 4i+3}
            
            reg [3:0] idx0, idx1, idx2, idx3;
            
            always @(*) begin
                if (stage == 0) begin
                    // Stage 0 (first pass): stride-4 groups
                    // Butterfly i gets {i, i+4, i+8, i+12}
                    idx0 = i[3:0];          // i+0
                    idx1 = i[3:0] + 4'd4;   // i+4
                    idx2 = i[3:0] + 4'd8;   // i+8
                    idx3 = i[3:0] + 4'd12;  // i+12
                end else begin
                    // Stage 1 (second pass): contiguous groups of 4
                    // Butterfly i gets {4i, 4i+1, 4i+2, 4i+3}
                    idx0 = {i[1:0], 2'd0};         // 4*i
                    idx1 = {i[1:0], 2'd0} + 4'd1;  // 4*i+1
                    idx2 = {i[1:0], 2'd0} + 4'd2;  // 4*i+2
                    idx3 = {i[1:0], 2'd0} + 4'd3;  // 4*i+3
                end
            end
            
            assign x0_real = mux_out_real[(idx0+1)*WIDTH-1 -: WIDTH];
            assign x0_imag = mux_out_imag[(idx0+1)*WIDTH-1 -: WIDTH];
            assign x1_real = mux_out_real[(idx1+1)*WIDTH-1 -: WIDTH];
            assign x1_imag = mux_out_imag[(idx1+1)*WIDTH-1 -: WIDTH];
            assign x2_real = mux_out_real[(idx2+1)*WIDTH-1 -: WIDTH];
            assign x2_imag = mux_out_imag[(idx2+1)*WIDTH-1 -: WIDTH];
            assign x3_real = mux_out_real[(idx3+1)*WIDTH-1 -: WIDTH];
            assign x3_imag = mux_out_imag[(idx3+1)*WIDTH-1 -: WIDTH];
            
            // Twiddle factor generation
            reg [3:0] tw1_addr, tw2_addr, tw3_addr;
            
            always @(*) begin
                if (stage == 0) begin
                    // Stage 0: W^(i*k) for k=0,1,2,3 (stride-4 butterflies)
                    tw1_addr = i[3:0];           // W^(i*1)
                    tw2_addr = (i*2) & 4'hF;     // W^(i*2)
                    tw3_addr = (i*3) & 4'hF;     // W^(i*3)
                end else begin
                    // Stage 1: no twiddles (all identity)
                    tw1_addr = 4'd0;
                    tw2_addr = 4'd0;
                    tw3_addr = 4'd0;
                end
            end
            
            twiddle_rom_radix4 #(.WIDTH(WIDTH)) tw_rom1 (
                .addr(tw1_addr),
                .tw_real(w1_real),
                .tw_imag(w1_imag)
            );
            
            twiddle_rom_radix4 #(.WIDTH(WIDTH)) tw_rom2 (
                .addr(tw2_addr),
                .tw_real(w2_real),
                .tw_imag(w2_imag)
            );
            
            twiddle_rom_radix4 #(.WIDTH(WIDTH)) tw_rom3 (
                .addr(tw3_addr),
                .tw_real(w3_real),
                .tw_imag(w3_imag)
            );
            
            // Butterfly instance
            butterfly_radix4 #(.WIDTH(WIDTH)) butterfly (
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
                .y0_real(y0_real), .y0_imag(y0_imag),
                .y1_real(y1_real), .y1_imag(y1_imag),
                .y2_real(y2_real), .y2_imag(y2_imag),
                .y3_real(y3_real), .y3_imag(y3_imag),
                .valid()
            );

            // Expose per-butterfly outputs to top-level arrays
            assign y0_real_arr[i] = y0_real;
            assign y0_imag_arr[i] = y0_imag;
            assign y1_real_arr[i] = y1_real;
            assign y1_imag_arr[i] = y1_imag;
            assign y2_real_arr[i] = y2_real;
            assign y2_imag_arr[i] = y2_imag;
            assign y3_real_arr[i] = y3_real;
            assign y3_imag_arr[i] = y3_imag;
        end
    endgenerate

    // Combinational logic for butterfly outputs
    integer k;
    always @(*) begin
        // Default to zero
        bf_out_real = {(WIDTH*16){1'b0}};
        bf_out_imag = {(WIDTH*16){1'b0}};

        // Map outputs from each butterfly using arrays (no hierarchical variable index)
        for (k = 0; k < 4; k = k + 1) begin : map_outputs
            reg [3:0] out_idx0, out_idx1, out_idx2, out_idx3;

            if (stage == 0) begin
                // Stage 0: stride-4 groups
                out_idx0 = k[3:0];         // k+0
                out_idx1 = k[3:0] + 4'd4;  // k+4
                out_idx2 = k[3:0] + 4'd8;  // k+8
                out_idx3 = k[3:0] + 4'd12; // k+12
            end else begin
                // Stage 1: contiguous groups
                out_idx0 = {k[1:0], 2'd0};         // 4*k
                out_idx1 = {k[1:0], 2'd0} + 4'd1;  // 4*k+1
                out_idx2 = {k[1:0], 2'd0} + 4'd2;  // 4*k+2
                out_idx3 = {k[1:0], 2'd0} + 4'd3;  // 4*k+3
            end

            // Assign outputs from arrays
            bf_out_real[(out_idx0+1)*WIDTH-1 -: WIDTH] = y0_real_arr[k];
            bf_out_imag[(out_idx0+1)*WIDTH-1 -: WIDTH] = y0_imag_arr[k];
            bf_out_real[(out_idx1+1)*WIDTH-1 -: WIDTH] = y1_real_arr[k];
            bf_out_imag[(out_idx1+1)*WIDTH-1 -: WIDTH] = y1_imag_arr[k];
            bf_out_real[(out_idx2+1)*WIDTH-1 -: WIDTH] = y2_real_arr[k];
            bf_out_imag[(out_idx2+1)*WIDTH-1 -: WIDTH] = y2_imag_arr[k];
            bf_out_real[(out_idx3+1)*WIDTH-1 -: WIDTH] = y3_real_arr[k];
            bf_out_imag[(out_idx3+1)*WIDTH-1 -: WIDTH] = y3_imag_arr[k];
        end
    end
    
    // Output
    assign data_out_real = reg_out_real;
    assign data_out_imag = reg_out_imag;

endmodule
