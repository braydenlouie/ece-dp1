module instruction_register (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ir_load,
    input  wire [7:0] data_in,
    output reg  [3:0] opcode,
    output reg  [3:0] operand
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            opcode  <= 4'h0;
            operand <= 4'h0;
        end else if (ir_load) begin
            opcode  <= data_in[7:4];
            operand <= data_in[3:0];
        end
    end

endmodule
