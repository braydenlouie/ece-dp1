module flags_register (
    input  wire clk,
    input  wire rst_n,
    input  wire flags_load,
    input  wire z_in,
    input  wire c_in,
    output reg  z_flag,
    output reg  c_flag
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            z_flag <= 1'b0;
            c_flag <= 1'b0;
        end else if (flags_load) begin
            z_flag <= z_in;
            c_flag <= c_in;
        end
    end

endmodule
