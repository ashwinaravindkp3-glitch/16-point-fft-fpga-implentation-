module fft_fpga_top #(
    parameter WIDTH = 16
)(
    input  wire clk,          // board clock (e.g. 100 MHz)
    input  wire rst_n,        // active-low reset
    output wire [15:0] leds_real,   // Real part on LED bank 1
    output wire [15:0] leds_imag    // Imag part on LED bank 2
);

    // ----------------------------------------------------------------
    // 1. Simple start pulse generator
    // ----------------------------------------------------------------
    reg [7:0] start_cnt = 0;
    reg       start_reg = 0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_cnt <= 0;
            start_reg <= 0;
        end else begin
            if (start_cnt < 8'd10) begin
                start_cnt <= start_cnt + 1'b1;
                start_reg <= (start_cnt == 8'd1);
            end else begin
                start_reg <= 1'b0;
            end
        end
    end

    wire start = start_reg;

    // ----------------------------------------------------------------
    // 2. Constant 16-sample impulse input
    // ----------------------------------------------------------------
    reg  signed [WIDTH*16-1:0] data_in_real;
    reg  signed [WIDTH*16-1:0] data_in_imag;

    integer i;
    always @(*) begin
        data_in_real = {WIDTH*16{1'b0}};
        data_in_imag = {WIDTH*16{1'b0}};
        data_in_real[WIDTH-1:0] = 16'sd32767;  // impulse at index 0
    end

    // ----------------------------------------------------------------
    // 3. FFT instance
    // ----------------------------------------------------------------
    wire signed [WIDTH*16-1:0] data_out_real;
    wire signed [WIDTH*16-1:0] data_out_imag;
    wire done, valid;

    fft_radix2_top #(.WIDTH(WIDTH)) u_fft (
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

    // ----------------------------------------------------------------
    // 4. Output mapping to LEDs
    // ----------------------------------------------------------------
    wire signed [15:0] bin0_real = data_out_real[WIDTH-1:0];
    wire signed [15:0] bin0_imag = data_out_imag[WIDTH-1:0];

    assign leds_real = bin0_real;
    assign leds_imag = bin0_imag;

endmodule
