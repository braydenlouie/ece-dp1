`timescale 1ns / 1ps

module tb_flags_register;

    reg        clk;
    reg        rst_n;
    reg        flags_load;
    reg        z_in;
    reg        c_in;
    wire       z_flag;
    wire       c_flag;

    flags_register uut (
        .clk        (clk),
        .rst_n      (rst_n),
        .flags_load (flags_load),
        .z_in       (z_in),
        .c_in       (c_in),
        .z_flag     (z_flag),
        .c_flag     (c_flag)
    );

    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    task check_flags;
        input exp_z;
        input exp_c;
        input [63:0] test_name;
    begin
        test_num = test_num + 1;
        @(negedge clk);
        if (z_flag !== exp_z || c_flag !== exp_c) begin
            $display("FAIL Test %0d [%s]: z=%b c=%b, expected z=%b c=%b",
                     test_num, test_name, z_flag, c_flag, exp_z, exp_c);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS Test %0d [%s]: z=%b c=%b", test_num, test_name, z_flag, c_flag);
            pass_count = pass_count + 1;
        end
    end
    endtask

    initial begin
        $display("========================================");
        $display("    Flags Register Testbench Starting");
        $display("========================================");

        clk        = 0;
        rst_n      = 0;
        flags_load = 0;
        z_in       = 0;
        c_in       = 0;

        // Test: Reset clears flags
        @(posedge clk);
        check_flags(1'b0, 1'b0, "RESET  ");

        rst_n = 1;

        // Test: Hold when flags_load=0
        z_in = 1; c_in = 1;
        flags_load = 0;
        @(posedge clk);
        check_flags(1'b0, 1'b0, "HOLD   ");

        // Test: Set both flags
        flags_load = 1;
        z_in = 1; c_in = 1;
        @(posedge clk);
        check_flags(1'b1, 1'b1, "SET_ZC ");

        // Test: Clear zero, keep carry
        z_in = 0; c_in = 1;
        @(posedge clk);
        check_flags(1'b0, 1'b1, "CLR_Z  ");

        // Test: Set zero, clear carry
        z_in = 1; c_in = 0;
        @(posedge clk);
        check_flags(1'b1, 1'b0, "SET_Z  ");

        // Test: Clear both
        z_in = 0; c_in = 0;
        @(posedge clk);
        check_flags(1'b0, 1'b0, "CLR_ZC ");

        // Test: Hold after disabling load
        flags_load = 1;
        z_in = 1; c_in = 1;
        @(posedge clk);
        check_flags(1'b1, 1'b1, "SET2   ");
        flags_load = 0;
        z_in = 0; c_in = 0;
        @(posedge clk);
        check_flags(1'b1, 1'b1, "HOLD2  ");

        $display("\n========================================");
        $display("  Flags Tests Complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("========================================");
        $finish;
    end

endmodule