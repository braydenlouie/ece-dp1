module tb_control_unit;

    reg        clk;
    reg        rst_n;
    reg  [3:0] opcode;
    reg        z_flag;
    reg        c_flag;
    wire       ir_load;
    wire       pc_inc;
    wire       pc_load;
    wire       acc_load;
    wire [1:0] acc_src;
    wire       rf_write;
    wire [2:0] alu_op;
    wire       flags_load;
    wire       out_load;
    wire       phase;

    control_unit uut (
        .clk        (clk),
        .rst_n      (rst_n),
        .opcode     (opcode),
        .z_flag     (z_flag),
        .c_flag     (c_flag),
        .ir_load    (ir_load),
        .pc_inc     (pc_inc),
        .pc_load    (pc_load),
        .acc_load   (acc_load),
        .acc_src    (acc_src),
        .rf_write   (rf_write),
        .alu_op     (alu_op),
        .flags_load (flags_load),
        .out_load   (out_load),
        .phase      (phase)
    );

    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    // Task: wait for the next fetch phase (phase==0) to be observable
    // We sample at negedge to see stable registered outputs
    task wait_for_fetch;
    begin
        // Wait until we observe phase==0 at a negedge
        @(negedge clk);
        while (phase !== 1'b0) @(negedge clk);
    end
    endtask

    // Task: wait for the next execute phase (phase==1) to be observable
    task wait_for_exec;
    begin
        @(negedge clk);
        while (phase !== 1'b1) @(negedge clk);
    end
    endtask

    task check_fetch;
        input [63:0] test_name;
    begin
        test_num = test_num + 1;
        wait_for_fetch;
        if (ir_load !== 1'b1 || pc_inc !== 1'b1) begin
            $display("FAIL Test %0d [%s]: fetch signals wrong ir_load=%b pc_inc=%b",
                     test_num, test_name, ir_load, pc_inc);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS Test %0d [%s]: fetch phase correct (ir_load=%b pc_inc=%b)",
                     test_num, test_name, ir_load, pc_inc);
            pass_count = pass_count + 1;
        end
    end
    endtask

    task check_exec;
        input       exp_acc_load;
        input [1:0] exp_acc_src;
        input       exp_rf_write;
        input [2:0] exp_alu_op;
        input       exp_flags_load;
        input       exp_pc_load;
        input       exp_out_load;
        input [63:0] test_name;
    begin
        test_num = test_num + 1;
        wait_for_exec;
        if (acc_load !== exp_acc_load || acc_src !== exp_acc_src ||
            rf_write !== exp_rf_write || alu_op !== exp_alu_op ||
            flags_load !== exp_flags_load || pc_load !== exp_pc_load ||
            out_load !== exp_out_load) begin
            $display("FAIL Test %0d [%s]:", test_num, test_name);
            $display("  Got:  acc_load=%b acc_src=%b rf_write=%b alu_op=%b flags_load=%b pc_load=%b out_load=%b",
                     acc_load, acc_src, rf_write, alu_op, flags_load, pc_load, out_load);
            $display("  Exp:  acc_load=%b acc_src=%b rf_write=%b alu_op=%b flags_load=%b pc_load=%b out_load=%b",
                     exp_acc_load, exp_acc_src, exp_rf_write, exp_alu_op, exp_flags_load, exp_pc_load, exp_out_load);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS Test %0d [%s]: exec phase correct", test_num, test_name);
            pass_count = pass_count + 1;
        end
    end
    endtask

    // Helper task: run one full instruction test (fetch then execute)
    // Sets the opcode before the fetch phase and checks both phases
    task test_instruction;
        input [3:0]  test_opcode;
        input        test_z;
        input        test_c;
        input        exp_acc_load;
        input [1:0]  exp_acc_src;
        input        exp_rf_write;
        input [2:0]  exp_alu_op;
        input        exp_flags_load;
        input        exp_pc_load;
        input        exp_out_load;
        input [127:0] test_name;
    begin
        // Set up inputs - opcode is read during execute phase after IR loads it
        // But in this standalone test, opcode is directly driven
        opcode = test_opcode;
        z_flag = test_z;
        c_flag = test_c;

        // Check fetch phase
        check_fetch(test_name);

        // Check execute phase
        check_exec(exp_acc_load, exp_acc_src, exp_rf_write, exp_alu_op,
                   exp_flags_load, exp_pc_load, exp_out_load, test_name);
    end
    endtask

    initial begin
        $display("========================================");
        $display("    Control Unit Testbench Starting");
        $display("========================================");

        clk    = 0;
        rst_n  = 0;
        opcode = 4'h0;
        z_flag = 0;
        c_flag = 0;

        // Hold reset for a few cycles
        repeat (3) @(posedge clk);

        // Release reset
        @(negedge clk);
        rst_n = 1;

        // After reset release, the control unit will start cycling
        // through fetch (phase=0) and execute (phase=1)
        // The wait_for_fetch/wait_for_exec tasks will synchronize us

        $display("\n--- Testing each instruction ---");
        $display("(Each test checks fetch phase then execute phase)\n");

        // ====== INA (0x0): ACC <- in_port ======
        // acc_src=11 (input port), acc_load=1, flags_load=1
        $display("--- INA (0x0) ---");
        test_instruction(
            4'h0, 1'b0, 1'b0,          // opcode, z, c
            1'b1, 2'b11, 1'b0, 3'b000, // acc_load, acc_src, rf_write, alu_op
            1'b1, 1'b0, 1'b0,          // flags_load, pc_load, out_load
            "INA    "
        );

        // ====== LDA (0x1): ACC <- R[n] ======
        // acc_src=01 (register), acc_load=1, flags_load=1
        $display("\n--- LDA (0x1) ---");
        test_instruction(
            4'h1, 1'b0, 1'b0,
            1'b1, 2'b01, 1'b0, 3'b000,
            1'b1, 1'b0, 1'b0,
            "LDA    "
        );

        // ====== STA (0x2): R[n] <- ACC ======
        // rf_write=1, everything else inactive
        $display("\n--- STA (0x2) ---");
        test_instruction(
            4'h2, 1'b0, 1'b0,
            1'b0, 2'b00, 1'b1, 3'b000,
            1'b0, 1'b0, 1'b0,
            "STA    "
        );

        // ====== LDI (0x3): ACC <- immediate ======
        // acc_src=10 (immediate), acc_load=1, flags_load=1
        $display("\n--- LDI (0x3) ---");
        test_instruction(
            4'h3, 1'b0, 1'b0,
            1'b1, 2'b10, 1'b0, 3'b000,
            1'b1, 1'b0, 1'b0,
            "LDI    "
        );

        // ====== ADD (0x4): ACC <- ACC + R[n] ======
        // acc_src=00 (ALU), acc_load=1, alu_op=000, flags_load=1
        $display("\n--- ADD (0x4) ---");
        test_instruction(
            4'h4, 1'b0, 1'b0,
            1'b1, 2'b00, 1'b0, 3'b000,
            1'b1, 1'b0, 1'b0,
            "ADD    "
        );

        // ====== SUB (0x5): ACC <- ACC - R[n] ======
        // alu_op=001
        $display("\n--- SUB (0x5) ---");
        test_instruction(
            4'h5, 1'b0, 1'b0,
            1'b1, 2'b00, 1'b0, 3'b001,
            1'b1, 1'b0, 1'b0,
            "SUB    "
        );

        // ====== AND (0x6) ======
        // alu_op=010
        $display("\n--- AND (0x6) ---");
        test_instruction(
            4'h6, 1'b0, 1'b0,
            1'b1, 2'b00, 1'b0, 3'b010,
            1'b1, 1'b0, 1'b0,
            "AND    "
        );

        // ====== OR (0x7) ======
        // alu_op=011
        $display("\n--- OR (0x7) ---");
        test_instruction(
            4'h7, 1'b0, 1'b0,
            1'b1, 2'b00, 1'b0, 3'b011,
            1'b1, 1'b0, 1'b0,
            "OR     "
        );

        // ====== XOR (0x8) ======
        // alu_op=100
        $display("\n--- XOR (0x8) ---");
        test_instruction(
            4'h8, 1'b0, 1'b0,
            1'b1, 2'b00, 1'b0, 3'b100,
            1'b1, 1'b0, 1'b0,
            "XOR    "
        );

        // ====== NOT (0x9) ======
        // alu_op=101
        $display("\n--- NOT (0x9) ---");
        test_instruction(
            4'h9, 1'b0, 1'b0,
            1'b1, 2'b00, 1'b0, 3'b101,
            1'b1, 1'b0, 1'b0,
            "NOT    "
        );

        // ====== SHL (0xA) ======
        // alu_op=110
        $display("\n--- SHL (0xA) ---");
        test_instruction(
            4'hA, 1'b0, 1'b0,
            1'b1, 2'b00, 1'b0, 3'b110,
            1'b1, 1'b0, 1'b0,
            "SHL    "
        );

        // ====== SHR (0xB) ======
        // alu_op=111
        $display("\n--- SHR (0xB) ---");
        test_instruction(
            4'hB, 1'b0, 1'b0,
            1'b1, 2'b00, 1'b0, 3'b111,
            1'b1, 1'b0, 1'b0,
            "SHR    "
        );

        // ====== JMP (0xC): unconditional jump ======
        // pc_load=1, nothing else
        $display("\n--- JMP (0xC) ---");
        test_instruction(
            4'hC, 1'b0, 1'b0,
            1'b0, 2'b00, 1'b0, 3'b000,
            1'b0, 1'b1, 1'b0,
            "JMP    "
        );

        // ====== JZ (0xD): jump if zero ======
        // JZ not taken (z_flag=0)
        $display("\n--- JZ not taken (z=0) ---");
        test_instruction(
            4'hD, 1'b0, 1'b0,
            1'b0, 2'b00, 1'b0, 3'b000,
            1'b0, 1'b0, 1'b0,
            "JZ_NT  "
        );

        // JZ taken (z_flag=1)
        $display("\n--- JZ taken (z=1) ---");
        test_instruction(
            4'hD, 1'b1, 1'b0,
            1'b0, 2'b00, 1'b0, 3'b000,
            1'b0, 1'b1, 1'b0,
            "JZ_TK  "
        );

        // ====== JC (0xE): jump if carry ======
        // JC not taken (c_flag=0)
        $display("\n--- JC not taken (c=0) ---");
        test_instruction(
            4'hE, 1'b0, 1'b0,
            1'b0, 2'b00, 1'b0, 3'b000,
            1'b0, 1'b0, 1'b0,
            "JC_NT  "
        );

        // JC taken (c_flag=1)
        $display("\n--- JC taken (c=1) ---");
        test_instruction(
            4'hE, 1'b0, 1'b1,
            1'b0, 2'b00, 1'b0, 3'b000,
            1'b0, 1'b1, 1'b0,
            "JC_TK  "
        );

        // ====== OUTA (0xF): OUT <- ACC ======
        // out_load=1
        $display("\n--- OUTA (0xF) ---");
        test_instruction(
            4'hF, 1'b0, 1'b0,
            1'b0, 2'b00, 1'b0, 3'b000,
            1'b0, 1'b0, 1'b1,
            "OUTA   "
        );

        $display("\n========================================");
        $display("  CTRL Tests Complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("*** ALL CONTROL UNIT TESTS PASSED ***");
        else
            $display("*** SOME TESTS FAILED - check signal expectations vs RTL ***");

        $finish;
    end

    // Timeout
    initial begin
        #50000;
        $display("TIMEOUT: Control unit testbench exceeded time limit");
        $finish;
    end

endmodule