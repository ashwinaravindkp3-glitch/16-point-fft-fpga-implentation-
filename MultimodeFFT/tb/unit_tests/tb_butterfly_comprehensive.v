// =============================================================================
// Testbench: tb_butterfly_comprehensive.v
// Description: Comprehensive tests for Radix-2 butterfly
// Tests: Edge cases, various twiddle factors, complex numbers
// =============================================================================

`timescale 1ns/1ps

module tb_butterfly_comprehensive;

    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;
    
    reg clk, rst_n, enable;
    reg signed [WIDTH-1:0] x0_real, x0_imag;
    reg signed [WIDTH-1:0] x1_real, x1_imag;
    reg signed [WIDTH-1:0] tw_real, tw_imag;
    wire signed [WIDTH-1:0] y0_real, y0_imag;
    wire signed [WIDTH-1:0] y1_real, y1_imag;
    wire valid;
    
    integer test_count, pass_count, fail_count;
    
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
    
    // Task to run a single test
    task run_test;
        input [255:0] test_name;
        input signed [15:0] in_x0_r, in_x0_i;
        input signed [15:0] in_x1_r, in_x1_i;
        input signed [15:0] in_tw_r, in_tw_i;
        input signed [15:0] exp_y0_r, exp_y0_i;
        input signed [15:0] exp_y1_r, exp_y1_i;
        input integer tolerance;
        
        integer err_y0_r, err_y0_i, err_y1_r, err_y1_i;
        reg test_pass;
    begin
        test_count = test_count + 1;
        
        $display("\n----------------------------------------");
        $display("Test %0d: %s", test_count, test_name);
        $display("----------------------------------------");
        
        // Set inputs
        x0_real = in_x0_r; x0_imag = in_x0_i;
        x1_real = in_x1_r; x1_imag = in_x1_i;
        tw_real = in_tw_r; tw_imag = in_tw_i;
        
        #(CLK_PERIOD);
        enable = 1;
        #(CLK_PERIOD);
        enable = 0;
        #(CLK_PERIOD*2);
        
        // Check results
        err_y0_r = y0_real - exp_y0_r;
        err_y0_i = y0_imag - exp_y0_i;
        err_y1_r = y1_real - exp_y1_r;
        err_y1_i = y1_imag - exp_y1_i;
        
        if (err_y0_r < 0) err_y0_r = -err_y0_r;
        if (err_y0_i < 0) err_y0_i = -err_y0_i;
        if (err_y1_r < 0) err_y1_r = -err_y1_r;
        if (err_y1_i < 0) err_y1_i = -err_y1_i;
        
        test_pass = (err_y0_r <= tolerance) && (err_y0_i <= tolerance) &&
                    (err_y1_r <= tolerance) && (err_y1_i <= tolerance);
        
        $display("Input:    x0=(%d,%d) x1=(%d,%d) W=(%d,%d)", 
                 in_x0_r, in_x0_i, in_x1_r, in_x1_i, in_tw_r, in_tw_i);
        $display("Expected: y0=(%d,%d) y1=(%d,%d)", 
                 exp_y0_r, exp_y0_i, exp_y1_r, exp_y1_i);
        $display("Got:      y0=(%d,%d) y1=(%d,%d)", 
                 y0_real, y0_imag, y1_real, y1_imag);
        $display("Error:    y0=(%d,%d) y1=(%d,%d) [tolerance=%d]", 
                 err_y0_r, err_y0_i, err_y1_r, err_y1_i, tolerance);
        
        if (test_pass) begin
            $display("Result: PASS ✓");
            pass_count = pass_count + 1;
        end else begin
            $display("Result: FAIL ✗");
            fail_count = fail_count + 1;
        end
    end
    endtask
    
    initial begin
        $display("========================================");
        $display("Comprehensive Butterfly Tests");
        $display("========================================");
        
        // Initialize
        clk = 0;
        rst_n = 0;
        enable = 0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        x0_real = 0; x0_imag = 0;
        x1_real = 0; x1_imag = 0;
        tw_real = 0; tw_imag = 0;
        
        #(CLK_PERIOD*2);
        rst_n = 1;
        #(CLK_PERIOD);
        
        // ===== BASIC TESTS =====
        
        // Test 1: Zero inputs
        run_test("Zero inputs", 
                 0, 0, 0, 0, 32767, 0,  // x0=0, x1=0, W=1
                 0, 0, 0, 0, 0);        // expect y0=0, y1=0
        
        // Test 2: Identity (x1=0, W=1)
        run_test("Identity (x1=0)", 
                 16384, 0, 0, 0, 32767, 0,  // x0=0.5, x1=0, W=1
                 16384, 0, 16384, 0, 1);     // expect y0=0.5, y1=0.5
        
        // Test 3: Equal real inputs, W=1
        run_test("Equal inputs W=1", 
                 16384, 0, 16384, 0, 32767, 0,  // x0=x1=0.5, W=1
                 32767, 0, 0, 0, 1);             // y0=1.0(sat), y1=0
        
        // Test 4: Negative inputs
        run_test("Negative inputs", 
                 -16384, 0, -16384, 0, 32767, 0,  // x0=x1=-0.5, W=1
                 -32768, 0, 0, 0, 1);              // y0=-1.0(sat), y1=0
        
        // ===== TWIDDLE FACTOR TESTS =====
        
        // Test 5: W = -j (90 degrees)
        run_test("Twiddle W=-j", 
                 16384, 0, 0, 0, 0, -32767,  // x0=0.5, x1=0, W=-j
                 16384, 0, 0, -16384, 1);     // y0=0.5, y1=-0.5j
        
        // Test 6: W = -1 (180 degrees)
        run_test("Twiddle W=-1", 
                 16384, 0, 8192, 0, -32767, 0,  // x0=0.5, x1=0.25, W=-1
                 24576, 0, -8192, 0, 1);         // y0=0.75, y1=-0.25
        
        // Test 7: W = 0.707-0.707j (45 degrees) - W_16^2
        run_test("Twiddle W=0.707-0.707j", 
                 16384, 0, 0, 0, 23170, -23170,  // x0=0.5, W=exp(-j*pi/4)
                 16384, 0, 11585, -11585, 2);     // y1≈0.354-0.354j
        
        // ===== COMPLEX NUMBER TESTS =====
        
        // Test 8: Complex x0, real x1
        run_test("Complex x0, real x1", 
                 16384, 8192, 8192, 0, 32767, 0,  // x0=0.5+0.25j, x1=0.25
                 24576, 8192, 8192, 8192, 1);      // y0=0.75+0.25j, y1=0.25+0.25j
        
        // Test 9: Both complex inputs
        run_test("Both complex", 
                 8192, 8192, 8192, -8192, 32767, 0,  // x0=0.25+0.25j, x1=0.25-0.25j
                 16384, 0, 0, 16384, 1);              // y0=0.5, y1=0.5j
        
        // Test 10: Complex twiddle multiplication
        run_test("Complex twiddle mult", 
                 16384, 0, 0, 0, 16384, 16384,  // x0=0.5, W=0.5+0.5j
                 16384, 0, 8192, 8192, 1);       // y1≈0.25+0.25j
        
        // ===== EDGE CASES =====
        
        // Test 11: Maximum positive
        run_test("Max positive", 
                 32767, 0, 0, 0, 32767, 0,
                 32767, 0, 32767, 0, 1);  // Allow 1 LSB tolerance
        
        // Test 12: Maximum negative
        run_test("Max negative", 
                 -32768, 0, 0, 0, 32767, 0,
                 -32768, 0, -32768, 0, 1);
        
        // Test 13: Saturation test (overflow)
        run_test("Saturation overflow", 
                 32767, 0, 16384, 0, 32767, 0,  // Should saturate
                 32767, 0, 16383, 0, 1);         // y0 saturates to 32767
        
        // Test 14: Negative saturation
        run_test("Saturation underflow", 
                 -32768, 0, -16384, 0, 32767, 0,
                 -32768, 0, -16384, 0, 2);
        
        // ===== SUMMARY =====
        #(CLK_PERIOD*5);
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        $display("Success Rate: %0d%%", (pass_count * 100) / test_count);
        $display("========================================");
        
        if (fail_count == 0) begin
            $display("✓ ALL TESTS PASSED!");
        end else begin
            $display("✗ SOME TESTS FAILED");
        end
        $display("========================================");
        
        $finish;
    end

endmodule
