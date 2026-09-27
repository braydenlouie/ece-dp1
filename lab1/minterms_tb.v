`timescale 1ps/1ps

module minterm_tb;

    reg A, B, C, D;
    wire F;
    integer i;

    minterms dut(.A(A), .B(B), .C(C), .D(D), .F(F));

    initial begin
        $dumpfile("minterms.vcd");
        $dumpvars(0, minterm_tb); 
        for (i = 0; i < 16; i = i + 1) begin
            {A, B, C, D} = i[3:0];
            #10;
        end

        $finish;
    end

endmodule