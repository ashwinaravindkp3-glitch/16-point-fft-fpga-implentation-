`timescale 1ns / 1ps

module control_radix4 #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    output reg stage,          // 0 or 1 (2 stages for 16-point)
    output reg bf_enable,      // Enable butterfly computation
    output reg reg_we,         // Write enable for register bank
    output reg mux_sel,        // 0=input data, 1=register feedback
    output reg done,
    output reg valid
);

    // FSM states for 2-stage Radix-4 FFT
    localparam IDLE      = 4'd0;
    localparam STAGE_0   = 4'd1;
    localparam WAIT_0    = 4'd2;
    localparam STAGE_1   = 4'd3;
    localparam WAIT_1    = 4'd4;
    localparam DONE      = 4'd5;
    
    reg [3:0] state, next_state;
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = STAGE_0;
            end
            STAGE_0: next_state = WAIT_0;
            WAIT_0:  next_state = STAGE_1;
            STAGE_1: next_state = WAIT_1;
            WAIT_1:  next_state = DONE;
            DONE:    next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Output logic
    always @(*) begin
        // Defaults
        stage = 1'b0;
        bf_enable = 1'b0;
        reg_we = 1'b0;
        mux_sel = 1'b0;
        done = 1'b0;
        valid = 1'b0;
        
        case (state)
            IDLE: begin
                stage = 1'b0;
                mux_sel = 1'b0;
            end
            
            STAGE_0: begin
                stage = 1'b0;
                bf_enable = 1'b1;
                mux_sel = 1'b0;  // Use input data
            end
            
            WAIT_0: begin
                stage = 1'b0;
                reg_we = 1'b1;   // Write butterfly results
                mux_sel = 1'b0;
            end
            
            STAGE_1: begin
                stage = 1'b1;
                bf_enable = 1'b1;
                mux_sel = 1'b1;  // Use register feedback
            end
            
            WAIT_1: begin
                stage = 1'b1;
                reg_we = 1'b1;   // Write butterfly results
                mux_sel = 1'b1;
            end
            
            DONE: begin
                done = 1'b1;
                valid = 1'b1;
            end
            
            default: begin
                stage = 1'b0;
                bf_enable = 1'b0;
                reg_we = 1'b0;
                mux_sel = 1'b0;
                done = 1'b0;
                valid = 1'b0;
            end
        endcase
    end

endmodule
