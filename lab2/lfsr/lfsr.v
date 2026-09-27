
module lfsr (
    input  wire       clk,
    input  wire       reset_n,
    output wire [7:0] data
);

    reg [7:0] lfsr_reg;

    // Feedback: XOR of bits at positions 0, 3, 5, and 6 (taps 1, 4, 6, 7)
    wire feedback;
    assign feedback = lfsr_reg[0] ^ lfsr_reg[3] ^ lfsr_reg[5] ^ lfsr_reg[6];

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lfsr_reg <= 8'b10001010;  // Initial state
        end else begin
            lfsr_reg <= {lfsr_reg[6:0], feedback};  // Shift left, new bit enters at LSB
        end
    end

    assign data = lfsr_reg;

endmodule
