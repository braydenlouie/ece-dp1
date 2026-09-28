`timescale 1ns / 1ps

module tb_microprocessor;

    reg        clk;
    reg        rst_n;
    wire [7:0] rom_addr;
    reg  [7:0] rom_data;
    reg  [7:0] in_port;
    wire [7:0] out_port;
    wire       out_valid;

    microprocessor uut (
        .clk      (clk),
        .rst_n    (rst_n),
        .rom_addr (rom_addr),
        .rom_data (rom_data),
        .in_port  (in_port),
        .out_port (out_port),
        .out_valid(out_valid)
    );

    always #5 clk = ~clk;

    // ============================================================
    // ROM: 256 bytes
    // Each instruction is 1 byte: [7:4]=opcode, [3:0]=operand
    //
    // Opcode encoding:
    //   0x0n = INA        (ACC <- in_port)
    //   0x1n = LDA Rn     (ACC <- R[n])
    //   0x2n = STA Rn     (R[n] <- ACC)
    //   0x3n = LDI #n     (ACC <- {0000, n})
    //   0x4n = ADD Rn     (ACC <- ACC + R[n])
    //   0x5n = SUB Rn     (ACC <- ACC - R[n])
    //   0x6n = AND Rn     (ACC <- ACC & R[n])
    //   0x7n = OR  Rn     (ACC <- ACC | R[n])
    //   0x8n = XOR Rn     (ACC <- ACC ^ R[n])
    //   0x9n = NOT        (ACC <- ~ACC)
    //   0xAn = SHL        (ACC <- ACC << 1)
    //   0xBn = SHR        (ACC <- ACC >> 1)
    //   0xCn = JMP addr   (PC <- {PC[7:4], n})
    //   0xDn = JZ  addr   (if Z: PC <- {PC[7:4], n})
    //   0xEn = JC  addr   (if C: PC <- {PC[7:4], n})
    //   0xFn = OUTA       (OUT <- ACC)
    // ============================================================

    reg [7:0] rom [0:255];

    // ROM read - combinational
    always @(*) begin
        rom_data = rom[rom_addr];
    end

    // ============================================================
    // Test Program
    // ============================================================
    //
    // The program is divided into test sections. Each section tests
    // specific instructions and outputs results via OUTA.
    // Expected outputs are checked by the testbench monitor.
    //
    // Register usage convention: R0-R7 (addressed by lower 3 bits)
    // Note: operand is 4 bits, but only lower 3 are used for register addressing
    // ============================================================

    integer i;
    integer output_count;
    reg [7:0] expected_outputs [0:63];
    integer num_expected;
    integer pass_count;
    integer fail_count;

    initial begin
        // Clear ROM
        for (i = 0; i < 256; i = i + 1)
            rom[i] = 8'hC0; // default: JMP 0 (safe infinite loop in each page)

        // ============================================================
        // SECTION 1: LDI + OUTA (addresses 0x00 - 0x0F)
        // Tests: LDI with values 0-15, OUTA
        // ============================================================
        //
        // Test 1: LDI #5, OUTA -> expect output 0x05
        rom[8'h00] = 8'h35;  // LDI #5       ACC = 0x05
        rom[8'h01] = 8'hF0;  // OUTA         OUT = 0x05    ** Output 0: 0x05 **

        // Test 2: LDI #0, OUTA -> expect output 0x00 (zero edge case)
        rom[8'h02] = 8'h30;  // LDI #0       ACC = 0x00
        rom[8'h03] = 8'hF0;  // OUTA         OUT = 0x00    ** Output 1: 0x00 **

        // Test 3: LDI #15 (max immediate), OUTA -> expect output 0x0F
        rom[8'h04] = 8'h3F;  // LDI #15      ACC = 0x0F
        rom[8'h05] = 8'hF0;  // OUTA         OUT = 0x0F    ** Output 2: 0x0F **

        // ============================================================
        // SECTION 2: STA + LDA (addresses 0x06 - 0x0B)
        // Tests: Store to register, load back
        // ============================================================
        //
        // Test 4: LDI #7, STA R0, LDI #0, LDA R0, OUTA -> expect 0x07
        rom[8'h06] = 8'h37;  // LDI #7       ACC = 0x07
        rom[8'h07] = 8'h20;  // STA R0       R0 = 0x07
        rom[8'h08] = 8'h30;  // LDI #0       ACC = 0x00 (clear ACC)
        rom[8'h09] = 8'h10;  // LDA R0       ACC = 0x07 (load from R0)
        rom[8'h0A] = 8'hF0;  // OUTA         OUT = 0x07    ** Output 3: 0x07 **

        // Test 5: Store to R7 (highest register)
        rom[8'h0B] = 8'h3A;  // LDI #10      ACC = 0x0A
        rom[8'h0C] = 8'h27;  // STA R7       R7 = 0x0A
        rom[8'h0D] = 8'h30;  // LDI #0       ACC = 0x00
        rom[8'h0E] = 8'h17;  // LDA R7       ACC = 0x0A
        rom[8'h0F] = 8'hF0;  // OUTA         OUT = 0x0A    ** Output 4: 0x0A **

        // ============================================================
        // SECTION 3: ADD (addresses 0x10 - 0x1F)
        // Jump to page 1
        // ============================================================
        // Need to jump to 0x10. From 0x10, we're in page 1 (PC[7:4]=0001)
        // Actually after OUTA at 0x0F, PC increments to 0x10 naturally.

        // Test 6: ADD basic: 3 + 5 = 8
        rom[8'h10] = 8'h33;  // LDI #3       ACC = 0x03
        rom[8'h11] = 8'h20;  // STA R0       R0 = 0x03
        rom[8'h12] = 8'h35;  // LDI #5       ACC = 0x05
        rom[8'h13] = 8'h21;  // STA R1       R1 = 0x05
        rom[8'h14] = 8'h10;  // LDA R0       ACC = 0x03
        rom[8'h15] = 8'h41;  // ADD R1       ACC = 0x03 + 0x05 = 0x08
        rom[8'h16] = 8'hF0;  // OUTA         OUT = 0x08    ** Output 5: 0x08 **

        // Test 7: ADD with carry (overflow): Build 0xFF + 0x01
        // First build 0xFF using shifts: LDI #15 (0x0F), SHL x4 gives 0xF0, OR 0x0F
        rom[8'h17] = 8'h3F;  // LDI #15      ACC = 0x0F
        rom[8'h18] = 8'hA0;  // SHL          ACC = 0x1E
        rom[8'h19] = 8'hA0;  // SHL          ACC = 0x3C
        rom[8'h1A] = 8'hA0;  // SHL          ACC = 0x78
        rom[8'h1B] = 8'hA0;  // SHL          ACC = 0xF0
        rom[8'h1C] = 8'h22;  // STA R2       R2 = 0xF0
        rom[8'h1D] = 8'h3F;  // LDI #15      ACC = 0x0F
        rom[8'h1E] = 8'h72;  // OR R2        ACC = 0x0F | 0xF0 = 0xFF
        rom[8'h1F] = 8'h22;  // STA R2       R2 = 0xFF

        // Continue on page 2
        // At 0x1F+1 = 0x20 (naturally flows to page 2)

        // ============================================================
        // SECTION 3 continued + SECTION 4 (addresses 0x20 - 0x2F)
        // ============================================================

        // Test 7 continued: 0xFF + 0x01 = 0x00 with carry
        rom[8'h20] = 8'h31;  // LDI #1       ACC = 0x01
        rom[8'h21] = 8'h23;  // STA R3       R3 = 0x01
        rom[8'h22] = 8'h12;  // LDA R2       ACC = 0xFF
        rom[8'h23] = 8'h43;  // ADD R3       ACC = 0xFF + 0x01 = 0x00, C=1, Z=1
        rom[8'h24] = 8'hF0;  // OUTA         OUT = 0x00    ** Output 6: 0x00 **

        // Test 8: JC - carry should be set from previous ADD
        // JC to addr 0x27 (skip next 2 instructions)
        rom[8'h25] = 8'hE7;  // JC 0x27      C=1, so jump to 0x27
        rom[8'h26] = 8'h3F;  // LDI #15      (SHOULD BE SKIPPED)
        // At 0x27:
        rom[8'h27] = 8'h31;  // LDI #1       ACC = 0x01 (proves we jumped)
        rom[8'h28] = 8'hF0;  // OUTA         OUT = 0x01    ** Output 7: 0x01 **

        // Test 9: SUB basic: 8 - 3 = 5
        rom[8'h29] = 8'h38;  // LDI #8       ACC = 0x08
        rom[8'h2A] = 8'h50;  // SUB R0       ACC = 0x08 - 0x03 = 0x05, C=0
        rom[8'h2B] = 8'hF0;  // OUTA         OUT = 0x05    ** Output 8: 0x05 **

        // Test 10: SUB equal values -> zero, Z=1
        rom[8'h2C] = 8'h33;  // LDI #3       ACC = 0x03
        rom[8'h2D] = 8'h50;  // SUB R0       ACC = 0x03 - 0x03 = 0x00, Z=1
        rom[8'h2E] = 8'hF0;  // OUTA         OUT = 0x00    ** Output 9: 0x00 **

        // Test 11: JZ - Z should be set from previous SUB
        rom[8'h2F] = 8'hD1;  // JZ 0x21      Z=1, jump to 0x21 (page 2: addr=0x21)

        // Wait—0x21 is in page 2, PC[7:4]=0x2, so jump target = {0x2, 0x1} = 0x21
        // But 0x21 is STA R3... that's fine for now, let's redirect

        // Actually let me reorganize. JZ target should be on same page.
        // At 0x2F, PC[7:4]=0x2, so jump to {0x2, operand} = 0x2n
        // Let's jump to 0x2F+2 which doesn't exist yet. Let me re-layout.

        // Revised: at 0x2F, JZ to skip one instruction:
        // Page boundary concern: 0x2F is the last address on page 2 nibble.
        // Actually PC[7:4] after fetch of 0x2F: PC was 0x2F during fetch, 
        // then PC incremented to 0x30. So PC[7:4]=0x3 when jump executes.
        // Jump target = {0x3, operand}. This is page 3!
        
        // Let me place the jump target at page 3:
        rom[8'h2F] = 8'hD2;  // JZ 0x2 -> target = {0x3, 0x2} = 0x32
        // If Z=1: skip to 0x32
        rom[8'h30] = 8'h3E;  // LDI #14      (SHOULD BE SKIPPED if Z=1)
        rom[8'h31] = 8'hF0;  // OUTA         (SHOULD BE SKIPPED if Z=1)

        rom[8'h32] = 8'h31;  // LDI #1       ACC = 0x01 (proves JZ worked)
        rom[8'h33] = 8'hF0;  // OUTA         OUT = 0x01    ** Output 10: 0x01 **

        // Test 12: JZ not taken (Z=0)
        rom[8'h34] = 8'h35;  // LDI #5       ACC = 0x05, Z=0
        rom[8'h35] = 8'hD8;  // JZ 0x8       Z=0, so NO jump; target would be {0x3,0x8}=0x38
        rom[8'h36] = 8'h32;  // LDI #2       ACC = 0x02 (should execute, JZ not taken)
        rom[8'h37] = 8'hF0;  // OUTA         OUT = 0x02    ** Output 11: 0x02 **

        // Test 13: JC not taken (C=0)
        // After LDI, carry flag should be preserved from last ALU op... 
        // Actually LDI sets flags: ACC=0x02, Z=0, C preserved (c_in = c_flag for non-ALU)
        // The last ALU operation that set carry: SUB at 0x2D set C=0 (3-3=0, no borrow)
        // Hmm, actually need to be careful. Let's explicitly create a C=0 condition:
        rom[8'h38] = 8'h31;  // LDI #1       ACC = 0x01
        rom[8'h39] = 8'h24;  // STA R4       R4 = 0x01
        rom[8'h3A] = 8'h32;  // LDI #2       ACC = 0x02
        rom[8'h3B] = 8'h54;  // SUB R4       ACC = 0x02 - 0x01 = 0x01, C=0, Z=0
        rom[8'h3C] = 8'hEF;  // JC 0xF       C=0, no jump; target={0x3,0xF}=0x3F
        rom[8'h3D] = 8'h33;  // LDI #3       ACC = 0x03 (should execute, JC not taken)
        rom[8'h3E] = 8'hF0;  // OUTA         OUT = 0x03    ** Output 12: 0x03 **

        // JMP to page 4 for more tests
        rom[8'h3F] = 8'hC0;  // JMP 0x0 -> target = {0x4, 0x0} = 0x40

        // ============================================================
        // SECTION 5: AND, OR, XOR, NOT (addresses 0x40 - 0x5F)
        // ============================================================

        // Test 14: AND - masking
        // 0xFF AND 0x0F = 0x0F
        rom[8'h40] = 8'h3F;  // LDI #15      ACC = 0x0F
        rom[8'h41] = 8'h25;  // STA R5       R5 = 0x0F
        rom[8'h42] = 8'h12;  // LDA R2       ACC = 0xFF (R2 was set to 0xFF earlier)
        rom[8'h43] = 8'h65;  // AND R5       ACC = 0xFF & 0x0F = 0x0F
        rom[8'h44] = 8'hF0;  // OUTA         OUT = 0x0F    ** Output 13: 0x0F **

        // Test 15: AND with zero = zero
        rom[8'h45] = 8'h30;  // LDI #0       ACC = 0x00
        rom[8'h46] = 8'h26;  // STA R6       R6 = 0x00
        rom[8'h47] = 8'h3F;  // LDI #15      ACC = 0x0F
        rom[8'h48] = 8'h66;  // AND R6       ACC = 0x0F & 0x00 = 0x00
        rom[8'h49] = 8'hF0;  // OUTA         OUT = 0x00    ** Output 14: 0x00 **

        // Test 16: OR
        // Need 0xA0 in a register. Build it: LDI #10 (0x0A), SHL x4 = 0xA0
        rom[8'h4A] = 8'h3A;  // LDI #10      ACC = 0x0A
        rom[8'h4B] = 8'hA0;  // SHL          ACC = 0x14
        rom[8'h4C] = 8'hA0;  // SHL          ACC = 0x28
        rom[8'h4D] = 8'hA0;  // SHL          ACC = 0x50
        rom[8'h4E] = 8'hA0;  // SHL          ACC = 0xA0
        rom[8'h4F] = 8'h24;  // STA R4       R4 = 0xA0

        // Actually, let me simplify: OR 0x0F with 0xA0
        rom[8'h50] = 8'h3F;  // LDI #15      ACC = 0x0F
        rom[8'h51] = 8'h74;  // OR R4        ACC = 0x0F | 0xA0 = 0xAF
        rom[8'h52] = 8'hF0;  // OUTA         OUT = 0xAF    ** Output 15: 0xAF **

        // Test 17: XOR self = 0
        rom[8'h53] = 8'h3F;  // LDI #15      ACC = 0x0F
        rom[8'h54] = 8'h25;  // STA R5       R5 = 0x0F
        rom[8'h55] = 8'h85;  // XOR R5       ACC = 0x0F ^ 0x0F = 0x00, Z=1
        rom[8'h56] = 8'hF0;  // OUTA         OUT = 0x00    ** Output 16: 0x00 **

        // Test 18: XOR with different value
        rom[8'h57] = 8'h3F;  // LDI #15      ACC = 0x0F
        rom[8'h58] = 8'h84;  // XOR R4       ACC = 0x0F ^ 0xA0 = 0xAF
        rom[8'h59] = 8'hF0;  // OUTA         OUT = 0xAF    ** Output 17: 0xAF **

        // Test 19: NOT
        rom[8'h5A] = 8'h30;  // LDI #0       ACC = 0x00
        rom[8'h5B] = 8'h90;  // NOT          ACC = ~0x00 = 0xFF
        rom[8'h5C] = 8'hF0;  // OUTA         OUT = 0xFF    ** Output 18: 0xFF **

        // Test 20: NOT of 0xFF = 0x00
        rom[8'h5D] = 8'h90;  // NOT          ACC = ~0xFF = 0x00
        rom[8'h5E] = 8'hF0;  // OUTA         OUT = 0x00    ** Output 19: 0x00 **

        // JMP to page 6
        rom[8'h5F] = 8'hC0;  // JMP 0x0 -> {0x6, 0x0} = 0x60

        // ============================================================
        // SECTION 6: SHL, SHR (addresses 0x60 - 0x7F)
        // ============================================================

        // Test 21: SHL basic: 0x01 << 1 = 0x02
        rom[8'h60] = 8'h31;  // LDI #1       ACC = 0x01
        rom[8'h61] = 8'hA0;  // SHL          ACC = 0x02, C=0
        rom[8'h62] = 8'hF0;  // OUTA         OUT = 0x02    ** Output 20: 0x02 **

        // Test 22: SHL with carry: 0x80 << 1 = 0x00, C=1
        // Build 0x80: LDI #8, SHL x4
        rom[8'h63] = 8'h38;  // LDI #8       ACC = 0x08
        rom[8'h64] = 8'hA0;  // SHL          ACC = 0x10
        rom[8'h65] = 8'hA0;  // SHL          ACC = 0x20
        rom[8'h66] = 8'hA0;  // SHL          ACC = 0x40
        rom[8'h67] = 8'hA0;  // SHL          ACC = 0x80, C=0
        rom[8'h68] = 8'hA0;  // SHL          ACC = 0x00, C=1, Z=1
        rom[8'h69] = 8'hF0;  // OUTA         OUT = 0x00    ** Output 21: 0x00 **

        // Test 23: Verify carry was set by using JC
        rom[8'h6A] = 8'hEC;  // JC 0xC -> target = {0x6, 0xC} = 0x6C (wait, PC after fetch 0x6A increments to 0x6B)
        // Actually: PC is at 0x6A during fetch. Fetch increments PC to 0x6B.
        // Execute: PC[7:4]=0x6, operand=0xC. target = {0x6, 0xC} = 0x6C
        rom[8'h6B] = 8'h3E;  // LDI #14      (SHOULD BE SKIPPED - C was 1)
        rom[8'h6C] = 8'h31;  // LDI #1       ACC = 0x01 (proves JC worked)
        rom[8'h6D] = 8'hF0;  // OUTA         OUT = 0x01    ** Output 22: 0x01 **

        // Test 24: SHR basic: 0x04 >> 1 = 0x02
        rom[8'h6E] = 8'h34;  // LDI #4       ACC = 0x04
        rom[8'h6F] = 8'hB0;  // SHR          ACC = 0x02, C=0

        // Page boundary: 0x6F+1 = 0x70, still page 7 when executing
        rom[8'h70] = 8'hF0;  // OUTA         OUT = 0x02    ** Output 23: 0x02 **

        // Test 25: SHR with carry: 0x01 >> 1 = 0x00, C=1
        rom[8'h71] = 8'h31;  // LDI #1       ACC = 0x01
        rom[8'h72] = 8'hB0;  // SHR          ACC = 0x00, C=1, Z=1
        rom[8'h73] = 8'hF0;  // OUTA         OUT = 0x00    ** Output 24: 0x00 **

        // Test 26: Multiple shifts to multiply: 0x03 << 3 = 0x18
        rom[8'h74] = 8'h33;  // LDI #3       ACC = 0x03
        rom[8'h75] = 8'hA0;  // SHL          ACC = 0x06
        rom[8'h76] = 8'hA0;  // SHL          ACC = 0x0C
        rom[8'h77] = 8'hA0;  // SHL          ACC = 0x18
        rom[8'h78] = 8'hF0;  // OUTA         OUT = 0x18    ** Output 25: 0x18 **

        // ============================================================
        // SECTION 7: INA (addresses 0x79 - 0x7F)
        // ============================================================

        // Test 27: INA - read from input port
        // in_port will be set by testbench
        rom[8'h79] = 8'h00;  // INA          ACC = in_port (testbench sets to 0xAB)
        rom[8'h7A] = 8'hF0;  // OUTA         OUT = 0xAB    ** Output 26: 0xAB **

        // Test 28: INA with 0x00
        rom[8'h7B] = 8'h00;  // INA          ACC = in_port (testbench sets to 0x00)
        rom[8'h7C] = 8'hF0;  // OUTA         OUT = 0x00    ** Output 27: 0x00 **

        // Test 29: INA with 0xFF
        rom[8'h7D] = 8'h00;  // INA          ACC = in_port (testbench sets to 0xFF)
        rom[8'h7E] = 8'hF0;  // OUTA         OUT = 0xFF    ** Output 28: 0xFF **

        // JMP to page 8 for JMP test
        rom[8'h7F] = 8'hC0;  // JMP 0x0 -> {0x8, 0x0} = 0x80

        // ============================================================
        // SECTION 8: JMP tests (addresses 0x80 - 0x8F)
        // ============================================================

        // Test 30: JMP unconditional
        rom[8'h80] = 8'hC4;  // JMP 0x4 -> target = {0x8, 0x4} = 0x84
        rom[8'h81] = 8'h3E;  // LDI #14      (SKIPPED)
        rom[8'h82] = 8'hF0;  // OUTA         (SKIPPED)
        rom[8'h83] = 8'hF0;  // OUTA         (SKIPPED)
        rom[8'h84] = 8'h34;  // LDI #4       ACC = 0x04 (proves JMP worked)
        rom[8'h85] = 8'hF0;  // OUTA         OUT = 0x04    ** Output 29: 0x04 **

        // Test 31: JMP backward on same page
        // Set up: output a value, jump back would create loop
        // Instead, test forward JMP to completion marker
        rom[8'h86] = 8'h39;  // LDI #9       ACC = 0x09
        rom[8'h87] = 8'hF0;  // OUTA         OUT = 0x09    ** Output 30: 0x09 **

        // ============================================================
        // SECTION 9: SUB underflow edge case (addresses 0x88 - 0x8F)
        // ============================================================

        // Test 32: SUB underflow: 0 - 1 = 0xFF with borrow
        rom[8'h88] = 8'h31;  // LDI #1       ACC = 0x01
        rom[8'h89] = 8'h20;  // STA R0       R0 = 0x01
        rom[8'h8A] = 8'h30;  // LDI #0       ACC = 0x00
        rom[8'h8B] = 8'h50;  // SUB R0       ACC = 0x00 - 0x01 = 0xFF, C=1 (borrow)
        rom[8'h8C] = 8'hF0;  // OUTA         OUT = 0xFF    ** Output 31: 0xFF **

        // Test 33: Verify borrow (carry) set with JC
        rom[8'h8D] = 8'hEF;  // JC 0xF -> target = {0x8, 0xF} = 0x8F
        rom[8'h8E] = 8'h3E;  // LDI #14      (SKIPPED - C=1)
        rom[8'h8F] = 8'h31;  // LDI #1       ACC = 0x01 (proves borrow/JC)
        rom[8'h90] = 8'hF0;  // OUTA         OUT = 0x01    ** Output 32: 0x01 **

        // ============================================================
        // SECTION 10: Chained operations & complex test (0x91 - 0x9F)
        // ============================================================

        // Test 34: Build 0xA5 using shifts and OR, then NOT, then AND
        // 0xA5 = 10100101
        // Strategy: build 0xA0, OR with 0x05
        rom[8'h91] = 8'h3A;  // LDI #10      ACC = 0x0A
        rom[8'h92] = 8'hA0;  // SHL          ACC = 0x14
        rom[8'h93] = 8'hA0;  // SHL          ACC = 0x28
        rom[8'h94] = 8'hA0;  // SHL          ACC = 0x50
        rom[8'h95] = 8'hA0;  // SHL          ACC = 0xA0
        rom[8'h96] = 8'h20;  // STA R0       R0 = 0xA0
        rom[8'h97] = 8'h35;  // LDI #5       ACC = 0x05
        rom[8'h98] = 8'h70;  // OR R0        ACC = 0x05 | 0xA0 = 0xA5
        rom[8'h99] = 8'hF0;  // OUTA         OUT = 0xA5    ** Output 33: 0xA5 **

        // Test 35: NOT of 0xA5 = 0x5A
        rom[8'h9A] = 8'h90;  // NOT          ACC = ~0xA5 = 0x5A
        rom[8'h9B] = 8'hF0;  // OUTA         OUT = 0x5A    ** Output 34: 0x5A **

        // Test 36: AND with 0x0F (mask lower nibble) = 0x0A
        rom[8'h9C] = 8'h3F;  // LDI #15      ACC = 0x0F
        rom[8'h9D] = 8'h21;  // STA R1       R1 = 0x0F
        rom[8'h9E] = 8'h35;  // LDI #5       Reload... wait, we need 0x5A

        // Hmm, ACC was changed by LDI. Let me fix:
        // After NOT at 0x9A, ACC = 0x5A. Store it.
        // Re-do:
        rom[8'h9A] = 8'h90;  // NOT          ACC = ~0xA5 = 0x5A
        rom[8'h9B] = 8'h21;  // STA R1       R1 = 0x5A
        rom[8'h9C] = 8'hF0;  // OUTA         OUT = 0x5A    ** Output 34: 0x5A **
        rom[8'h9D] = 8'h3F;  // LDI #15      ACC = 0x0F
        rom[8'h9E] = 8'h22;  // STA R2       R2 = 0x0F
        rom[8'h9F] = 8'h11;  // LDA R1       ACC = 0x5A

        // Continue on page A
        rom[8'hA0] = 8'h62;  // AND R2       ACC = 0x5A & 0x0F = 0x0A
        rom[8'hA1] = 8'hF0;  // OUTA         OUT = 0x0A    ** Output 35: 0x0A **

        // ============================================================
        // SECTION 11: Loop test - count down from 3 to 0 (0xA2 - 0xAF)
        // Tests: JZ with loop, SUB in loop
        // ============================================================

        // R0 = counter (start at 3)
        // R1 = decrement value (1)
        rom[8'hA2] = 8'h31;  // LDI #1       ACC = 0x01
        rom[8'hA3] = 8'h21;  // STA R1       R1 = 0x01
        rom[8'hA4] = 8'h33;  // LDI #3       ACC = 0x03
        // Loop start at 0xA5:
        rom[8'hA5] = 8'hF0;  // OUTA         Output current ACC value
        rom[8'hA6] = 8'h51;  // SUB R1       ACC = ACC - 1
        rom[8'hA7] = 8'hDA;  // JZ 0xA -> target = {0xA, 0xA} = 0xAA (exit loop when zero)
        rom[8'hA8] = 8'hC5;  // JMP 0x5 -> target = {0xA, 0x5} = 0xA5 (loop back)
        rom[8'hA9] = 8'h30;  // (never reached)

        // Loop outputs:
        // Iteration 1: ACC=3, output 3, sub -> ACC=2, Z=0, loop  ** Output 36: 0x03 **
        // Iteration 2: ACC=2, output 2, sub -> ACC=1, Z=0, loop  ** Output 37: 0x02 **
        // Iteration 3: ACC=1, output 1, sub -> ACC=0, Z=1, exit  ** Output 38: 0x01 **

        // Exit point:
        rom[8'hAA] = 8'hF0;  // OUTA         OUT = 0x00    ** Output 39: 0x00 **

        // ============================================================
        // SECTION 12: Register isolation test (0xAB - 0xBF)
        // Store different values in all 8 registers, read them all back
        // ============================================================
        rom[8'hAB] = 8'h31;  // LDI #1       ACC = 0x01
        rom[8'hAC] = 8'h20;  // STA R0       R0 = 0x01
        rom[8'hAD] = 8'h32;  // LDI #2       ACC = 0x02
        rom[8'hAE] = 8'h21;  // STA R1       R1 = 0x02
        rom[8'hAF] = 8'h33;  // LDI #3       ACC = 0x03

        rom[8'hB0] = 8'h22;  // STA R2       R2 = 0x03
        rom[8'hB1] = 8'h34;  // LDI #4       ACC = 0x04
        rom[8'hB2] = 8'h23;  // STA R3       R3 = 0x04
        rom[8'hB3] = 8'h35;  // LDI #5       ACC = 0x05
        rom[8'hB4] = 8'h24;  // STA R4       R4 = 0x05
        rom[8'hB5] = 8'h36;  // LDI #5       ACC = 0x06
        rom[8'hB6] = 8'h25;  // STA R5       R5 = 0x06
        rom[8'hB7] = 8'h37;  // LDI #7       ACC = 0x07
        rom[8'hB8] = 8'h26;  // STA R6       R6 = 0x07
        rom[8'hB9] = 8'h38;  // LDI #8       ACC = 0x08
        rom[8'hBA] = 8'h27;  // STA R7       R7 = 0x08

        // Now read them all back and output
        rom[8'hBB] = 8'h10;  // LDA R0       ACC = 0x01
        rom[8'hBC] = 8'hF0;  // OUTA         OUT = 0x01    ** Output 40: 0x01 **
        rom[8'hBD] = 8'h11;  // LDA R1       ACC = 0x02
        rom[8'hBE] = 8'hF0;  // OUTA         OUT = 0x02    ** Output 41: 0x02 **
        rom[8'hBF] = 8'h12;  // LDA R2       ACC = 0x03

        rom[8'hC0] = 8'hF0;  // OUTA         OUT = 0x03    ** Output 42: 0x03 **
        rom[8'hC1] = 8'h13;  // LDA R3       ACC = 0x04
        rom[8'hC2] = 8'hF0;  // OUTA         OUT = 0x04    ** Output 43: 0x04 **
        rom[8'hC3] = 8'h14;  // LDA R4       ACC = 0x05
        rom[8'hC4] = 8'hF0;  // OUTA         OUT = 0x05    ** Output 44: 0x05 **
        rom[8'hC5] = 8'h15;  // LDA R5       ACC = 0x06
        rom[8'hC6] = 8'hF0;  // OUTA         OUT = 0x06    ** Output 45: 0x06 **
        rom[8'hC7] = 8'h16;  // LDA R6       ACC = 0x07
        rom[8'hC8] = 8'hF0;  // OUTA         OUT = 0x07    ** Output 46: 0x07 **
        rom[8'hC9] = 8'h17;  // LDA R7       ACC = 0x08
        rom[8'hCA] = 8'hF0;  // OUTA         OUT = 0x08    ** Output 47: 0x08 **

        // ============================================================
        // SECTION 13: ADD chain to build large number (0xCB - 0xDF)
        // 15 + 15 + 15 + 15 = 60 (0x3C)
        // ============================================================
        rom[8'hCB] = 8'h3F;  // LDI #15      ACC = 0x0F
        rom[8'hCC] = 8'h20;  // STA R0       R0 = 0x0F
        rom[8'hCD] = 8'h40;  // ADD R0       ACC = 0x0F + 0x0F = 0x1E
        rom[8'hCE] = 8'h40;  // ADD R0       ACC = 0x1E + 0x0F = 0x2D
        rom[8'hCF] = 8'h40;  // ADD R0       ACC = 0x2D + 0x0F = 0x3C

        rom[8'hD0] = 8'hF0;  // OUTA         OUT = 0x3C    ** Output 48: 0x3C **

        // ============================================================
        // SECTION 14: XOR-based swap test
        // Swap R0 and R1 using XOR
        // R0 = 0x0F (from above), need to set R1
        // ============================================================
        rom[8'hD1] = 8'h35;  // LDI #5       ACC = 0x05
        rom[8'hD2] = 8'h21;  // STA R1       R1 = 0x05, R0 = 0x0F
        // XOR swap: R0 ^= R1, R1 ^= R0, R0 ^= R1
        rom[8'hD3] = 8'h10;  // LDA R0       ACC = 0x0F
        rom[8'hD4] = 8'h81;  // XOR R1       ACC = 0x0F ^ 0x05 = 0x0A
        rom[8'hD5] = 8'h20;  // STA R0       R0 = 0x0A
        rom[8'hD6] = 8'h11;  // LDA R1       ACC = 0x05
        rom[8'hD7] = 8'h80;  // XOR R0       ACC = 0x05 ^ 0x0A = 0x0F
        rom[8'hD8] = 8'h21;  // STA R1       R1 = 0x0F
        rom[8'hD9] = 8'h10;  // LDA R0       ACC = 0x0A
        rom[8'hDA] = 8'h81;  // XOR R1       ACC = 0x0A ^ 0x0F = 0x05
        rom[8'hDB] = 8'h20;  // STA R0       R0 = 0x05

        // Output swapped values
        rom[8'hDC] = 8'h10;  // LDA R0       ACC = 0x05 (was R1's value)
        rom[8'hDD] = 8'hF0;  // OUTA         OUT = 0x05    ** Output 49: 0x05 **
        rom[8'hDE] = 8'h11;  // LDA R1       ACC = 0x0F (was R0's value)
        rom[8'hDF] = 8'hF0;  // OUTA         OUT = 0x0F    ** Output 50: 0x0F **

        // ============================================================
        // SECTION 15: Final halt - infinite loop
        // ============================================================
        rom[8'hE0] = 8'hC0;  // JMP 0x0 -> {0xE, 0x0} = 0xE0 (infinite loop / halt)

        // ============================================================
        // Expected output sequence
        // ============================================================
        num_expected = 51;

        expected_outputs[0]  = 8'h05;  // LDI #5
        expected_outputs[1]  = 8'h00;  // LDI #0
        expected_outputs[2]  = 8'h0F;  // LDI #15
        expected_outputs[3]  = 8'h07;  // STA/LDA R0
        expected_outputs[4]  = 8'h0A;  // STA/LDA R7
        expected_outputs[5]  = 8'h08;  // ADD 3+5
        expected_outputs[6]  = 8'h00;  // ADD 0xFF+0x01 (overflow)
        expected_outputs[7]  = 8'h01;  // JC taken (carry from overflow)
        expected_outputs[8]  = 8'h05;  // SUB 8-3
        expected_outputs[9]  = 8'h00;  // SUB 3-3 (zero)
        expected_outputs[10] = 8'h01;  // JZ taken
        expected_outputs[11] = 8'h02;  // JZ not taken
        expected_outputs[12] = 8'h03;  // JC not taken
        expected_outputs[13] = 8'h0F;  // AND 0xFF & 0x0F
        expected_outputs[14] = 8'h00;  // AND with zero
        expected_outputs[15] = 8'hAF;  // OR 0x0F | 0xA0
        expected_outputs[16] = 8'h00;  // XOR self
        expected_outputs[17] = 8'hAF;  // XOR 0x0F ^ 0xA0
        expected_outputs[18] = 8'hFF;  // NOT 0x00
        expected_outputs[19] = 8'h00;  // NOT 0xFF
        expected_outputs[20] = 8'h02;  // SHL 0x01
        expected_outputs[21] = 8'h00;  // SHL 0x80 (carry out)
        expected_outputs[22] = 8'h01;  // JC from SHL carry
        expected_outputs[23] = 8'h02;  // SHR 0x04
        expected_outputs[24] = 8'h00;  // SHR 0x01 (carry out)
        expected_outputs[25] = 8'h18;  // SHL x3 of 0x03
        expected_outputs[26] = 8'hAB;  // INA (0xAB)
        expected_outputs[27] = 8'h00;  // INA (0x00)
        expected_outputs[28] = 8'hFF;  // INA (0xFF)
        expected_outputs[29] = 8'h04;  // JMP test
        expected_outputs[30] = 8'h09;  // JMP continued
        expected_outputs[31] = 8'hFF;  // SUB underflow 0-1
        expected_outputs[32] = 8'h01;  // JC from borrow
        expected_outputs[33] = 8'hA5;  // Build 0xA5
        expected_outputs[34] = 8'h5A;  // NOT 0xA5
        expected_outputs[35] = 8'h0A;  // AND 0x5A & 0x0F
        expected_outputs[36] = 8'h03;  // Loop: count 3
        expected_outputs[37] = 8'h02;  // Loop: count 2
        expected_outputs[38] = 8'h01;  // Loop: count 1
        expected_outputs[39] = 8'h00;  // Loop: exit (0)
        expected_outputs[40] = 8'h01;  // Reg isolation R0
        expected_outputs[41] = 8'h02;  // Reg isolation R1
        expected_outputs[42] = 8'h03;  // Reg isolation R2
        expected_outputs[43] = 8'h04;  // Reg isolation R3
        expected_outputs[44] = 8'h05;  // Reg isolation R4
        expected_outputs[45] = 8'h06;  // Reg isolation R5
        expected_outputs[46] = 8'h07;  // Reg isolation R6
        expected_outputs[47] = 8'h08;  // Reg isolation R7
        expected_outputs[48] = 8'h3C;  // ADD chain (15x4=60)
        expected_outputs[49] = 8'h05;  // XOR swap R0
        expected_outputs[50] = 8'h0F;  // XOR swap R1
    end

    // ============================================================
    // Input port management
    // Set in_port at the right time for INA instructions
    // ============================================================
    always @(posedge clk) begin
        // Default input
        if (rom_addr == 8'h79)
            in_port <= 8'hAB;   // For INA test at 0x79
        else if (rom_addr == 8'h7B)
            in_port <= 8'h00;   // For INA test at 0x7B
        else if (rom_addr == 8'h7D)
            in_port <= 8'hFF;   // For INA test at 0x7D
    end

    // ============================================================
    // Output monitor and checker
    // ============================================================
    initial begin
        output_count = 0;
        pass_count   = 0;
        fail_count   = 0;
        in_port      = 8'h00;
    end

    // Description strings for each output
    reg [255:0] test_descriptions [0:50];
    initial begin
        test_descriptions[0]  = "LDI #5 -> OUTA";
        test_descriptions[1]  = "LDI #0 (zero) -> OUTA";
        test_descriptions[2]  = "LDI #15 (max imm) -> OUTA";
        test_descriptions[3]  = "STA R0 / LDA R0 round-trip";
        test_descriptions[4]  = "STA R7 / LDA R7 (highest reg)";
        test_descriptions[5]  = "ADD: 3 + 5 = 8";
        test_descriptions[6]  = "ADD overflow: 0xFF + 0x01 = 0x00";
        test_descriptions[7]  = "JC taken (carry from ADD overflow)";
        test_descriptions[8]  = "SUB: 8 - 3 = 5";
        test_descriptions[9]  = "SUB equal: 3 - 3 = 0 (zero flag)";
        test_descriptions[10] = "JZ taken (zero from SUB)";
        test_descriptions[11] = "JZ not taken (non-zero ACC)";
        test_descriptions[12] = "JC not taken (no carry)";
        test_descriptions[13] = "AND: 0xFF & 0x0F = 0x0F";
        test_descriptions[14] = "AND: with zero = 0x00";
        test_descriptions[15] = "OR: 0x0F | 0xA0 = 0xAF";
        test_descriptions[16] = "XOR self: 0x0F ^ 0x0F = 0x00";
        test_descriptions[17] = "XOR diff: 0x0F ^ 0xA0 = 0xAF";
        test_descriptions[18] = "NOT: ~0x00 = 0xFF";
        test_descriptions[19] = "NOT: ~0xFF = 0x00 (double NOT)";
        test_descriptions[20] = "SHL: 0x01 << 1 = 0x02";
        test_descriptions[21] = "SHL: 0x80 << 1 = 0x00 (carry out)";
        test_descriptions[22] = "JC taken (carry from SHL)";
        test_descriptions[23] = "SHR: 0x04 >> 1 = 0x02";
        test_descriptions[24] = "SHR: 0x01 >> 1 = 0x00 (carry out)";
        test_descriptions[25] = "SHL x3: 0x03 << 3 = 0x18";
        test_descriptions[26] = "INA: read 0xAB from input port";
        test_descriptions[27] = "INA: read 0x00 (zero input)";
        test_descriptions[28] = "INA: read 0xFF (max input)";
        test_descriptions[29] = "JMP: unconditional jump verified";
        test_descriptions[30] = "JMP: continued execution after jump";
        test_descriptions[31] = "SUB underflow: 0 - 1 = 0xFF";
        test_descriptions[32] = "JC taken (borrow from SUB underflow)";
        test_descriptions[33] = "Complex build: 0xA5 via SHL+OR";
        test_descriptions[34] = "NOT: ~0xA5 = 0x5A";
        test_descriptions[35] = "AND mask: 0x5A & 0x0F = 0x0A";
        test_descriptions[36] = "Loop iteration 1: countdown 3";
        test_descriptions[37] = "Loop iteration 2: countdown 2";
        test_descriptions[38] = "Loop iteration 3: countdown 1";
        test_descriptions[39] = "Loop exit: countdown 0";
        test_descriptions[40] = "Reg isolation: R0 = 1";
        test_descriptions[41] = "Reg isolation: R1 = 2";
        test_descriptions[42] = "Reg isolation: R2 = 3";
        test_descriptions[43] = "Reg isolation: R3 = 4";
        test_descriptions[44] = "Reg isolation: R4 = 5";
        test_descriptions[45] = "Reg isolation: R5 = 6";
        test_descriptions[46] = "Reg isolation: R6 = 7";
        test_descriptions[47] = "Reg isolation: R7 = 8";
        test_descriptions[48] = "ADD chain: 15+15+15+15 = 60";
        test_descriptions[49] = "XOR swap result: R0 = 0x05";
        test_descriptions[50] = "XOR swap result: R1 = 0x0F";
    end

    always @(posedge clk) begin
        if (rst_n && out_valid) begin
            if (output_count < num_expected) begin
                if (out_port === expected_outputs[output_count]) begin
                    $display("PASS Output %0d: got 0x%02h (expected 0x%02h) - %0s",
                             output_count, out_port, expected_outputs[output_count],
                             test_descriptions[output_count]);
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL Output %0d: got 0x%02h (expected 0x%02h) - %0s",
                             output_count, out_port, expected_outputs[output_count],
                             test_descriptions[output_count]);
                    fail_count = fail_count + 1;
                end
            end else begin
                $display("UNEXPECTED Output %0d: got 0x%02h", output_count, out_port);
                fail_count = fail_count + 1;
            end
            output_count = output_count + 1;
        end
    end

    // ============================================================
    // Main simulation control
    // ============================================================
    initial begin
        $display("========================================================");
        $display("   FULL INTEGRATION TESTBENCH - 8-Bit Microprocessor");
        $display("========================================================");
        $display("Testing %0d expected outputs across all instructions", num_expected);
        $display("--------------------------------------------------------");

        clk   = 0;
        rst_n = 0;

        // Hold reset for 4 clock cycles
        repeat (4) @(posedge clk);
        rst_n = 1;

        // Run for enough cycles
        // Each instruction takes 2 clock cycles (fetch + execute)
        // With ~230 instructions in the program and some loops,
        // 2000 cycles should be more than enough
        repeat (2000) @(posedge clk);

        $display("");
        $display("========================================================");
        if (output_count < num_expected) begin
            $display("WARNING: Only %0d of %0d expected outputs were produced",
                     output_count, num_expected);
            fail_count = fail_count + (num_expected - output_count);
        end

        $display("INTEGRATION TEST RESULTS: %0d PASS, %0d FAIL out of %0d tests",
                 pass_count, fail_count, num_expected);

        if (fail_count == 0)
            $display("*** ALL TESTS PASSED ***");
        else
            $display("*** SOME TESTS FAILED ***");

        $display("========================================================");
        $finish;
    end

    // ============================================================
    // Timeout watchdog
    // ============================================================
    initial begin
        #100000;
        $display("TIMEOUT: Simulation exceeded maximum time");
        $finish;
    end

    // ============================================================
    // Optional: waveform dump
    // ============================================================
    initial begin
        $dumpfile("microprocessor_tb.vcd");
        $dumpvars(0, tb_microprocessor);
    end

endmodule