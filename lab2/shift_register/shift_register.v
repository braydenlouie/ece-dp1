
module shift_register (
    input wire clk,                 // Clock input
    input wire reset_n,             // Active-low reset
    input wire data_in,             // 1-bit data input
    input wire shift_enable,         // Shift enable input
    output reg [7:0] data_out       // 8-bit data output
);

    // Initial value for data_out
    initial begin
        data_out = 8'b00000000;      // Initialize data_out to 0
    end

    // Always block triggered on the rising edge of the clock or on reset
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Active-low reset (reset the shift register)
            data_out <= 8'b00000000;  // Reset data_out to 0
        end else if (shift_enable) begin
            // Shift operation
            data_out <= {data_out[6:0], data_in}; // Shift left and input data_in at LSB
        end
    end

endmodule
