module output_register (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       out_load,
    input  wire [7:0] data_in,
    output reg  [7:0] out_port,
    output reg        out_valid
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_port  <= 8'h00;
            out_valid <= 1'b0;
        end else begin
            out_valid <= out_load;
            if (out_load)
                out_port <= data_in;
        end
    end

endmodule
