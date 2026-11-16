// Datapath integration testbench.
// Exercises arithmetic, memory interface, branches, jumps, and jal write-back.

`timescale 1ns/1ps

module datapath_tb;
    reg clk, reset;
    reg [31:0] pc, instruction, data_mem_read_data;
    wire reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write;
    wire branch, branch_ne, jump, jal, jr;
    wire [3:0] alu_op;
    wire [31:0] next_pc, data_mem_address, data_mem_write_data;
    wire data_mem_read, data_mem_write;
    integer fail_count;

    control_unit control (
        .opcode(instruction[31:26]), .funct(instruction[5:0]),
        .reg_dst(reg_dst), .alu_src(alu_src), .mem_to_reg(mem_to_reg),
        .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
        .branch(branch), .branch_ne(branch_ne), .jump(jump), .jal(jal), .jr(jr), .alu_op(alu_op)
    );

    datapath dut (
        .clk(clk), .reset(reset), .pc(pc), .instruction(instruction),
        .data_mem_read_data(data_mem_read_data), .reg_dst(reg_dst),
        .alu_src(alu_src), .mem_to_reg(mem_to_reg), .reg_write(reg_write),
        .mem_read(mem_read), .mem_write(mem_write), .branch(branch),
        .branch_ne(branch_ne), .jump(jump), .jal(jal), .jr(jr), .alu_op(alu_op),
        .next_pc(next_pc), .data_mem_address(data_mem_address),
        .data_mem_write_data(data_mem_write_data), .data_mem_read(data_mem_read),
        .data_mem_write(data_mem_write)
    );

    always #5 clk = ~clk;

    task check_value;
        input [31:0] actual;
        input [31:0] expected;
        input string name;
        begin
            #1;
            if (actual === expected) begin
                $display("PASS: %s -> 0x%08h", name, actual);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %s -> got 0x%08h, expected 0x%08h", name, actual, expected);
            end
        end
    endtask

    task clock_instruction;
        input [31:0] instruction_value;
        input [31:0] pc_value;
        begin
            instruction = instruction_value;
            pc = pc_value;
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        pc = 32'b0;
        instruction = 32'b0;
        data_mem_read_data = 32'b0;
        fail_count = 0;

        $display("===== Datapath Integration Test =====");
        @(posedge clk);
        #1;
        reset = 1'b0;

        // addi $t0, $zero, 5; addi $t1, $zero, 7
        instruction = 32'h20080005;
        pc = 32'd0;
        #1;
        check_value(next_pc, 32'd4, "addi next PC");
        clock_instruction(32'h20080005, 32'd0);
        clock_instruction(32'h20090007, 32'd4);
        check_value(dut.rf.registers[8], 32'd5, "addi writes $t0");
        check_value(dut.rf.registers[9], 32'd7, "addi writes $t1");

        // add $t2, $t0, $t1
        clock_instruction(32'h01095020, 32'd8);
        check_value(dut.rf.registers[10], 32'd12, "add writes $t2");

        // sll $t4, $t2, 2
        clock_instruction(32'h000A6080, 32'd12);
        check_value(dut.rf.registers[12], 32'd48, "sll writes $t4");

        // sw $t2, 0($zero)
        instruction = 32'hAC0A0000;
        pc = 32'd16;
        #1;
        check_value(data_mem_address, 32'd0, "sw address");
        check_value(data_mem_write_data, 32'd12, "sw write data");
        check_value({31'b0, data_mem_write}, 32'd1, "sw memory write enable");

        // lw $t3, 0($zero)
        data_mem_read_data = 32'd12;
        clock_instruction(32'h8C0B0000, 32'd16);
        check_value({31'b0, data_mem_read}, 32'd1, "lw memory read enable");
        check_value(dut.rf.registers[11], 32'd12, "lw writes $t3");

        // beq $t0, $t0, 2: 20 + 4 + (2 << 2) = 32
        instruction = 32'h11080002;
        pc = 32'd20;
        #1;
        check_value(next_pc, 32'd32, "taken beq target");

        // bne $t0, $t0, 2 must not branch.
        instruction = 32'h15080002;
        pc = 32'd24;
        #1;
        check_value(next_pc, 32'd28, "not-taken bne target");

        // j 0x10: target is 0x40 for a low PC region.
        instruction = 32'h08000010;
        pc = 32'd28;
        #1;
        check_value(next_pc, 32'h00000040, "jump target");

        // jal 0x10 writes PC+4 to $ra and jumps to 0x40.
        clock_instruction(32'h0C000010, 32'd28);
        check_value(next_pc, 32'h00000040, "jal target");
        check_value(dut.rf.registers[31], 32'd32, "jal writes return address");

        if (fail_count != 0) begin
            $fatal(1, "Datapath test failed: %0d check(s)", fail_count);
        end
        $display("PASS: Datapath test completed with no failures");
        $finish;
    end
endmodule