`timescale 1ns / 1ps

module tb_accumulator;

    reg        clk;
    reg        rst_n;
    reg        acc_load;
    reg  [7:0] acc_in;
    wire [7:0] acc_out;

    accumulator uut (
        .clk      (clk),
        .rst_n    (rst_n),
        .acc_load (acc_load),
        .acc_in   (acc_in),
        .acc_out  (acc_out)
    );

    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    task check_acc;
        input [7:0] expected;
        input [63:0] test_name;
    begin
        test_num = test_num + 1;
        @(negedge clk);
        if (acc_out !== expected) begin
            $display("FAIL Test %0d [%s]: acc_out=%h, expected=%h", test_num, test_name, acc_out, expected);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS Test %0d [%s]: acc_out=%h", test_num, test_name, acc_out);
            pass_count = pass_count + 1;
        end
    end
    endtask

    initial begin
        $display("========================================");
        $display("     Accumulator Testbench Starting");
        $display("========================================");

        clk      = 0;
        rst_n    = 0;
        acc_load = 0;
        acc_in   = 8'h00;

        // Test: Reset
        @(posedge clk);
        check_acc(8'h00, "RESET  ");

        rst_n = 1;

        // Test: Hold when acc_load=0
        acc_in   = 8'hAB;
        acc_load = 0;
        @(posedge clk);
        check_acc(8'h00, "HOLD   ");

        // Test: Load value
        acc_load = 1;
        acc_in   = 8'h42;
        @(posedge clk);
        check_acc(8'h42, "LOAD_42");

        // Test: Load 0xFF
        acc_in = 8'hFF;
        @(posedge clk);
        check_acc(8'hFF, "LOAD_FF");

        // Test: Load 0x00
        acc_in = 8'h00;
        @(posedge clk);
        check_acc(8'h00, "LOAD_00");

        // Test: Hold loaded value
        acc_in   = 8'h55;
        acc_load = 0;
        @(posedge clk);
        check_acc(8'h00, "HOLD2  ");

        // Test: Rapid load changes
        acc_load = 1;
        acc_in   = 8'hAA;
        @(posedge clk);
        check_acc(8'hAA, "RAPID1 ");
        acc_in = 8'h55;
        @(posedge clk);
        check_acc(8'h55, "RAPID2 ");
        acc_in = 8'h01;
        @(posedge clk);
        check_acc(8'h01, "RAPID3 ");

        $display("\n========================================");
        $display("  ACC Tests Complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("========================================");
        $finish;
    end

endmodule