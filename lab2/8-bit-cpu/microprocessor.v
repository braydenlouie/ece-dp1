module microprocessor (
    input  wire       clk,
    input  wire       rst_n,
    output wire [7:0] rom_addr,
    input  wire [7:0] rom_data,
    output wire [7:0] out_port,
    output wire       out_valid
);

    // Internal wires
    wire [3:0] opcode;
    wire [3:0] operand;
    wire [7:0] acc_out;
    wire [7:0] rf_data_out;
    wire [7:0] alu_result;
    wire       alu_carry;
    wire       alu_zero;
    wire       z_flag;
    wire       c_flag;
    wire [7:0] pc_out;

    // Control signals
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

    // Accumulator input mux
    reg [7:0] acc_in;
    always @(*) begin
        case (acc_src)
            2'b00:   acc_in = alu_result;
            2'b01:   acc_in = rf_data_out;
            2'b10:   acc_in = {4'h0, operand};
            default: acc_in = 8'h00;
        endcase
    end

    // Jump address: upper nibble from PC, lower nibble from operand
    wire [7:0] pc_jump_addr = {pc_out[7:4], operand};

    // Flags input: ALU flags for ALU ops, computed flags for LDA/LDI
    wire z_in = (acc_src == 2'b00) ? alu_zero : (acc_in == 8'h00);
    wire c_in = (acc_src == 2'b00) ? alu_carry : c_flag;

    assign rom_addr = pc_out;

    // ---- Instantiations ----

    program_counter u_pc (
        .clk     (clk),
        .rst_n   (rst_n),
        .pc_inc  (pc_inc),
        .pc_load (pc_load),
        .pc_in   (pc_jump_addr),
        .pc_out  (pc_out)
    );

    instruction_register u_ir (
        .clk      (clk),
        .rst_n    (rst_n),
        .ir_load  (ir_load),
        .data_in  (rom_data),
        .opcode   (opcode),
        .operand  (operand)
    );

    accumulator u_acc (
        .clk      (clk),
        .rst_n    (rst_n),
        .acc_load (acc_load),
        .acc_in   (acc_in),
        .acc_out  (acc_out)
    );

    flags_register u_flags (
        .clk        (clk),
        .rst_n      (rst_n),
        .flags_load (flags_load),
        .z_in       (z_in),
        .c_in       (c_in),
        .z_flag     (z_flag),
        .c_flag     (c_flag)
    );

    register_file u_rf (
        .clk         (clk),
        .rst_n       (rst_n),
        .rf_write    (rf_write),
        .rf_addr     (operand[2:0]),     // 3-bit address
        .rf_data_in  (acc_out),
        .rf_data_out (rf_data_out)
    );

    alu u_alu (
        .a_in       (acc_out),
        .b_in       (rf_data_out),
        .alu_op     (alu_op),
        .alu_result (alu_result),
        .alu_carry  (alu_carry),
        .alu_zero   (alu_zero)
    );

    output_register u_out (
        .clk       (clk),
        .rst_n     (rst_n),
        .out_load  (out_load),
        .data_in   (acc_out),
        .out_port  (out_port),
        .out_valid (out_valid)
    );

    control_unit u_ctrl (
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

endmodule
