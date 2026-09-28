`timescale 1ns / 1ps

module tb_alu;

    reg  [7:0] a_in;
    reg  [7:0] b_in;
    reg  [2:0] alu_op;
    wire [7:0] alu_result;
    wire       alu_carry;
    wire       alu_zero;

    alu uut (
        .a_in       (a_in),
        .b_in       (b_in),
        .alu_op     (alu_op),
        .alu_result (alu_result),
        .alu_carry  (alu_carry),
        .alu_zero   (alu_zero)
    );

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    task check;
        input [7:0] exp_result;
        input       exp_carry;
        input       exp_zero;
        input [63:0] test_name; // 8 chars max for display
    begin
        test_num = test_num + 1;
        #1;
        if (alu_result !== exp_result || alu_carry !== exp_carry || alu_zero !== exp_zero) begin
            $display("FAIL Test %0d [%s]: a=%h b=%h op=%b | Got: result=%h carry=%b zero=%b | Exp: result=%h carry=%b zero=%b",
                     test_num, test_name, a_in, b_in, alu_op,
                     alu_result, alu_carry, alu_zero,
                     exp_result, exp_carry, exp_zero);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS Test %0d [%s]: a=%h b=%h op=%b -> result=%h carry=%b zero=%b",
                     test_num, test_name, a_in, b_in, alu_op,
                     alu_result, alu_carry, alu_zero);
            pass_count = pass_count + 1;
        end
    end
    endtask

    initial begin
        $display("========================================");
        $display("        ALU Testbench Starting");
        $display("========================================");

        // ============================================================
        // ADD (alu_op = 3'b000)
        // ============================================================
        $display("\n--- ADD Tests (alu_op=000) ---");

        // Test: Basic addition
        a_in = 8'h03; b_in = 8'h05; alu_op = 3'b000;
        check(8'h08, 1'b0, 1'b0, "ADD_BAS");

        // Test: Addition resulting in zero (0 + 0)
        a_in = 8'h00; b_in = 8'h00; alu_op = 3'b000;
        check(8'h00, 1'b0, 1'b1, "ADD_ZRO");

        // Test: Addition with carry out (overflow)
        a_in = 8'hFF; b_in = 8'h01; alu_op = 3'b000;
        check(8'h00, 1'b1, 1'b1, "ADD_OVF");

        // Test: Addition with carry, non-zero result
        a_in = 8'hFF; b_in = 8'hFF; alu_op = 3'b000;
        check(8'hFE, 1'b1, 1'b0, "ADD_CF2");

        // Test: Addition max + 0 (no carry)
        a_in = 8'hFF; b_in = 8'h00; alu_op = 3'b000;
        check(8'hFF, 1'b0, 1'b0, "ADD_MAX");

        // Test: Mid-range carry boundary
        a_in = 8'h80; b_in = 8'h80; alu_op = 3'b000;
        check(8'h00, 1'b1, 1'b1, "ADD_128");

        // Test: Single bit additions
        a_in = 8'h01; b_in = 8'h01; alu_op = 3'b000;
        check(8'h02, 1'b0, 1'b0, "ADD_1+1");

        // ============================================================
        // SUB (alu_op = 3'b001)
        // ============================================================
        $display("\n--- SUB Tests (alu_op=001) ---");

        // Test: Basic subtraction
        a_in = 8'h08; b_in = 8'h03; alu_op = 3'b001;
        check(8'h05, 1'b0, 1'b0, "SUB_BAS");

        // Test: Subtraction resulting in zero
        a_in = 8'h42; b_in = 8'h42; alu_op = 3'b001;
        check(8'h00, 1'b0, 1'b1, "SUB_EQL");

        // Test: Subtraction with borrow (underflow)
        a_in = 8'h00; b_in = 8'h01; alu_op = 3'b001;
        check(8'hFF, 1'b1, 1'b0, "SUB_UNF");

        // Test: Subtract from max
        a_in = 8'hFF; b_in = 8'hFF; alu_op = 3'b001;
        check(8'h00, 1'b0, 1'b1, "SUB_MAX");

        // Test: Subtract zero
        a_in = 8'h55; b_in = 8'h00; alu_op = 3'b001;
        check(8'h55, 1'b0, 1'b0, "SUB_ZR0");

        // Test: 0 - 0
        a_in = 8'h00; b_in = 8'h00; alu_op = 3'b001;
        check(8'h00, 1'b0, 1'b1, "SUB_0_0");

        // Test: Large borrow
        a_in = 8'h01; b_in = 8'hFF; alu_op = 3'b001;
        check(8'h02, 1'b1, 1'b0, "SUB_LB ");

        // ============================================================
        // AND (alu_op = 3'b010)
        // ============================================================
        $display("\n--- AND Tests (alu_op=010) ---");

        // Test: Basic AND
        a_in = 8'hF0; b_in = 8'h0F; alu_op = 3'b010;
        check(8'h00, 1'b0, 1'b1, "AND_BAS");

        // Test: AND with all ones
        a_in = 8'hFF; b_in = 8'hFF; alu_op = 3'b010;
        check(8'hFF, 1'b0, 1'b0, "AND_ALL");

        // Test: AND identity
        a_in = 8'hA5; b_in = 8'hFF; alu_op = 3'b010;
        check(8'hA5, 1'b0, 1'b0, "AND_ID ");

        // Test: AND with zero
        a_in = 8'hA5; b_in = 8'h00; alu_op = 3'b010;
        check(8'h00, 1'b0, 1'b1, "AND_ZRO");

        // Test: Alternating pattern
        a_in = 8'hAA; b_in = 8'h55; alu_op = 3'b010;
        check(8'h00, 1'b0, 1'b1, "AND_ALT");

        // Test: Single bit mask
        a_in = 8'hFF; b_in = 8'h01; alu_op = 3'b010;
        check(8'h01, 1'b0, 1'b0, "AND_BIT");

        // ============================================================
        // OR (alu_op = 3'b011)
        // ============================================================
        $display("\n--- OR Tests (alu_op=011) ---");

        // Test: Basic OR
        a_in = 8'hF0; b_in = 8'h0F; alu_op = 3'b011;
        check(8'hFF, 1'b0, 1'b0, "OR_BAS ");

        // Test: OR with zero (identity)
        a_in = 8'hA5; b_in = 8'h00; alu_op = 3'b011;
        check(8'hA5, 1'b0, 1'b0, "OR_ID  ");

        // Test: OR zero with zero
        a_in = 8'h00; b_in = 8'h00; alu_op = 3'b011;
        check(8'h00, 1'b0, 1'b1, "OR_ZERO");

        // Test: OR already set bits
        a_in = 8'hFF; b_in = 8'hFF; alu_op = 3'b011;
        check(8'hFF, 1'b0, 1'b0, "OR_ALL ");

        // ============================================================
        // XOR (alu_op = 3'b100)
        // ============================================================
        $display("\n--- XOR Tests (alu_op=100) ---");

        // Test: XOR with self (zero result)
        a_in = 8'hA5; b_in = 8'hA5; alu_op = 3'b100;
        check(8'h00, 1'b0, 1'b1, "XOR_SLF");

        // Test: XOR with all ones (inversion)
        a_in = 8'hA5; b_in = 8'hFF; alu_op = 3'b100;
        check(8'h5A, 1'b0, 1'b0, "XOR_INV");

        // Test: XOR with zero (identity)
        a_in = 8'hA5; b_in = 8'h00; alu_op = 3'b100;
        check(8'hA5, 1'b0, 1'b0, "XOR_ID ");

        // Test: XOR complementary patterns
        a_in = 8'hF0; b_in = 8'h0F; alu_op = 3'b100;
        check(8'hFF, 1'b0, 1'b0, "XOR_CMP");

        // Test: XOR 0 ^ 0
        a_in = 8'h00; b_in = 8'h00; alu_op = 3'b100;
        check(8'h00, 1'b0, 1'b1, "XOR_ZR0");

        // ============================================================
        // NOT (alu_op = 3'b101)
        // ============================================================
        $display("\n--- NOT Tests (alu_op=101) ---");

        // Test: NOT of zero
        a_in = 8'h00; b_in = 8'h00; alu_op = 3'b101;
        check(8'hFF, 1'b0, 1'b0, "NOT_ZRO");

        // Test: NOT of all ones
        a_in = 8'hFF; b_in = 8'h00; alu_op = 3'b101;
        check(8'h00, 1'b0, 1'b1, "NOT_ALL");

        // Test: NOT of alternating
        a_in = 8'hAA; b_in = 8'h00; alu_op = 3'b101;
        check(8'h55, 1'b0, 1'b0, "NOT_ALT");

        // Test: NOT of 0x0F
        a_in = 8'h0F; b_in = 8'hXX; alu_op = 3'b101; // b_in irrelevant
        check(8'hF0, 1'b0, 1'b0, "NOT_0F ");

        // ============================================================
        // SHL (alu_op = 3'b110)
        // ============================================================
        $display("\n--- SHL Tests (alu_op=110) ---");

        // Test: SHL basic (no carry out)
        a_in = 8'h01; b_in = 8'h00; alu_op = 3'b110;
        check(8'h02, 1'b0, 1'b0, "SHL_BAS");

        // Test: SHL with carry out (MSB was 1)
        a_in = 8'h80; b_in = 8'h00; alu_op = 3'b110;
        check(8'h00, 1'b1, 1'b1, "SHL_MSB");

        // Test: SHL all ones
        a_in = 8'hFF; b_in = 8'h00; alu_op = 3'b110;
        check(8'hFE, 1'b1, 1'b0, "SHL_ALL");

        // Test: SHL zero
        a_in = 8'h00; b_in = 8'h00; alu_op = 3'b110;
        check(8'h00, 1'b0, 1'b1, "SHL_ZRO");

        // Test: SHL alternating pattern
        a_in = 8'hAA; b_in = 8'h00; alu_op = 3'b110;
        check(8'h54, 1'b1, 1'b0, "SHL_ALT");

        // Test: SHL 0x55 (01010101)
        a_in = 8'h55; b_in = 8'h00; alu_op = 3'b110;
        check(8'hAA, 1'b0, 1'b0, "SHL_55 ");

        // Test: SHL 0x40 -> should not produce carry
        a_in = 8'h40; b_in = 8'h00; alu_op = 3'b110;
        check(8'h80, 1'b0, 1'b0, "SHL_40 ");

        // ============================================================
        // SHR (alu_op = 3'b111)
        // ============================================================
        $display("\n--- SHR Tests (alu_op=111) ---");

        // Test: SHR basic (no carry out)
        a_in = 8'h02; b_in = 8'h00; alu_op = 3'b111;
        check(8'h01, 1'b0, 1'b0, "SHR_BAS");

        // Test: SHR with carry out (LSB was 1)
        a_in = 8'h01; b_in = 8'h00; alu_op = 3'b111;
        check(8'h00, 1'b1, 1'b1, "SHR_LSB");

        // Test: SHR all ones
        a_in = 8'hFF; b_in = 8'h00; alu_op = 3'b111;
        check(8'h7F, 1'b1, 1'b0, "SHR_ALL");

        // Test: SHR zero
        a_in = 8'h00; b_in = 8'h00; alu_op = 3'b111;
        check(8'h00, 1'b0, 1'b1, "SHR_ZRO");

        // Test: SHR 0x80 (MSB only)
        a_in = 8'h80; b_in = 8'h00; alu_op = 3'b111;
        check(8'h40, 1'b0, 1'b0, "SHR_80 ");

        // Test: SHR alternating
        a_in = 8'hAA; b_in = 8'h00; alu_op = 3'b111;
        check(8'h55, 1'b0, 1'b0, "SHR_ALT");

        // ============================================================
        $display("\n========================================");
        $display("  ALU Tests Complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("========================================");
        $finish;
    end

endmodule