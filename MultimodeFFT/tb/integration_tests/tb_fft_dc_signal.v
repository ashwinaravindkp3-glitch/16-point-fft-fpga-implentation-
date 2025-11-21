`timescale 1ns / 1ps

module tb_fft_dc_signal;

    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg start;
    reg signed [WIDTH*16-1:0] data_in_real;
    reg signed [WIDTH*16-1:0] data_in_imag;
    wire signed [WIDTH*16-1:0] data_out_real;
    wire signed [WIDTH*16-1:0] data_out_imag;
    wire done;
    wire valid;

    // Instantiate FFT
    fft_radix2_top #(.WIDTH(WIDTH)) uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .data_in_real(data_in_real),
        .data_in_imag(data_in_imag),
        .data_out_real(data_out_real),
        .data_out_imag(data_out_imag),
        .done(done),
        .valid(valid)
    );

    // Clock generation
    initial clk = 0;
    always #((CLK_PERIOD/2)) clk = ~clk;

    // Test sequence
    initial begin
        $display("========================================");
        $display("DC Signal Test (all inputs = 1.0)");
        $display("========================================");
        
        rst_n = 0;
        start = 0;
        
        // DC signal: all samples = 1.0
        data_in_real = {16{16'sd32767}};  // All 16 samples = 32767
        data_in_imag = 256'h0;
        
        #30;
        rst_n = 1;
        #20;
        start = 1;
        #10;
        start = 0;
        
        // Wait for completion
        @(posedge done);
        #20;
        
        $display("\nFFT Complete!");
        $display("Expected: X[0]=max (DC bin), X[1-15]=0 (AC bins)");
        $display("\nAll 16 output bins:");
        $display("  X[0]  = %d (should be ~32767 or saturated)", data_out_real[15:0]);
        $display("  X[1]  = %d (should be ~0)", data_out_real[31:16]);
        $display("  X[2]  = %d (should be ~0)", data_out_real[47:32]);
        $display("  X[3]  = %d (should be ~0)", data_out_real[63:48]);
        $display("  X[4]  = %d (should be ~0)", data_out_real[79:64]);
        $display("  X[5]  = %d (should be ~0)", data_out_real[95:80]);
        $display("  X[6]  = %d (should be ~0)", data_out_real[111:96]);
        $display("  X[7]  = %d (should be ~0)", data_out_real[127:112]);
        $display("  X[8]  = %d (should be ~0)", data_out_real[143:128]);
        $display("  X[9]  = %d (should be ~0)", data_out_real[159:144]);
        $display("  X[10] = %d (should be ~0)", data_out_real[175:160]);
        $display("  X[11] = %d (should be ~0)", data_out_real[191:176]);
        $display("  X[12] = %d (should be ~0)", data_out_real[207:192]);
        $display("  X[13] = %d (should be ~0)", data_out_real[223:208]);
        $display("  X[14] = %d (should be ~0)", data_out_real[239:224]);
        $display("  X[15] = %d (should be ~0)", data_out_real[255:240]);
        
        $finish;
    end

endmodule
