`timescale 1ns / 1ps

module tb_instruction_register;

    reg        clk;
    reg        rst_n;
    reg        ir_load;
    reg  [7:0] data_in;
    wire [3:0] opcode;
    wire [3:0] operand;

    instruction_register uut (
        .clk     (clk),
        .rst_n   (rst_n),
        .ir_load (ir_load),
        .data_in (data_in),
        .opcode  (opcode),
        .operand (operand)
    );

    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    task check_ir;
        input [3:0] exp_opcode;
        input [3:0] exp_operand;
        input [63:0] test_name;
    begin
        test_num = test_num + 1;
        @(negedge clk);
        if (opcode !== exp_opcode || operand !== exp_operand) begin
            $display("FAIL Test %0d [%s]: opcode=%h operand=%h, expected opcode=%h operand=%h",
                     test_num, test_name, opcode, operand, exp_opcode, exp_operand);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS Test %0d [%s]: opcode=%h operand=%h", test_num, test_name, opcode, operand);
            pass_count = pass_count + 1;
        end
    end
    endtask

    initial begin
        $display("========================================");
        $display("  Instruction Register TB Starting");
        $display("========================================");

        clk     = 0;
        rst_n   = 0;
        ir_load = 0;
        data_in = 8'h00;

        // Test: Reset clears IR
        @(posedge clk);
        check_ir(4'h0, 4'h0, "RESET  ");

        rst_n = 1;

        // Test: IR holds when ir_load=0
        data_in = 8'hAB;
        ir_load = 0;
        @(posedge clk);
        check_ir(4'h0, 4'h0, "HOLD   ");

        // Test: Load LDA R3 instruction (0x13)
        data_in = 8'h13;
        ir_load = 1;
        @(posedge clk);
        check_ir(4'h1, 4'h3, "LDA_R3 ");

        // Test: Load ADD R7 instruction (0x47)
        data_in = 8'h47;
        @(posedge clk);
        check_ir(4'h4, 4'h7, "ADD_R7 ");

        // Test: Load all zeros (INA instruction)
        data_in = 8'h00;
        @(posedge clk);
        check_ir(4'h0, 4'h0, "INA_0  ");

        // Test: Load all ones (OUTA 0xF)
        data_in = 8'hFF;
        @(posedge clk);
        check_ir(4'hF, 4'hF, "OUTA_F ");

        // Test: Load JMP 0x5 (0xC5)
        data_in = 8'hC5;
        @(posedge clk);
        check_ir(4'hC, 4'h5, "JMP_5  ");

        // Test: Hold after load disabled
        ir_load = 0;
        data_in = 8'h99;
        @(posedge clk);
        check_ir(4'hC, 4'h5, "HOLD2  ");

        // Test: LDI #0xF (0x3F)
        ir_load = 1;
        data_in = 8'h3F;
        @(posedge clk);
        check_ir(4'h3, 4'hF, "LDI_F  ");

        $display("\n========================================");
        $display("  IR Tests Complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("========================================");
        $finish;
    end

endmodule