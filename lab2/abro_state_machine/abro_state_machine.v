
module abro_state_machine (
    input wire clk,
    input wire rst_n,
    input wire A,
    input wire B,
    output reg O,
    output reg [3:0] State
);

    // Define state encoding
    parameter STATE_A = 4'b0001; // A detected
    parameter STATE_B = 4'b0010; // B detected
    parameter STATE_AB = 4'b0100; // A followed by B

    // Current state and next state variables
    reg [3:0] current_state, next_state;

    // Synchronous logic for state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_A; // Reset to initial state
            O <= 0; // Reset output
        end else begin
            current_state <= next_state; // Update state
        end
    end

    // Combinational logic for next state and output
    always @(*) begin
        // Default values for next_state and output
        next_state = current_state;
        O = 0;

        case (current_state)
            STATE_A: begin
                if (A) begin
                    next_state = STATE_A; // Stay in state A
                end else if (B) begin
                    next_state = STATE_B; // Transition to state B
                end
            end
            
            STATE_B: begin
                if (A) begin
                    next_state = STATE_AB; // Transition to state AB
                end else begin
                    next_state = STATE_B; // Stay in state B
                end
            end
            
            STATE_AB: begin
                O = 1; // Output is high when in state AB
                // Optionally, define your transition behavior here
                // For example, you could return to initial state or hold.
                if (!A && !B) begin
                    next_state = STATE_A; // Return to state A on both low inputs
                end else if (A && !B) begin
                    next_state = STATE_A; // Stay in state A
                end else if (!A && B) begin
                    next_state = STATE_B; // Stay in state B
                end
            end
            
            default: begin
                next_state = STATE_A; // Safe default
            end
        endcase
    end

    // Assign current state to output State
    always @(*) begin
        State = current_state; // Output the current state
    end

endmodule
