// Control Unit Testbench for the supported MIPS32 subset.

`timescale 1ns/1ps

module control_unit_tb;
    reg [5:0] opcode;
    reg [5:0] funct;
    wire reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write;
    wire branch, branch_ne, jump, jal;
    wire [3:0] alu_op;
    integer fail_count;

    control_unit dut (
        .opcode(opcode), .funct(funct), .reg_dst(reg_dst), .alu_src(alu_src),
        .mem_to_reg(mem_to_reg), .reg_write(reg_write), .mem_read(mem_read),
        .mem_write(mem_write), .branch(branch), .branch_ne(branch_ne),
        .jump(jump), .jal(jal), .alu_op(alu_op)
    );

    task check;
        input [5:0] op;
        input [5:0] fn;
        input exp_reg_dst, exp_alu_src, exp_mem_to_reg, exp_reg_write;
        input exp_mem_read, exp_mem_write, exp_branch, exp_branch_ne;
        input exp_jump, exp_jal;
        input [3:0] exp_alu_op;
        input string instr_name;
        begin
            opcode = op;
            funct = fn;
            #1;
            if (reg_dst === exp_reg_dst && alu_src === exp_alu_src &&
                mem_to_reg === exp_mem_to_reg && reg_write === exp_reg_write &&
                mem_read === exp_mem_read && mem_write === exp_mem_write &&
                branch === exp_branch && branch_ne === exp_branch_ne &&
                jump === exp_jump && jal === exp_jal && alu_op === exp_alu_op) begin
                $display("PASS: %s", instr_name);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %s", instr_name);
                $display("  got: branch=%b branch_ne=%b reg_write=%b alu_op=%b", branch, branch_ne, reg_write, alu_op);
                $display("  expected: branch=%b branch_ne=%b reg_write=%b alu_op=%b", exp_branch, exp_branch_ne, exp_reg_write, exp_alu_op);
            end
        end
    endtask

    initial begin
        fail_count = 0;
        $display("===== Control Unit Test =====");
        check(6'b000000, 6'b100000, 1,0,0,1,0,0,0,0,0,0, 4'b0000, "add");
        check(6'b000000, 6'b100010, 1,0,0,1,0,0,0,0,0,0, 4'b0001, "sub");
        check(6'b000000, 6'b100100, 1,0,0,1,0,0,0,0,0,0, 4'b0010, "and");
        check(6'b000000, 6'b100101, 1,0,0,1,0,0,0,0,0,0, 4'b0011, "or");
        check(6'b000000, 6'b100110, 1,0,0,1,0,0,0,0,0,0, 4'b0100, "xor");
        check(6'b000000, 6'b101010, 1,0,0,1,0,0,0,0,0,0, 4'b0101, "slt");
        check(6'b001000, 0, 0,1,0,1,0,0,0,0,0,0, 4'b0000, "addi");
        check(6'b001100, 0, 0,1,0,1,0,0,0,0,0,0, 4'b0010, "andi");
        check(6'b001101, 0, 0,1,0,1,0,0,0,0,0,0, 4'b0011, "ori");
        check(6'b001010, 0, 0,1,0,1,0,0,0,0,0,0, 4'b0101, "slti");
        check(6'b001110, 0, 0,1,0,1,0,0,0,0,0,0, 4'b0100, "xori");
        check(6'b100011, 0, 0,1,1,1,1,0,0,0,0,0, 4'b0000, "lw");
        check(6'b101011, 0, 0,1,0,0,0,1,0,0,0,0, 4'b0000, "sw");
        check(6'b000100, 0, 0,0,0,0,0,0,1,0,0,0, 4'b0001, "beq");
        check(6'b000101, 0, 0,0,0,0,0,0,1,1,0,0, 4'b0001, "bne");
        check(6'b000010, 0, 0,0,0,0,0,0,0,0,1,0, 4'b0000, "j");
        check(6'b000011, 0, 0,0,0,1,0,0,0,0,1,1, 4'b0000, "jal");
        check(6'b000000, 0, 0,0,0,0,0,0,0,0,0,0, 4'b0000, "unsupported funct");
        check(6'b111111, 0, 0,0,0,0,0,0,0,0,0,0, 4'b0000, "unsupported opcode");
        if (fail_count != 0) $fatal(1, "Control unit test failed: %0d check(s)", fail_count);
        $display("PASS: Control unit test completed with no failures");
        $finish;
    end
endmodule