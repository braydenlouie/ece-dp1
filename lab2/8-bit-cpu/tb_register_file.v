module tb_register_file;

    reg        clk;
    reg        rst_n;
    reg        rf_write;
    reg  [2:0] rf_addr;
    reg  [7:0] rf_data_in;
    wire [7:0] rf_data_out;

    register_file uut (
        .clk         (clk),
        .rst_n       (rst_n),
        .rf_write    (rf_write),
        .rf_addr     (rf_addr),
        .rf_data_in  (rf_data_in),
        .rf_data_out (rf_data_out)
    );

    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;
    integer i;

    task check_rf;
        input [7:0] expected;
        input [63:0] test_name;
    begin
        test_num = test_num + 1;
        #2; // allow combinational read to settle after rf_addr change
        if (rf_data_out !== expected) begin
            $display("FAIL Test %0d [%s]: addr=%0d data_out=%h, expected=%h",
                     test_num, test_name, rf_addr, rf_data_out, expected);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS Test %0d [%s]: addr=%0d data_out=%h",
                     test_num, test_name, rf_addr, rf_data_out);
            pass_count = pass_count + 1;
        end
    end
    endtask

    initial begin
        $display("========================================");
        $display("    Register File Testbench Starting");
        $display("========================================");

        clk        = 0;
        rst_n      = 0;
        rf_write   = 0;
        rf_addr    = 3'b000;
        rf_data_in = 8'h00;

        // Hold reset for a couple cycles
        repeat (2) @(posedge clk);
        @(negedge clk);

        // ============================================
        // Test: All registers zero after reset
        // ============================================
        $display("\n--- Reset State Check ---");
        for (i = 0; i < 8; i = i + 1) begin
            rf_addr = i[2:0];
            check_rf(8'h00, "RST_CHK");
        end

        // Release reset
        @(negedge clk);
        rst_n = 1;
        @(posedge clk);

        // ============================================
        // Test: Write to each register sequentially
        // R0=0x11, R1=0x22, R2=0x33, ... R7=0x88
        // ============================================
        $display("\n--- Write All Registers ---");
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge clk);
            rf_write   = 1;
            rf_addr    = i[2:0];
            rf_data_in = (i + 1) * 8'h11;
            @(posedge clk);  // write happens on this edge
        end
        @(negedge clk);
        rf_write = 0;

        // ============================================
        // Test: Read back all registers
        // ============================================
        $display("\n--- Read Back All Registers ---");
        for (i = 0; i < 8; i = i + 1) begin
            rf_addr = i[2:0];
            check_rf((i + 1) * 8'h11, "RD_BACK");
        end

        // ============================================
        // Test: Write to R3 does NOT affect R2 or R4
        // ============================================
        $display("\n--- Isolation Test ---");
        @(negedge clk);
        rf_write   = 1;
        rf_addr    = 3'd3;
        rf_data_in = 8'hAA;
        @(posedge clk);  // write R3=0xAA
        @(negedge clk);
        rf_write = 0;

        // Check R3 was written
        rf_addr = 3'd3;
        check_rf(8'hAA, "WR_R3  ");

        // Check R2 was NOT affected (should still be 0x33)
        rf_addr = 3'd2;
        check_rf(8'h33, "ISO_R2 ");

        // Check R4 was NOT affected (should still be 0x55)
        rf_addr = 3'd4;
        check_rf(8'h55, "ISO_R4 ");

        // ============================================
        // Test: Overwrite R0
        // ============================================
        $display("\n--- Overwrite Test ---");
        @(negedge clk);
        rf_write   = 1;
        rf_addr    = 3'd0;
        rf_data_in = 8'hFF;
        @(posedge clk);  // write R0=0xFF
        @(negedge clk);
        rf_write = 0;

        rf_addr = 3'd0;
        check_rf(8'hFF, "OVR_R0 ");

        // ============================================
        // Test: Write 0x00 to R7
        // ============================================
        $display("\n--- Write Zero Test ---");
        @(negedge clk);
        rf_write   = 1;
        rf_addr    = 3'd7;
        rf_data_in = 8'h00;
        @(posedge clk);  // write R7=0x00
        @(negedge clk);
        rf_write = 0;

        rf_addr = 3'd7;
        check_rf(8'h00, "WR_ZR_7");

        // ============================================
        // Test: rf_write=0 should NOT modify register
        // ============================================
        $display("\n--- Write Enable Gating Test ---");
        // R5 should still be 0x66 from the initial write
        @(negedge clk);
        rf_write   = 0;
        rf_addr    = 3'd5;
        rf_data_in = 8'hDE;  // try to write 0xDE with rf_write=0
        @(posedge clk);
        @(negedge clk);

        rf_addr = 3'd5;
        check_rf(8'h66, "NO_WR_5");

        // ============================================
        // Test: Mid-operation reset clears all regs
        // ============================================
        $display("\n--- Mid-Operation Reset ---");
        @(negedge clk);
        rst_n = 0;
        @(posedge clk);  // reset takes effect
        @(negedge clk);

        for (i = 0; i < 8; i = i + 1) begin
            rf_addr = i[2:0];
            check_rf(8'h00, "RST2_CK");
        end

        // ============================================
        // Test: Write and read same cycle (write-through or read-after-write)
        // ============================================
        $display("\n--- Write Then Immediate Read ---");
        @(negedge clk);
        rst_n = 1;
        @(posedge clk);

        @(negedge clk);
        rf_write   = 1;
        rf_addr    = 3'd0;
        rf_data_in = 8'hBE;
        @(posedge clk);  // write R0=0xBE
        @(negedge clk);
        rf_write = 0;

        // Read R0 immediately
        rf_addr = 3'd0;
        check_rf(8'hBE, "WRTHR_0");

        // ============================================
        // Test: Write different register, verify old ones unchanged
        // ============================================
        $display("\n--- Sequential Independence ---");
        @(negedge clk);
        rf_write   = 1;
        rf_addr    = 3'd1;
        rf_data_in = 8'hEF;
        @(posedge clk);  // write R1=0xEF
        @(negedge clk);
        rf_write = 0;

        rf_addr = 3'd1;
        check_rf(8'hEF, "SEQ_R1 ");

        rf_addr = 3'd0;
        check_rf(8'hBE, "SEQ_R0 ");  // R0 should still be 0xBE

        $display("\n========================================");
        $display("  RF Tests Complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("*** ALL REGISTER FILE TESTS PASSED ***");
        else
            $display("*** SOME TESTS FAILED ***");

        $finish;
    end

    // Timeout
    initial begin
        #50000;
        $display("TIMEOUT");
        $finish;
    end

endmodule