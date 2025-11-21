`timescale 1ns / 1ps

module tb_fft_radix2_2_top;

    parameter WIDTH      = 16;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg start;
    reg  signed [WIDTH*16-1:0] data_in_real;
    reg  signed [WIDTH*16-1:0] data_in_imag;
    wire signed [WIDTH*16-1:0] data_out_real;
    wire signed [WIDTH*16-1:0] data_out_imag;
    wire done;
    wire valid;

    // DUT
    fft_radix2_2_top #(.WIDTH(WIDTH)) dut (
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

    // Clock
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Stimulus: impulse at index 0
    initial begin
        data_in_real = {16{16'sd0}};
        data_in_imag = {16{16'sd0}};
        data_in_real[15:0] = 16'sd32767; // x[0] = 1.0 in Q15
    end

    // Test sequence
    initial begin
        $display("========================================");
        $display("Radix-2^2 16-point FFT Test - Impulse Input");
        $display("========================================");

        rst_n = 0;
        start = 0;
        #30;
        rst_n = 1;
        #20;
        start = 1;
        #10;
        start = 0;

        @(posedge done);
        #20;

        $display("FFT Complete!\nAll 16 output bins (real part):");
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

endmodule
