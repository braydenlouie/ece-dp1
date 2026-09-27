
module traffic_light_fsm(
    input wire clk,          // Clock input
    input wire reset_n,       // Active-low reset
    input wire enable,      // Enable signal
    output reg red,         // Red light output
    output reg yellow,      // Yellow light output
    output reg green        // Green light output
);

    // State definitions
    localparam RED = 2'b00;
    localparam GREEN = 2'b01;
    localparam YELLOW = 2'b10;

    reg [1:0] state;        // Current state
    reg [4:0] counter;      // 5-bit counter to hold the number of clock cycles

    // State transition logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= RED;          // Reset to RED state
            counter <= 0;         // Reset counter
        end else if (enable) begin
            case (state)
                RED: begin
                    if (counter == 31) begin  // 32 clock cycles
                        state <= GREEN;
                        counter <= 0;          // Reset counter for the next state
                    end else begin
                        counter <= counter + 1; // Increment counter
                    end
                end
                
                GREEN: begin
                    if (counter == 19) begin  // 20 clock cycles
                        state <= YELLOW;
                        counter <= 0;          // Reset counter for the next state
                    end else begin
                        counter <= counter + 1; // Increment counter
                    end
                end
                
                YELLOW: begin
                    if (counter == 6) begin   // 7 clock cycles
                        state <= RED;
                        counter <= 0;          // Reset counter for the next state
                    end else begin
                        counter <= counter + 1; // Increment counter
                    end
                end
            
                default: begin
                    state <= RED;            // Default to RED in case of an unknown state
                    counter <= 0;           // Reset counter
                end
            endcase
        end
    end

    // Output logic based on the current state
    always @(*) begin
        // Default output states to low
        red = 1'b0;
        yellow = 1'b0;
        green = 1'b0;

        case (state)
            RED:    red = 1'b1;
            GREEN:  green = 1'b1;
            YELLOW: yellow = 1'b1;
        endcase
    end

endmodule
