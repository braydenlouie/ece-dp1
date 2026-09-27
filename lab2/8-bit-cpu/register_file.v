module register_file (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rf_write,
    input  wire [2:0] rf_addr,
    input  wire [7:0] rf_data_in,
    output wire [7:0] rf_data_out
);

    reg [7:0] regs [0:7];
    integer i;

    assign rf_data_out = regs[rf_addr];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= 8'h00;
        end else if (rf_write) begin
            regs[rf_addr] <= rf_data_in;
        end
    end

endmodule
