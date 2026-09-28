module tb_output_register;

    reg        clk;
    reg        rst_n;
    reg        out_load;
    reg  [7:0] data_in;
    wire [7:0] out_port;
    wire       out_valid;

    output_register uut (
        .clk       (clk),
        .rst_n     (rst_n),
        .out_load  (out_load),
        .data_in   (data_in),
        .out_port  (out_port),
        .out_valid (out_valid)
    );

    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    task check_out;
        input [7:0] exp_data;
        input       exp_valid;
        input [63:0] test_name;
    begin
        test_num = test_num + 1;
        @(negedge clk);
        if (out_port !== exp_data || out_valid !== exp_valid) begin
            $display("FAIL Test %0d [%s]: port=%h valid=%b, expected port=%h valid=%b",
                     test_num, test_name, out_port, out_valid, exp_data, exp_valid);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS Test %0d [%s]: port=%h valid=%b", test_num, test_name, out_port, out_valid);
            pass_count = pass_count + 1;
        end
    end
    endtask

    initial begin
        $display("========================================");
        $display("   Output Register Testbench Starting");
        $display("========================================");

        clk      = 0;
        rst_n    = 0;
        out_load = 0;
        data_in  = 8'h00;

        // Test: Reset
        @(posedge clk);
        check_out(8'h00, 1'b0, "RESET  ");

        rst_n = 1;

        // Test: Hold when out_load=0
        data_in  = 8'hAA;
        out_load = 0;
        @(posedge clk);
        check_out(8'h00, 1'b0, "HOLD   ");

        // Test: Load value, out_valid asserts
        out_load = 1;
        data_in  = 8'h42;
        @(posedge clk);
        check_out(8'h42, 1'b1, "LOAD_42");

        // Test: out_valid deasserts when out_load removed
        out_load = 0;
        @(posedge clk);
        check_out(8'h42, 1'b0, "DVALID ");

        // Test: Load 0xFF
        out_load = 1;
        data_in  = 8'hFF;
        @(posedge clk);
        check_out(8'hFF, 1'b1, "LOAD_FF");

        // Test: Load 0x00
        data_in = 8'h00;
        @(posedge clk);
        check_out(8'h00, 1'b1, "LOAD_00");

        // Test: Data held after load removed
        out_load = 0;
        @(posedge clk);
        check_out(8'h00, 1'b0, "HOLD_00");

        $display("\n========================================");
        $display("  OUT Tests Complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("========================================");
        $finish;
    end

endmodule