// =============================================================================
// Testbench: tb_butterfly_radix2.v
// Description: Test the Radix-2 butterfly unit
// =============================================================================

`timescale 1ns/1ps

module tb_butterfly_radix2;

    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;
    
    reg clk, rst_n, enable;
    reg signed [WIDTH-1:0] x0_real, x0_imag;
    reg signed [WIDTH-1:0] x1_real, x1_imag;
    reg signed [WIDTH-1:0] tw_real, tw_imag;
    wire signed [WIDTH-1:0] y0_real, y0_imag;
    wire signed [WIDTH-1:0] y1_real, y1_imag;
    wire valid;
    
    // Instantiate butterfly
    butterfly_radix2 #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
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
        .valid(valid)
    );
    
    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;
    
    initial begin
        $display("========================================");
        $display("Radix-2 Butterfly Test Started");
        $display("========================================\n");
        
        // Initialize
        clk = 0;
        rst_n = 0;
        enable = 0;
        x0_real = 0; x0_imag = 0;
        x1_real = 0; x1_imag = 0;
        tw_real = 0; tw_imag = 0;
        
        // Reset
        #(CLK_PERIOD*2);
        rst_n = 1;
        #(CLK_PERIOD);
        
        // Test 1: x0=1.0, x1=0.5, W=1.0
        $display("Test 1: x0=(1.0+0i), x1=(0.5+0i), W=(1.0+0i)");
        x0_real = 16'sd32767;  // 1.0
        x0_imag = 16'sd0;
        x1_real = 16'sd16384;  // 0.5
        x1_imag = 16'sd0;
        tw_real = 16'sd32767;  // 1.0
        tw_imag = 16'sd0;
        
        #(CLK_PERIOD);
        $display("  [DEBUG] Inputs set, sum_real should be %d", dut.sum_real);
        $display("  [DEBUG] diff_real should be %d", dut.diff_real);
        
        enable = 1;
        #(CLK_PERIOD);
        enable = 0;
        
        // Wait 2 cycles for pipeline to complete
        #(CLK_PERIOD*2);
        $display("  Output: y0=(%.4f+%.4fi), y1=(%.4f+%.4fi)", 
                 $itor(y0_real)/32768.0, $itor(y0_imag)/32768.0,
                 $itor(y1_real)/32768.0, $itor(y1_imag)/32768.0);
        $display("  Expected: y0≈(1.5+0i) [saturates to 0.9999], y1=(0.5+0i)\n");
        
        // Test 2: x0=0.5, x1=0.5, W=1.0
        #(CLK_PERIOD*3);
        $display("Test 2: x0=(0.5+0i), x1=(0.5+0i), W=(1.0+0i)");
        x0_real = 16'sd16384;  // 0.5
        x0_imag = 16'sd0;
        x1_real = 16'sd16384;  // 0.5
        x1_imag = 16'sd0;
        tw_real = 16'sd32767;  // 1.0
        tw_imag = 16'sd0;
        enable = 1;
        #(CLK_PERIOD);
        enable = 0;
        #(CLK_PERIOD*2);
        $display("  Output: y0=(%.4f+%.4fi), y1=(%.4f+%.4fi)", 
                 $itor(y0_real)/32768.0, $itor(y0_imag)/32768.0,
                 $itor(y1_real)/32768.0, $itor(y1_imag)/32768.0);
        $display("  Expected: y0=(1.0+0i), y1=(0.0+0i)\n");
        
        #(CLK_PERIOD*2);
        $display("========================================");
        $display("Butterfly Test Complete");
        $display("========================================");
        
        $finish;
    end

endmodule
