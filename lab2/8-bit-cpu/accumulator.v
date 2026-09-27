module accumulator (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       acc_load,
    input  wire [7:0] acc_in,
    output reg  [7:0] acc_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            acc_out <= 8'h00;
        else if (acc_load)
            acc_out <= acc_in;
    end

endmodule
