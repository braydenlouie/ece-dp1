module alu (
    input  wire [7:0] a_in,
    input  wire [7:0] b_in,
    input  wire [2:0] alu_op,
    output reg  [7:0] alu_result,
    output reg        alu_carry,
    output wire       alu_zero
);

    wire [8:0] add_result;
    wire [8:0] sub_result;

    assign add_result = {1'b0, a_in} + {1'b0, b_in};
    assign sub_result = {1'b0, a_in} - {1'b0, b_in};
    assign alu_zero   = (alu_result == 8'h00);

    always @(*) begin
        alu_carry = 1'b0;
        case (alu_op)
            3'b000: begin
                alu_result = add_result[7:0];
                alu_carry  = add_result[8];
            end
            3'b001: begin
                alu_result = sub_result[7:0];
                alu_carry  = sub_result[8];
            end
            3'b010: alu_result = a_in & b_in;
            3'b011: alu_result = a_in | b_in;
            3'b100: alu_result = a_in ^ b_in;
            3'b101: alu_result = ~a_in;
            3'b110: begin
                alu_result = {a_in[6:0], 1'b0};
                alu_carry  = a_in[7];
            end
            3'b111: begin
                alu_result = {1'b0, a_in[7:1]};
                alu_carry  = a_in[0];
            end
        endcase
    end

endmodule
