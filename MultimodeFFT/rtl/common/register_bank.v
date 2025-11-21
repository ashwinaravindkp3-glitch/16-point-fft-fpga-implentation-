module register_bank #(
    parameter WIDTH = 16,
    parameter DEPTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire we,          // Write enable
    input wire signed [WIDTH*DEPTH-1:0] data_in_real,   // Flattened 16 values
    input wire signed [WIDTH*DEPTH-1:0] data_in_imag,
    output wire signed [WIDTH*DEPTH-1:0] data_out_real,
    output wire signed [WIDTH*DEPTH-1:0] data_out_imag
);

    // Internal register array
    reg signed [WIDTH-1:0] regs_real [0:DEPTH-1];
    reg signed [WIDTH-1:0] regs_imag [0:DEPTH-1];
    
    integer i;
    
    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                regs_real[i] <= {WIDTH{1'b0}};
                regs_imag[i] <= {WIDTH{1'b0}};
            end
        end else if (we) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                regs_real[i] <= data_in_real[(i+1)*WIDTH-1 -: WIDTH];
                regs_imag[i] <= data_in_imag[(i+1)*WIDTH-1 -: WIDTH];
            end
        end
    end
    
    // Read logic (combinational)
    genvar j;
    generate
        for (j = 0; j < DEPTH; j = j + 1) begin : flatten_output
            assign data_out_real[(j+1)*WIDTH-1 -: WIDTH] = regs_real[j];
            assign data_out_imag[(j+1)*WIDTH-1 -: WIDTH] = regs_imag[j];
        end
    endgenerate

endmodule