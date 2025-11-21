module complex_multiplier #(
    parameter WIDTH = 16
)(
    input                     clk,
    input                     rst_n,
    input                     enable,
    input  signed [WIDTH-1:0] a_real,
    input  signed [WIDTH-1:0] a_imag,
    input  signed [WIDTH-1:0] b_real,
    input  signed [WIDTH-1:0] b_imag,
    output signed [WIDTH-1:0] result_real,
    output signed [WIDTH-1:0] result_imag,
    output reg                valid
);

    // Four 16x16 multiplications = 32-bit products
    wire signed [31:0] ac, bd, ad, bc;
    
    assign ac = a_real * b_real;
    assign bd = a_imag * b_imag;
    assign ad = a_real * b_imag;
    assign bc = a_imag * b_real;
    
    // Complex multiplication: (ac - bd) + (ad + bc)i
    wire signed [32:0] real_temp, imag_temp;
    assign real_temp = ac - bd;
    assign imag_temp = ad + bc;
    
    // Scale by 2^15 for Q15 format (arithmetic right shift)
    wire signed [WIDTH-1:0] real_scaled, imag_scaled;
    assign real_scaled = real_temp[30:15];  // Take bits [30:15] for divide by 32768
    assign imag_scaled = imag_temp[30:15];
    
    // Pipeline registers
    reg signed [WIDTH-1:0] result_real_reg;
    reg signed [WIDTH-1:0] result_imag_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_real_reg <= 16'sd0;
            result_imag_reg <= 16'sd0;
            valid <= 1'b0;
        end else if (enable) begin
            result_real_reg <= real_scaled;
            result_imag_reg <= imag_scaled;
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
    
    assign result_real = result_real_reg;
    assign result_imag = result_imag_reg;

endmodule