module butterfly_radix2 #(
    parameter WIDTH = 16
)(
    input                     clk,
    input                     rst_n,
    input                     enable,
    input  signed [WIDTH-1:0] x0_real,
    input  signed [WIDTH-1:0] x0_imag,
    input  signed [WIDTH-1:0] x1_real,
    input  signed [WIDTH-1:0] x1_imag,
    input  signed [WIDTH-1:0] tw_real,
    input  signed [WIDTH-1:0] tw_imag,
    output signed [WIDTH-1:0] y0_real,
    output signed [WIDTH-1:0] y0_imag,
    output signed [WIDTH-1:0] y1_real,
    output signed [WIDTH-1:0] y1_imag,
    output                    valid
);

    // Adder for upper path: y0 = x0 + x1
    wire signed [WIDTH-1:0] sum_real, sum_imag;
    wire ov_add;
    
    complex_adder #(.WIDTH(WIDTH)) adder (
        .a_real(x0_real),
        .a_imag(x0_imag),
        .b_real(x1_real),
        .b_imag(x1_imag),
        .sum_real(sum_real),
        .sum_imag(sum_imag),
        .overflow(ov_add)
    );
    
    // Subtractor for lower path: diff = x0 - x1
    wire signed [WIDTH-1:0] diff_real, diff_imag;
    wire ov_sub;
    
    complex_subtractor #(.WIDTH(WIDTH)) subtractor (
        .a_real(x0_real),
        .a_imag(x0_imag),
        .b_real(x1_real),
        .b_imag(x1_imag),
        .diff_real(diff_real),
        .diff_imag(diff_imag),
        .overflow(ov_sub)
    );
    
    // Pipeline stage 1: Register sum result
    reg signed [WIDTH-1:0] sum_real_reg, sum_imag_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_real_reg <= 16'sd0;
            sum_imag_reg <= 16'sd0;
        end else begin
            sum_real_reg <= sum_real;
            sum_imag_reg <= sum_imag;
        end
    end
    
    // Multiplier for lower path: y1 = diff × W (1 cycle latency)
    wire signed [WIDTH-1:0] mult_real, mult_imag;
    wire mult_valid;
    
    complex_multiplier #(.WIDTH(WIDTH)) multiplier (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .a_real(diff_real),
        .a_imag(diff_imag),
        .b_real(tw_real),
        .b_imag(tw_imag),
        .result_real(mult_real),
        .result_imag(mult_imag),
        .valid(mult_valid)
    );
    
    // Outputs
    assign y0_real = sum_real_reg;
    assign y0_imag = sum_imag_reg;
    assign y1_real = mult_real;
    assign y1_imag = mult_imag;
    assign valid = mult_valid;

endmodule