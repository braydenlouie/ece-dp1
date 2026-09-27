
module dice_roller (
    input wire clk,                    // Clock input
    input wire rst_n,                // Active-low reset
    input wire [1:0] die_select,       // 2-bits for die selection
    input wire roll,                   // Roll trigger
    output reg [7:0] rolled_number      // Output rolled number (8-bits)
);

    // Define the die sizes based on the die_select
    parameter DIE_4_SIDES = 2'b00;
    parameter DIE_6_SIDES = 2'b01;
    parameter DIE_8_SIDES = 2'b10;
    parameter DIE_20_SIDES = 2'b11;

    reg [7:0] max_number; // Max number based on die selected
    reg rolling;          // Flag to indicate rolling in progress

    // Random number generation (simple Linear Congruential Generator for simulation)
    reg [7:0] rand_num; // Store random number

    // Simple LFSR or counter to generate pseudo-random numbers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rand_num <= 8'h1; // Seed value
        end else begin
            // Update random number (example LCG, multiply by a constant and mod)
            rand_num <= (rand_num * 1103515245 + 12345) % 256;
        end
    end

    // Determine max number based on die_select
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_number <= 0;
        end else begin
            case (die_select)
                DIE_4_SIDES: max_number <= 4;
                DIE_6_SIDES: max_number <= 6;
                DIE_8_SIDES: max_number <= 8;
                DIE_20_SIDES: max_number <= 20;
                default: max_number <= 0; // In case of undefined input
            endcase
        end
    end

    // Handle roll input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rolled_number <= 0;
            rolling <= 0;
        end else begin
            if (roll && !rolling) begin
                rolling <= 1; // Start rolling
                rolled_number <= 1 + (rand_num % max_number); // Generate rolled number
            end else if (!roll) begin
                rolling <= 0; // Stop rolling when roll is low
            end
        end
    end

endmodule
