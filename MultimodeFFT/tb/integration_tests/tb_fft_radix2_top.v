`timescale 1ns / 1ps

module tb_fft_radix2_top;

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

    // Instantiate the FFT top module
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

    // Reset and start sequence
    initial begin
        rst_n = 0;
        start = 0;
        #30;
        rst_n = 1;
        #20;
        start = 1;
        #10;
        start = 0;
        
        // Wait for done
        @(posedge done);
        #20;
        
        $display("FFT Complete!");
        $display("All 16 output bins:");
        $display("  X[0]  = %d", data_out_real[15:0]);
        $display("  X[1]  = %d", data_out_real[31:16]);
        $display("  X[2]  = %d", data_out_real[47:32]);
        $display("  X[3]  = %d", data_out_real[63:48]);
        $display("  X[4]  = %d", data_out_real[79:64]);
        $display("  X[5]  = %d", data_out_real[95:80]);
        $display("  X[6]  = %d", data_out_real[111:96]);
        $display("  X[7]  = %d", data_out_real[127:112]);
        $display("  X[8]  = %d", data_out_real[143:128]);
        $display("  X[9]  = %d", data_out_real[159:144]);
        $display("  X[10] = %d", data_out_real[175:160]);
        $display("  X[11] = %d", data_out_real[191:176]);
        $display("  X[12] = %d", data_out_real[207:192]);
        $display("  X[13] = %d", data_out_real[223:208]);
        $display("  X[14] = %d", data_out_real[239:224]);
        $display("  X[15] = %d", data_out_real[255:240]);
        
        $finish;
    end

    // Input data setup - impulse at index 0
    initial begin
        // Set impulse: x[0] = 1.0, x[1..15] = 0
        // Only bits [15:0] should be 32767, rest should be 0
        data_in_real = 256'h0;
        data_in_imag = 256'h0;
        data_in_real[15:0] = 16'sd32767;  // Set first sample to 1.0
    end

    // Monitor output
    initial begin
        $monitor("Time: %t, Done: %d, Valid: %d, Data Out Real: %h, Data Out Imag: %h",
                 $time, done, valid, data_out_real, data_out_imag);
    end

endmodule