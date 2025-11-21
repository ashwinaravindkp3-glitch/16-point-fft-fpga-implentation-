`timescale 1ns / 1ps

module twiddle_rom_radix2_2 #(
    parameter WIDTH = 16
)(
    input  wire [3:0]              addr,
    output reg  signed [WIDTH-1:0] tw_real,
    output reg  signed [WIDTH-1:0] tw_imag
);

    // 16-point FFT twiddle factors: W_16^k = e^(-j*2*pi*k/16)
    // Q15 fixed-point format

    always @(*) begin
        case (addr)
            4'd0:  begin tw_real = 16'sd32767;  tw_imag = 16'sd0;      end // 1.0
            4'd1:  begin tw_real = 16'sd30273;  tw_imag = -16'sd12540; end // cos22.5, -sin22.5
            4'd2:  begin tw_real = 16'sd23170;  tw_imag = -16'sd23170; end // cos45, -sin45
            4'd3:  begin tw_real = 16'sd12540;  tw_imag = -16'sd30273; end
            4'd4:  begin tw_real = 16'sd0;      tw_imag = -16'sd32767; end
            4'd5:  begin tw_real = -16'sd12540; tw_imag = -16'sd30273; end
            4'd6:  begin tw_real = -16'sd23170; tw_imag = -16'sd23170; end
            4'd7:  begin tw_real = -16'sd30273; tw_imag = -16'sd12540; end
            4'd8:  begin tw_real = -16'sd32767; tw_imag = 16'sd0;      end
            4'd9:  begin tw_real = -16'sd30273; tw_imag = 16'sd12540; end
            4'd10: begin tw_real = -16'sd23170; tw_imag = 16'sd23170; end
            4'd11: begin tw_real = -16'sd12540; tw_imag = 16'sd30273; end
            4'd12: begin tw_real = 16'sd0;      tw_imag = 16'sd32767; end
            4'd13: begin tw_real = 16'sd12540; tw_imag = 16'sd30273; end
            4'd14: begin tw_real = 16'sd23170; tw_imag = 16'sd23170; end
            4'd15: begin tw_real = 16'sd30273; tw_imag = 16'sd12540; end
        endcase
    end

endmodule
