`timescale 1ns / 1ps

module fft_master_wrapper #(
    parameter WIDTH = 16
)(
    input  wire              clk,          // System Clock
    input  wire              rst_n,        // Reset (Active Low)
    input  wire [3:0]        bin_sel,      // 4 Switches: Select Bin 0-15
    output wire signed [15:0] leds_real,   // 16 LEDs for Real result
    output wire signed [15:0] leds_imag,   // 16 LEDs for Imag result
    output wire              done_led      // 1 LED for Done status
);

    // ----------------------------------------------------------------
    // 1. Internal Signals & Start Pulse
    // ----------------------------------------------------------------
    reg [7:0] start_cnt = 0;
    reg       start_reg = 0;

    // Generate a single start pulse shortly after reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_cnt <= 0;
            start_reg <= 0;
        end else begin
            if (start_cnt < 8'd20) begin
                start_cnt <= start_cnt + 1'b1;
                if (start_cnt == 8'd10) 
                    start_reg <= 1'b1;
                else 
                    start_reg <= 1'b0;
            end
        end
    end
    wire start = start_reg;

    // ----------------------------------------------------------------
    // 2. Input Generator (Impulse: 1 at index 0)
    // ----------------------------------------------------------------
    reg  signed [WIDTH*16-1:0] data_in_real;
    reg  signed [WIDTH*16-1:0] data_in_imag;

    always @(*) begin
        data_in_real = {(WIDTH*16){1'b0}};
        data_in_imag = {(WIDTH*16){1'b0}};
        data_in_real[WIDTH-1:0] = 16'sd32767; // Max positive value
    end

    wire signed [WIDTH*16-1:0] data_out_real;
    wire signed [WIDTH*16-1:0] data_out_imag;
    wire done, valid;

    // ----------------------------------------------------------------
    // 3. INSTANTIATION AREA - SELECT YOUR ARCHITECTURE
    // ----------------------------------------------------------------

    // === OPTION 1: RADIX-2 (Uncomment to use) ===
    /*
    fft_radix2_top #(.WIDTH(WIDTH)) u_fft (
        .clk(clk), .rst_n(rst_n), .start(start),
        .data_in_real(data_in_real), .data_in_imag(data_in_imag),
        .data_out_real(data_out_real), .data_out_imag(data_out_imag),
        .done(done), .valid(valid)
    );
    */

    // === OPTION 2: RADIX-4 (Uncomment to use) ===
    
    fft_radix4_top #(.WIDTH(WIDTH)) u_fft (
        .clk(clk), .rst_n(rst_n), .start(start),
        .data_in_real(data_in_real), .data_in_imag(data_in_imag),
        .data_out_real(data_out_real), .data_out_imag(data_out_imag),
        .done(done), .valid(valid)
    );
    

    // === OPTION 3: RADIX-2^2 (Currently Active) ===
    /*
    fft_radix2_2_top #(.WIDTH(WIDTH)) u_fft (
        .clk(clk), .rst_n(rst_n), .start(start),
        .data_in_real(data_in_real), .data_in_imag(data_in_imag),
        .data_out_real(data_out_real), .data_out_imag(data_out_imag),
        .done(done), .valid(valid)
    );
    */

    // ----------------------------------------------------------------
    // 4. Output Mux & LED Mapping
    // ----------------------------------------------------------------
    reg signed [15:0] selected_real;
    reg signed [15:0] selected_imag;

    always @(*) begin
        // Select the specific 16-bit chunk based on the switches
        selected_real = data_out_real[bin_sel*WIDTH +: WIDTH];
        selected_imag = data_out_imag[bin_sel*WIDTH +: WIDTH];
    end

    assign leds_real = selected_real;
    assign leds_imag = selected_imag;
    assign done_led  = done;

endmodule
