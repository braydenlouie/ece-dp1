
module sequence_detector (
    input wire clk,
    input wire reset_n,
    input wire [2:0] data,
    output reg sequence_found
);

    // State Encoding
    typedef enum reg [3:0] {
        S0 = 4'b0000, // Initial State
        S1 = 4'b0001, // Detected 0b001
        S2 = 4'b0010, // Detected 0b101
        S3 = 4'b0011, // Detected 0b110
        S4 = 4'b0100, // Detected 0b000
        S5 = 4'b0101, // Detected 0b110 (again)
        S6 = 4'b0110, // Detected 0b110 (third time)
        S7 = 4'b0111  // Detected 0b011
    } state_t;

    state_t current_state, next_state;

    // State Transition Logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_state <= S0; // Reset to initial state
            sequence_found <= 0; // Clear sequence_found on reset
        end else begin
            current_state <= next_state; // Update to the next state
        end
    end

    // Next State Logic based on current state and input data
    always @(*) begin
        // Default assignment for next state
        next_state = current_state; 
        sequence_found = 0; // Default output

        case (current_state)
            S0: begin
                if (data == 3'b001) next_state = S1;
            end
            S1: begin
                if (data == 3'b101) next_state = S2;
            end
            S2: begin
                if (data == 3'b110) next_state = S3;
            end
            S3: begin
                if (data == 3'b000) next_state = S4;
            end
            S4: begin
                if (data == 3'b110) next_state = S5; // Detected 0b110 again
            end
            S5: begin
                if (data == 3'b110) next_state = S6; // Detected 0b110 again
            end
            S6: begin
                if (data == 3'b011) next_state = S7; // Detected 0b011
            end
            S7: begin
                if (data == 3'b101) begin
                    next_state = S2; // Cycle back to detect 0b101 again after 0b011
                    sequence_found = 1; // We found the sequence
                end
            end
        endcase
    end

endmodule
