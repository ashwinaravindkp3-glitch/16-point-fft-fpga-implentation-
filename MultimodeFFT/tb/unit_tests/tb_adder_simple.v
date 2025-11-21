// Simple adder test
`timescale 1ns/1ps

module tb_adder_simple;

    reg signed [15:0] a_real, b_real;
    wire signed [15:0] sum_real;
    wire overflow;
    
    complex_adder #(.WIDTH(16)) dut (
        .a_real(a_real),
        .a_imag(16'd0),
        .b_real(b_real),
        .b_imag(16'd0),
        .sum_real(sum_real),
        .sum_imag(),
        .overflow(overflow)
    );
    
    initial begin
        $display("=== Adder Direct Test ===");
        
        a_real = 16'sd32767;
        b_real = 16'sd16384;
        #10;
        $display("Test: %d + %d = %d (expected 49151)", a_real, b_real, sum_real);
        $display("  temp_real would be: %d", $signed({a_real[15], a_real}) + $signed({b_real[15], b_real}));
        $display("  overflow = %b", overflow);
        
        #10;
        a_real = 16'sd16384;
        b_real = 16'sd16384;
        #10;
        $display("Test: %d + %d = %d (expected 32768)", a_real, b_real, sum_real);
        
        $finish;
    end

endmodule
