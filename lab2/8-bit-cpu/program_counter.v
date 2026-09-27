module program_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       pc_inc,
    input  wire       pc_load,
    input  wire [7:0] pc_in,
    output reg  [7:0] pc_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_out <= 8'h00;
        else if (pc_load)
            pc_out <= pc_in;
        else if (pc_inc)
            pc_out <= pc_out + 8'h01;
    end

endmodule
