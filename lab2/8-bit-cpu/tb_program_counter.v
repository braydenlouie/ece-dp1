`timescale 1ns / 1ps

module tb_program_counter;

    reg        clk;
    reg        rst_n;
    reg        pc_inc;
    reg        pc_load;
    reg  [7:0] pc_in;
    wire [7:0] pc_out;

    program_counter uut (
        .clk     (clk),
        .rst_n   (rst_n),
        .pc_inc  (pc_inc),
        .pc_load (pc_load),
        .pc_in   (pc_in),
        .pc_out  (pc_out)
    );

    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    task check_pc;
        input [7:0] expected;
        input [63:0] test_name;
    begin
        test_num = test_num + 1;
        @(negedge clk); // sample after clock edge
        if (pc_out !== expected) begin
            $display("FAIL Test %0d [%s]: pc_out=%h, expected=%h", test_num, test_name, pc_out, expected);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS Test %0d [%s]: pc_out=%h", test_num, test_name, pc_out);
            pass_count = pass_count + 1;
        end
    end
    endtask

    initial begin
        $display("========================================");
        $display("   Program Counter Testbench Starting");
        $display("========================================");

        clk     = 0;
        rst_n   = 0;
        pc_inc  = 0;
        pc_load = 0;
        pc_in   = 8'h00;

        // Test: Reset clears PC to 0
        @(posedge clk);
        check_pc(8'h00, "RESET  ");

        // Release reset
        rst_n = 1;

        // Test: PC holds value when no inc/load
        @(posedge clk);
        check_pc(8'h00, "HOLD   ");

        // Test: PC increments
        pc_inc = 1;
        @(posedge clk);
        check_pc(8'h01, "INC_1  ");

        @(posedge clk);
        check_pc(8'h02, "INC_2  ");

        @(posedge clk);
        check_pc(8'h03, "INC_3  ");

        // Test: PC load overrides increment
        pc_inc  = 1;
        pc_load = 1;
        pc_in   = 8'hA0;
        @(posedge clk);
        check_pc(8'hA0, "LOAD   ");

        // Test: Continue incrementing from loaded address
        pc_load = 0;
        pc_inc  = 1;
        @(posedge clk);
        check_pc(8'hA1, "INC_LDA");

        @(posedge clk);
        check_pc(8'hA2, "INC_LD2");

        // Test: PC wraps around from 0xFF to 0x00
        pc_load = 1;
        pc_in   = 8'hFE;
        @(posedge clk);
        check_pc(8'hFE, "LOAD_FE");

        pc_load = 0;
        pc_inc  = 1;
        @(posedge clk);
        check_pc(8'hFF, "INC_FF ");

        @(posedge clk);
        check_pc(8'h00, "WRAP_00");

        @(posedge clk);
        check_pc(8'h01, "WRAP_01");

        // Test: Load to address 0
        pc_load = 1;
        pc_in   = 8'h00;
        @(posedge clk);
        check_pc(8'h00, "LOAD_00");

        // Test: Load to 0xFF
        pc_in = 8'hFF;
        @(posedge clk);
        check_pc(8'hFF, "LOAD_FF");

        // Test: Reset during operation
        pc_load = 0;
        pc_inc  = 1;
        rst_n   = 0;
        @(posedge clk);
        check_pc(8'h00, "RST_MID");

        // Release reset, verify normal operation resumes
        rst_n = 1;
        pc_inc = 1;
        @(posedge clk);
        check_pc(8'h01, "AFT_RST");

        $display("\n========================================");
        $display("  PC Tests Complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("========================================");
        $finish;
    end

endmodule