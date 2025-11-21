module fft_radix2_top #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    // 16 complex inputs (flattened)
    input wire signed [WIDTH*16-1:0] data_in_real,
    input wire signed [WIDTH*16-1:0] data_in_imag,
    
    // 16 complex outputs (flattened)
    output wire signed [WIDTH*16-1:0] data_out_real,
    output wire signed [WIDTH*16-1:0] data_out_imag,
    
    output wire done,
    output wire valid
);

    // Control signals
    wire [1:0] cycle;
    wire bf_enable, reg_we, mux_sel;
    
    // Control FSM
    control_radix2 ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .cycle(cycle),
        .bf_enable(bf_enable),
        .reg_we(reg_we),
        .mux_sel(mux_sel),
        .done(done),
        .data_valid(valid)
    );
    
    // Register bank outputs (feedback path)
    wire signed [WIDTH*16-1:0] reg_out_real, reg_out_imag;
    
    // MUX: Select between fresh input and feedback
    wire signed [WIDTH*16-1:0] mux_out_real, mux_out_imag;
    
    assign mux_out_real = mux_sel ? reg_out_real : data_in_real;
    assign mux_out_imag = mux_sel ? reg_out_imag : data_in_imag;
    
    // Butterfly outputs (8 butterflies × 2 outputs = 16 values)
    wire signed [WIDTH-1:0] bf_out_real [0:15];
    wire signed [WIDTH-1:0] bf_out_imag [0:15];
    
    // Generate 8 butterflies with twiddle address generation
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : butterfly_array
            // Index generation: which two samples this butterfly operates on
            // for each pipeline cycle (stage) of the 16-point radix-2 DIF FFT.
            localparam integer I = i;   // 0..7, compile-time constant per instance
            reg [3:0] idx0, idx1;
            reg [2:0] tw_addr;

            always @(*) begin
                case (cycle)
                    // Cycle 0 (stage 0): pairs (0,8),(1,9),...,(7,15), exponents 0..7
                    2'd0: begin
                        idx0    = I;              // 0..7
                        idx1    = I + 8;          // 8..15
                        tw_addr = I[2:0];         // 0,1,2,3,4,5,6,7
                    end

                    // Cycle 1 (stage 1): pairs (0,4),(1,5),...,(8,12)..., exponents 0,2,4,6
                    2'd1: begin
                        idx0    = (I < 4) ? I : (I + 4);   // 0,1,2,3,8,9,10,11
                        idx1    = idx0 + 4;               // 4,5,6,7,12,13,14,15
                        tw_addr = ((I & 3) << 1);         // (I & 3)*2 -> 0,2,4,6,0,2,4,6
                    end

                    // Cycle 2 (stage 2): pairs (0,2),(1,3),...,(12,14),(13,15), exponents 0 or 4
                    2'd2: begin
                        idx0    = (I & 1) + ((I >> 1) << 2); // (I&1) + 4*(I>>1)
                        idx1    = idx0 + 2;                 // +2 within each group
                        tw_addr = (I & 1) ? 3'd4 : 3'd0;     // 0,4,0,4,0,4,0,4
                    end

                    // Cycle 3 (stage 3): pairs (0,1),(2,3),...,(14,15), twiddle exponent 0
                    2'd3: begin
                        idx0    = I << 1;                   // 0,2,4,6,8,10,12,14
                        idx1    = (I << 1) + 1;             // 1,3,5,7,9,11,13,15
                        tw_addr = 3'd0;
                    end

                    default: begin
                        idx0    = 4'd0;
                        idx1    = 4'd0;
                        tw_addr = 3'd0;
                    end
                endcase
            end

            // Extract inputs for this butterfly for the current stage
            wire signed [WIDTH-1:0] x0_real = mux_out_real[(idx0+1)*WIDTH-1 -: WIDTH];
            wire signed [WIDTH-1:0] x0_imag = mux_out_imag[(idx0+1)*WIDTH-1 -: WIDTH];
            wire signed [WIDTH-1:0] x1_real = mux_out_real[(idx1+1)*WIDTH-1 -: WIDTH];
            wire signed [WIDTH-1:0] x1_imag = mux_out_imag[(idx1+1)*WIDTH-1 -: WIDTH];
            
            // Twiddle ROM
            wire signed [WIDTH-1:0] tw_real, tw_imag;
            twiddle_rom_radix2 #(.WIDTH(WIDTH)) twiddle (
                .addr(tw_addr),
                .tw_real(tw_real),
                .tw_imag(tw_imag)
            );
            
            // Butterfly instance
            wire signed [WIDTH-1:0] y0_real, y0_imag, y1_real, y1_imag;
            butterfly_radix2 #(.WIDTH(WIDTH)) butterfly (
                .clk(clk),
                .rst_n(rst_n),
                .enable(bf_enable),
                .x0_real(x0_real),
                .x0_imag(x0_imag),
                .x1_real(x1_real),
                .x1_imag(x1_imag),
                .tw_real(tw_real),
                .tw_imag(tw_imag),
                .y0_real(y0_real),
                .y0_imag(y0_imag),
                .y1_real(y1_real),
                .y1_imag(y1_imag),
                .valid()
            );
            
            // Connect outputs
            // y0 goes to position i, y1 goes to position i+8
            assign bf_out_real[i]   = y0_real;
            assign bf_out_imag[i]   = y0_imag;
            assign bf_out_real[i+8] = y1_real;
            assign bf_out_imag[i+8] = y1_imag;
        end
    endgenerate
    
    // Flatten butterfly outputs for register bank
    wire signed [WIDTH*16-1:0] bf_out_real_flat, bf_out_imag_flat;
    
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : flatten_bf_out
            assign bf_out_real_flat[(k+1)*WIDTH-1 -: WIDTH] = bf_out_real[k];
            assign bf_out_imag_flat[(k+1)*WIDTH-1 -: WIDTH] = bf_out_imag[k];
        end
    endgenerate
    
    // Register bank (stores intermediate results)
    register_bank #(
        .WIDTH(WIDTH),
        .DEPTH(16)
    ) reg_bank (
        .clk(clk),
        .rst_n(rst_n),
        .we(reg_we),
        .data_in_real(bf_out_real_flat),
        .data_in_imag(bf_out_imag_flat),
        .data_out_real(reg_out_real),
        .data_out_imag(reg_out_imag)
    );
    
    // Output assignment (from register bank in DONE state)
    assign data_out_real = reg_out_real;
    assign data_out_imag = reg_out_imag;

endmodule