module twiddle_rom_radix2 #(
    parameter WIDTH = 16
)(
    input      [2:0] addr,     // Address 0-7
    output reg signed [WIDTH-1:0] tw_real,
    output reg signed [WIDTH-1:0] tw_imag
);

    // Twiddle factors in Q15 format
    // W_16^k = cos(2*pi*k/16) - j*sin(2*pi*k/16)
    always @(*) begin
        case(addr)
            3'd0: begin  // W^0 = 1.0 + 0j
                tw_real = 16'sd32767;   // cos(0) = 1.0
                tw_imag = 16'sd0;       // -sin(0) = 0
            end
            3'd1: begin  // W^1 = 0.924 - 0.383j
                tw_real = 16'sd30273;   // cos(22.5°)
                tw_imag = -16'sd12540;  // -sin(22.5°)
            end
            3'd2: begin  // W^2 = 0.707 - 0.707j
                tw_real = 16'sd23170;   // cos(45°)
                tw_imag = -16'sd23170;  // -sin(45°)
            end
            3'd3: begin  // W^3 = 0.383 - 0.924j
                tw_real = 16'sd12540;   // cos(67.5°)
                tw_imag = -16'sd30273;  // -sin(67.5°)
            end
            3'd4: begin  // W^4 = 0 - 1.0j
                tw_real = 16'sd0;       // cos(90°)
                tw_imag = -16'sd32767;  // -sin(90°)
            end
            3'd5: begin  // W^5 = -0.383 - 0.924j
                tw_real = -16'sd12540;  // cos(112.5°)
                tw_imag = -16'sd30273;  // -sin(112.5°)
            end
            3'd6: begin  // W^6 = -0.707 - 0.707j
                tw_real = -16'sd23170;  // cos(135°)
                tw_imag = -16'sd23170;  // -sin(135°)
            end
            3'd7: begin  // W^7 = -0.924 - 0.383j
                tw_real = -16'sd30273;  // cos(157.5°)
                tw_imag = -16'sd12540;  // -sin(157.5°)
            end
        endcase
    end

endmodule