// tb/control_unit_tb.v
// Control Unit Testbench for Phase 1 MIPS32 subset
// Tests supported R/I/J instructions and unsupported encodings.
//
// Checks outputs:
//   reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write,
//   branch, jump, jal, alu_op

`timescale 1ns/1ps

module control_unit_tb;

    // Inputs to DUT
    reg  [5:0] opcode;
    reg  [5:0] funct;

    // Outputs from DUT
    wire       reg_dst;
    wire       alu_src;
    wire       mem_to_reg;
    wire       reg_write;
    wire       mem_read;
    wire       mem_write;
    wire       branch;
    wire       jump;
    wire       jal;
    wire [3:0] alu_op;

    // Instantiate device under test
    control_unit dut (
        .opcode(opcode),
        .funct(funct),
        .reg_dst(reg_dst),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .jump(jump),
        .jal(jal),
        .alu_op(alu_op)
    );

    // Helper task: assert expected signals for an instruction
    task check(
        input [5:0] op,
        input [5:0] fn,
        input exp_reg_dst,
        input exp_alu_src,
        input exp_mem_to_reg,
        input exp_reg_write,
        input exp_mem_read,
        input exp_mem_write,
        input exp_branch,
        input exp_jump,
        input exp_jal,
        input [3:0] exp_alu_op,
        input string instr_name
    );
    begin
        opcode = op;
        funct  = fn;
        #1; // combinational settle

        if (reg_dst    === exp_reg_dst  &&
            alu_src    === exp_alu_src  &&
            mem_to_reg === exp_mem_to_reg &&
            reg_write  === exp_reg_write &&
            mem_read   === exp_mem_read &&
            mem_write  === exp_mem_write &&
            branch     === exp_branch &&
            jump       === exp_jump &&
            jal        === exp_jal &&
            alu_op     === exp_alu_op) begin
            $display("✓ PASS: %s", instr_name);
        end else begin
            $display("✗ FAIL: %s", instr_name);
            $display("    got: reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_read=%b mem_write=%b branch=%b jump=%b jal=%b alu_op=%b",
                     reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write, branch, jump, jal, alu_op);
            $display(" expected: reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_read=%b mem_write=%b branch=%b jump=%b jal=%b alu_op=%b",
                     exp_reg_dst, exp_alu_src, exp_mem_to_reg, exp_reg_write, exp_mem_read, exp_mem_write, exp_branch, exp_jump, exp_jal, exp_alu_op);
        end
    end
    endtask

    initial begin
        $display("\n===== Control Unit Test =====\n");

        // R-type (opcode = 000000), funct select
        $display("--- R-type ---");
        check(6'b000000, 6'b100000, 1,0,0,1,0,0,0,0,0, 4'b0000, "add (R-type)");
        check(6'b000000, 6'b100010, 1,0,0,1,0,0,0,0,0, 4'b0001, "sub (R-type)");
        check(6'b000000, 6'b100100, 1,0,0,1,0,0,0,0,0, 4'b0010, "and (R-type)");
        check(6'b000000, 6'b100101, 1,0,0,1,0,0,0,0,0, 4'b0011, "or  (R-type)");
        check(6'b000000, 6'b100110, 1,0,0,1,0,0,0,0,0, 4'b0100, "xor (R-type)");
        check(6'b000000, 6'b101010, 1,0,0,1,0,0,0,0,0, 4'b0101, "slt (R-type)");

        // I-type arithmetic/logical
        $display("\n--- I-type ---");
        check(6'b001000, 6'b000000, 0,1,0,1,0,0,0,0,0, 4'b0000, "addi");
        check(6'b001100, 6'b000000, 0,1,0,1,0,0,0,0,0, 4'b0010, "andi");
        check(6'b001101, 6'b000000, 0,1,0,1,0,0,0,0,0, 4'b0011, "ori");
        check(6'b001010, 6'b000000, 0,1,0,1,0,0,0,0,0, 4'b0101, "slti");

        // Load/store
        $display("\n--- Load/Store ---");
        check(6'b100011, 6'b000000, 0,1,1,1,1,0,0,0,0, 4'b0000, "lw");
        check(6'b101011, 6'b000000, 0,1,0,0,0,1,0,0,0, 4'b0000, "sw");

        // Branches
        $display("\n--- Branches ---");
        check(6'b000100, 6'b000000, 0,0,0,0,0,0,1,0,0, 4'b0001, "beq");
        check(6'b000101, 6'b000000, 0,0,0,0,0,0,1,0,0, 4'b0001, "bne");

        // Jumps
        $display("\n--- Jumps ---");
        check(6'b000010, 6'b000000, 0,0,0,0,0,0,0,1,0, 4'b0000, "j");
        check(6'b000011, 6'b000000, 0,0,0,1,0,0,0,1,1, 4'b0000, "jal");

        // Unsupported cases (should be safe defaults -> mostly zeros)
        $display("\n--- Unsupported ---");
        check(6'b000000, 6'b000000, 0,0,0,0,0,0,0,0,0, 4'b0000, "R-type unsupported funct (0)");
        check(6'b111111, 6'b000000, 0,0,0,0,0,0,0,0,0, 4'b0000, "unsupported opcode (63)");

        $display("\n===== Control Unit Test Complete =====\n");
        $finish;
    end

endmodule
