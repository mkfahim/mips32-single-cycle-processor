// End-to-end single-cycle CPU testbench.
// Loads a small program into instruction memory and verifies register,
// memory, branch, jump, and jal behavior across clock cycles.

`timescale 1ns/1ps

module mips32_cpu_tb;
    reg clk;
    reg reset;
    wire [31:0] pc;
    integer fail_count;

    mips32_cpu #(
        .IM_ADDR_WIDTH(4),
        .DM_ADDR_WIDTH(4)
    ) dut (
        .clk(clk), .reset(reset), .pc(pc)
    );

    always #5 clk = ~clk;

    task check_value;
        input [31:0] actual;
        input [31:0] expected;
        input string name;
        begin
            if (actual === expected) begin
                $display("PASS: %s -> 0x%08h", name, actual);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %s -> got 0x%08h, expected 0x%08h", name, actual, expected);
            end
        end
    endtask

    task step;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        fail_count = 0;

        // Program words, indexed by byte address / 4:
        // 0: addi $t0, $zero, 5
        // 1: addi $t1, $zero, 7
        // 2: add  $t2, $t0, $t1
        // 3: sw   $t2, 0($zero)
        // 4: lw   $t3, 0($zero)
        // 5: beq  $t3, $t2, 1   (skip instruction 6)
        // 6: addi $t4, $zero, 99
        // 7: jal  10            (target address 40)
        // 8: addi $t4, $zero, 1 (skipped by jal)
        // 9: nop
        //10: addi $t5, $zero, 42
        //11: xori $t6, $t0, 0x00ff
        //12: lui  $t7, 0x1234
        //13: sll  $t8, $t0, 4
        //14: jr   $ra
        dut.instruction_memory_unit.memory[0]  = 32'h20080005;
        dut.instruction_memory_unit.memory[1]  = 32'h20090007;
        dut.instruction_memory_unit.memory[2]  = 32'h01095020;
        dut.instruction_memory_unit.memory[3]  = 32'hAC0A0000;
        dut.instruction_memory_unit.memory[4]  = 32'h8C0B0000;
        dut.instruction_memory_unit.memory[5]  = 32'h116A0001;
        dut.instruction_memory_unit.memory[6]  = 32'h200C0063;
        dut.instruction_memory_unit.memory[7]  = 32'h0C00000A;
        dut.instruction_memory_unit.memory[8]  = 32'h200C0001;
        dut.instruction_memory_unit.memory[9]  = 32'h00000000;
        dut.instruction_memory_unit.memory[10] = 32'h200D002A;
        dut.instruction_memory_unit.memory[11] = 32'h390E00FF;
        dut.instruction_memory_unit.memory[12] = 32'h3C0F1234;
        dut.instruction_memory_unit.memory[13] = 32'h0008C100;
        dut.instruction_memory_unit.memory[14] = 32'h03E00008;

        $display("===== MIPS32 Single-Cycle CPU Test =====");
        step;
        reset = 1'b0;

        step;
        check_value(dut.datapath_unit.rf.registers[8], 32'd5, "addi writes $t0");
        check_value(pc, 32'd4, "PC after first instruction");

        step;
        check_value(dut.datapath_unit.rf.registers[9], 32'd7, "addi writes $t1");
        check_value(pc, 32'd8, "PC after second instruction");

        step;
        check_value(dut.datapath_unit.rf.registers[10], 32'd12, "add writes $t2");

        step;
        check_value(dut.data_memory_unit.memory[0], 32'd12, "sw stores $t2");

        step;
        check_value(dut.datapath_unit.rf.registers[11], 32'd12, "lw writes $t3");

        step;
        check_value(pc, 32'd28, "beq skips instruction");
        check_value(dut.datapath_unit.rf.registers[12], 32'd0, "skipped instruction leaves $t4 unchanged");

        step;
        check_value(pc, 32'd40, "jal jumps to target");
        check_value(dut.datapath_unit.rf.registers[31], 32'd32, "jal writes $ra");

        step;
        check_value(dut.datapath_unit.rf.registers[13], 32'd42, "target instruction writes $t5");
        check_value(dut.datapath_unit.rf.registers[12], 32'd0, "instruction after jal remains skipped");

        step;
        check_value(dut.datapath_unit.rf.registers[14], 32'h000000FA, "xori writes $t6");

        step;
        check_value(dut.datapath_unit.rf.registers[15], 32'h12340000, "lui writes $t7");

        step;
        check_value(dut.datapath_unit.rf.registers[24], 32'h00000050, "sll writes $t8");

        step;
        check_value(pc, 32'd32, "jr returns to $ra");

        step;
        check_value(dut.datapath_unit.rf.registers[12], 32'd1, "instruction after jr executes");

        if (fail_count != 0) begin
            $fatal(1, "CPU integration test failed: %0d check(s)", fail_count);
        end
        $display("PASS: CPU integration test completed with no failures");
        $finish;
    end
endmodule