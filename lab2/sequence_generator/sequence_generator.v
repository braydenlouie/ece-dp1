
module sequence_generator (
    input wire clk,
    input wire reset_n, // Active-low reset
    input wire enable,
    output reg [7:0] data
);

// State encoding
localparam [2:0] 
    STATE_0 = 3'b000,
    STATE_1 = 3'b001,
    STATE_2 = 3'b010,
    STATE_3 = 3'b011,
    STATE_4 = 3'b100,
    STATE_5 = 3'b101,
    STATE_6 = 3'b110,
    STATE_7 = 3'b111;

// Current state and next state variables
reg [2:0] current_state, next_state;

// Define the sequence of values
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        current_state <= STATE_0; // Reset to the initial state
    end else if (enable) begin
        current_state <= next_state; // Update state when enabled
    end
end

// Output logic and state transition logic
always @(*) begin
    case (current_state)
        STATE_0: begin
            data = 8'hAF; // 0xAF
            next_state = STATE_1;
        end
        STATE_1: begin
            data = 8'hBC; // 0xBC
            next_state = STATE_2;
        end
        STATE_2: begin
            data = 8'hE2; // 0xE2
            next_state = STATE_3;
        end
        STATE_3: begin
            data = 8'h78; // 0x78
            next_state = STATE_4;
        end
        STATE_4: begin
            data = 8'hFF; // 0xFF
            next_state = STATE_5;
        end
        STATE_5: begin
            data = 8'hE2; // 0xE2
            next_state = STATE_6;
        end
        STATE_6: begin
            data = 8'h0B; // 0x0B
            next_state = STATE_7;
        end
        STATE_7: begin
            data = 8'h8D; // 0x8D
            next_state = STATE_0; // Go back to the first state
        end
        default: begin
            data = 8'h00; // Default case (shouldn't occur)
            next_state = STATE_0; // Safety fallback
        end
    endcase
end

endmodule
