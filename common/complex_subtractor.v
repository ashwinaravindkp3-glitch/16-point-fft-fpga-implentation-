module complex_subtractor #(
    parameter WIDTH = 16
)(
    input  signed [WIDTH-1:0] a_real,
    input  signed [WIDTH-1:0] a_imag,
    input  signed [WIDTH-1:0] b_real,
    input  signed [WIDTH-1:0] b_imag,
    output signed [WIDTH-1:0] diff_real,
    output signed [WIDTH-1:0] diff_imag,
    output                    overflow
);

    // 17-bit intermediate for overflow detection
    wire signed [WIDTH:0] temp_real;
    wire signed [WIDTH:0] temp_imag;
    
    // Perform subtraction with sign extension
    assign temp_real = {a_real[WIDTH-1], a_real} - {b_real[WIDTH-1], b_real};
    assign temp_imag = {a_imag[WIDTH-1], a_imag} - {b_imag[WIDTH-1], b_imag};
    
    // Detect overflow: result doesn't fit in 16-bit signed range
    wire overflow_real = (temp_real > 17'sd32767) | (temp_real < -17'sd32768);
    wire overflow_imag = (temp_imag > 17'sd32767) | (temp_imag < -17'sd32768);
    assign overflow = overflow_real | overflow_imag;
    
    // Saturate on overflow
    assign diff_real = overflow_real ? 
                       (temp_real[WIDTH] ? 16'sh8000 : 16'sh7FFF) :
                       temp_real[WIDTH-1:0];
                       
    assign diff_imag = overflow_imag ? 
                       (temp_imag[WIDTH] ? 16'sh8000 : 16'sh7FFF) :
                       temp_imag[WIDTH-1:0];

endmodule