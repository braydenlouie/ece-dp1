module control_unit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] opcode,
    input  wire       z_flag,
    input  wire       c_flag,
    output reg        ir_load,
    output reg        pc_inc,
    output reg        pc_load,
    output reg        acc_load,
    output reg  [1:0] acc_src,
    output reg        rf_write,
    output reg  [2:0] alu_op,
    output reg        flags_load,
    output reg        out_load,
    output reg        phase
);

    localparam OP_INA  = 4'h0;   // was NOP
    localparam OP_LDA  = 4'h1;
    localparam OP_STA  = 4'h2;
    localparam OP_LDI  = 4'h3;
    localparam OP_ADD  = 4'h4;
    localparam OP_SUB  = 4'h5;
    localparam OP_AND  = 4'h6;
    localparam OP_OR   = 4'h7;
    localparam OP_XOR  = 4'h8;
    localparam OP_NOT  = 4'h9;
    localparam OP_SHL  = 4'hA;
    localparam OP_SHR  = 4'hB;
    localparam OP_JMP  = 4'hC;
    localparam OP_JZ   = 4'hD;
    localparam OP_JC   = 4'hE;
    localparam OP_OUTA = 4'hF;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            phase <= 1'b0;
        else
            phase <= ~phase;
    end

    always @(*) begin
        ir_load    = 1'b0;
        pc_inc     = 1'b0;
        pc_load    = 1'b0;
        acc_load   = 1'b0;
        acc_src    = 2'b00;
        rf_write   = 1'b0;
        alu_op     = 3'b000;
        flags_load = 1'b0;
        out_load   = 1'b0;

        if (phase == 1'b0) begin
            ir_load = 1'b1;
            pc_inc  = 1'b1;
        end else begin
            case (opcode)
                OP_INA: begin
                    acc_load   = 1'b1;
                    acc_src    = 2'b11;     // select input port
                    flags_load = 1'b1;
                end

                OP_LDA: begin
                    acc_load   = 1'b1;
                    acc_src    = 2'b01;
                    flags_load = 1'b1;
                end

                OP_STA: begin
                    rf_write = 1'b1;
                end

                OP_LDI: begin
                    acc_load   = 1'b1;
                    acc_src    = 2'b10;
                    flags_load = 1'b1;
                end

                OP_ADD: begin
                    acc_load   = 1'b1;
                    acc_src    = 2'b00;
                    alu_op     = 3'b000;
                    flags_load = 1'b1;
                end

                OP_SUB: begin
                    acc_load   = 1'b1;
                    acc_src    = 2'b00;
                    alu_op     = 3'b001;
                    flags_load = 1'b1;
                end

                OP_AND: begin
                    acc_load   = 1'b1;
                    acc_src    = 2'b00;
                    alu_op     = 3'b010;
                    flags_load = 1'b1;
                end

                OP_OR: begin
                    acc_load   = 1'b1;
                    acc_src    = 2'b00;
                    alu_op     = 3'b011;
                    flags_load = 1'b1;
                end

                OP_XOR: begin
                    acc_load   = 1'b1;
                    acc_src    = 2'b00;
                    alu_op     = 3'b100;
                    flags_load = 1'b1;
                end

                OP_NOT: begin
                    acc_load   = 1'b1;
                    acc_src    = 2'b00;
                    alu_op     = 3'b101;
                    flags_load = 1'b1;
                end

                OP_SHL: begin
                    acc_load   = 1'b1;
                    acc_src    = 2'b00;
                    alu_op     = 3'b110;
                    flags_load = 1'b1;
                end

                OP_SHR: begin
                    acc_load   = 1'b1;
                    acc_src    = 2'b00;
                    alu_op     = 3'b111;
                    flags_load = 1'b1;
                end

                OP_JMP: begin
                    pc_load = 1'b1;
                end

                OP_JZ: begin
                    pc_load = z_flag;
                end

                OP_JC: begin
                    pc_load = c_flag;
                end

                OP_OUTA: begin
                    out_load = 1'b1;
                end
            endcase
        end
    end

endmodule