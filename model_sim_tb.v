`timescale 1ns / 1ps

module tb_fft_pure;

    // --------------------------------------------------------
    // 1. Parameters & Signals
    // --------------------------------------------------------
    parameter WIDTH = 16;
    
    // Control Signals
    reg clk;
    reg rst_n;
    reg start;
    
    // The Massive Buses (16 * 16 = 256 bits each)
    reg  signed [WIDTH*16-1:0] data_in_real;
    reg  signed [WIDTH*16-1:0] data_in_imag;
    
    wire signed [WIDTH*16-1:0] data_out_real;
    wire signed [WIDTH*16-1:0] data_out_imag;
    
    wire done;
    wire valid;

    // --------------------------------------------------------
    // 2. Instantiate the PURE FFT Core
    // --------------------------------------------------------
    // Change 'fft_radix2_top' to 'fft_radix4_top' or 'fft_radix2_2_top' as needed
    
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

    // --------------------------------------------------------
    // 3. Clock Generation (50 MHz)
    // --------------------------------------------------------
    always #10 clk = ~clk;

    // --------------------------------------------------------
    // 4. Test Sequence
    // --------------------------------------------------------
    integer k;

    initial begin
        // Initialize
        clk = 0;
        rst_n = 0;
        start = 0;
        
        // Clear Inputs
        data_in_real = {(WIDTH*16){1'b0}};
        data_in_imag = {(WIDTH*16){1'b0}};

        // ------------------------------------------------------
        // Step A: Create Stimulus (Impulse Input)
        // ------------------------------------------------------
        // We set Index 0 to Max Value (32767). All others are 0.
        // Note: In the flat bus, Index 0 is at bits [15:0]
        data_in_real[WIDTH-1 : 0] = 16'sd32767;

        $display("\n==========================================");
        $display("   Testing PURE FFT Block (No Wrapper)");
        $display("==========================================");

        // Step B: Reset the System
        #100;
        rst_n = 1;
        $display("[Time %0t] Reset Released.", $time);
        
        // Step C: Start the FFT
        #20;
        start = 1;
        #20; // Hold start high for 1 cycle (at 50MHz = 20ns)
        start = 0;
        $display("[Time %0t] Start Pulse Sent.", $time);

        // Step D: Wait for Completion
        wait(done == 1);
        $display("[Time %0t] FFT Done Signal Received!", $time);
        
        // Wait a moment for valid data to settle
        #20;

        // ------------------------------------------------------
        // Step E: Read & Verify Outputs
        // ------------------------------------------------------
        $display("\n------------------------------------------");
        $display(" Bin |   Real Output   |   Imag Output   ");
        $display("-----|-----------------|-----------------");

        // We manually slice the massive 256-bit bus using a loop
        for (k = 0; k < 16; k = k + 1) begin
            // Use the "+:" slicing operator to grab 16 bits at a time
            // Base Index = k * 16
            $display("  %2d |      %6d     |      %6d", 
                k, 
                data_out_real[k*WIDTH +: WIDTH], 
                data_out_imag[k*WIDTH +: WIDTH]
            );
        end
        $display("------------------------------------------\n");

        $stop;
    end

endmodule
