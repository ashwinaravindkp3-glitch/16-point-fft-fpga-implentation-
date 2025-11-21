`timescale 1ns / 1ps

module twiddle_rom_radix4 #(
    parameter WIDTH = 16
)(
    input wire [3:0] addr,
    output reg signed [WIDTH-1:0] tw_real,
    output reg signed [WIDTH-1:0] tw_imag
);

    // Twiddle factors for 16-point FFT: W_16^k = e^(-j*2*pi*k/16)
    // Q15 format: multiply by 32767
    // Pre-computed values for k=0 to 15
    
    always @(*) begin
        case(addr)
            4'd0: begin  // W^0 = 1.0
                tw_real = 16'sd32767;
                tw_imag = 16'sd0;
            end
            4'd1: begin  // W^1 = 0.9238795 - 0.3826834j
                tw_real = 16'sd30273;
                tw_imag = -16'sd12540;
            end
            4'd2: begin  // W^2 = 0.7071068 - 0.7071068j
                tw_real = 16'sd23170;
                tw_imag = -16'sd23170;
            end
            4'd3: begin  // W^3 = 0.3826834 - 0.9238795j
                tw_real = 16'sd12540;
                tw_imag = -16'sd30273;
            end
            4'd4: begin  // W^4 = 0.0 - 1.0j
                tw_real = 16'sd0;
                tw_imag = -16'sd32767;
            end
            4'd5: begin  // W^5 = -0.3826834 - 0.9238795j
                tw_real = -16'sd12540;
                tw_imag = -16'sd30273;
            end
            4'd6: begin  // W^6 = -0.7071068 - 0.7071068j
                tw_real = -16'sd23170;
                tw_imag = -16'sd23170;
            end
            4'd7: begin  // W^7 = -0.9238795 - 0.3826834j
                tw_real = -16'sd30273;
                tw_imag = -16'sd12540;
            end
            4'd8: begin  // W^8 = -1.0 + 0.0j
                tw_real = -16'sd32767;
                tw_imag = 16'sd0;
            end
            4'd9: begin  // W^9 = -0.9238795 + 0.3826834j
                tw_real = -16'sd30273;
                tw_imag = 16'sd12540;
            end
            4'd10: begin  // W^10 = -0.7071068 + 0.7071068j
                tw_real = -16'sd23170;
                tw_imag = 16'sd23170;
            end
            4'd11: begin  // W^11 = -0.3826834 + 0.9238795j
                tw_real = -16'sd12540;
                tw_imag = 16'sd30273;
            end
            4'd12: begin  // W^12 = 0.0 + 1.0j
                tw_real = 16'sd0;
                tw_imag = 16'sd32767;
            end
            4'd13: begin  // W^13 = 0.3826834 + 0.9238795j
                tw_real = 16'sd12540;
                tw_imag = 16'sd30273;
            end
            4'd14: begin  // W^14 = 0.7071068 + 0.7071068j
                tw_real = 16'sd23170;
                tw_imag = 16'sd23170;
            end
            4'd15: begin  // W^15 = 0.9238795 + 0.3826834j
                tw_real = 16'sd30273;
                tw_imag = 16'sd12540;
            end
        endcase
    end

endmodule
