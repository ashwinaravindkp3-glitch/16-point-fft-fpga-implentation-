module control_radix2 (
    input  wire clk,
    input  wire rst_n,
    input  wire start,      // Start FFT computation
    output reg  [1:0] cycle,      // Current cycle (0-3)
    output reg  bf_enable,  // Butterfly enable
    output reg  reg_we,     // Register write enable
    output reg  mux_sel,    // 0=fresh input, 1=feedback
    output reg  done,       // Computation complete
    output reg  data_valid  // Output data valid
);

    // FSM states - need wait states for butterfly latency
    localparam IDLE      = 4'd0;
    localparam CYCLE_0   = 4'd1;
    localparam WAIT_0    = 4'd2;
    localparam CYCLE_1   = 4'd3;
    localparam WAIT_1    = 4'd4;
    localparam CYCLE_2   = 4'd5;
    localparam WAIT_2    = 4'd6;
    localparam CYCLE_3   = 4'd7;
    localparam WAIT_3    = 4'd8;
    localparam DONE      = 4'd9;
    
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
        case (state)
            IDLE: begin
                if (start)
                    next_state = CYCLE_0;
                else
                    next_state = IDLE;
            end
            
            CYCLE_0: next_state = WAIT_0;
            WAIT_0:  next_state = CYCLE_1;
            
            CYCLE_1: next_state = WAIT_1;
            WAIT_1:  next_state = CYCLE_2;
            
            CYCLE_2: next_state = WAIT_2;
            WAIT_2:  next_state = CYCLE_3;
            
            CYCLE_3: next_state = WAIT_3;
            WAIT_3:  next_state = DONE;
            
            DONE: begin
                if (start)
                    next_state = CYCLE_0;
                else
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Output logic
    always @(*) begin
        // Defaults
        cycle = 2'd0;
        bf_enable = 1'b0;
        reg_we = 1'b0;
        mux_sel = 1'b0;
        done = 1'b0;
        data_valid = 1'b0;
        
        case (state)
            IDLE: begin
                mux_sel = 1'b0;  // Select fresh input
            end
            
            CYCLE_0: begin
                cycle = 2'd0;
                bf_enable = 1'b1;
                mux_sel = 1'b0;  // Fresh input
            end
            
            WAIT_0: begin
                cycle = 2'd0;
                reg_we = 1'b1;   // Write butterfly results
                mux_sel = 1'b0;
            end
            
            CYCLE_1: begin
                cycle = 2'd1;
                bf_enable = 1'b1;
                mux_sel = 1'b1;  // Feedback
            end
            
            WAIT_1: begin
                cycle = 2'd1;
                reg_we = 1'b1;
                mux_sel = 1'b1;
            end
            
            CYCLE_2: begin
                cycle = 2'd2;
                bf_enable = 1'b1;
                mux_sel = 1'b1;  // Feedback
            end
            
            WAIT_2: begin
                cycle = 2'd2;
                reg_we = 1'b1;
                mux_sel = 1'b1;
            end
            
            CYCLE_3: begin
                cycle = 2'd3;
                bf_enable = 1'b1;
                mux_sel = 1'b1;  // Feedback
            end
            
            WAIT_3: begin
                cycle = 2'd3;
                reg_we = 1'b1;
                mux_sel = 1'b1;
            end
            
            DONE: begin
                done = 1'b1;
                data_valid = 1'b1;
                mux_sel = 1'b1;  // Keep feedback data for output
            end
            
            default: begin
                // All outputs at default values
            end
        endcase
    end

endmodule