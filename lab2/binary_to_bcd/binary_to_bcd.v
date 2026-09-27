
module binary_to_bcd_converter (
    // Inputs
    input      [4:0] binary_input,

    // Outputs
    output reg [7:0] bcd_output
);

    // Internal registers to hold the individual BCD digits for clarity.
    // A 5-bit input (max 31) needs a tens digit up to 3 and a ones digit up to 9.
    // 4 bits are sufficient for each.
    reg [3:0] tens_digit;
    reg [3:0] ones_digit;

    // This block describes combinational logic. It will re-evaluate
    // whenever the `binary_input` signal changes.
    always @(*) begin
        // The division operator gives the integer part of the result.
        // For example, 27 / 10 = 2.
        tens_digit = binary_input / 10;

        // The modulus operator gives the remainder of the division.
        // For example, 27 % 10 = 7.
        ones_digit = binary_input % 10;

        // Concatenate the two 4-bit digits to form the final 8-bit BCD output.
        // The tens digit is the most significant nibble.
        bcd_output = {tens_digit, ones_digit};
    end

endmodule
