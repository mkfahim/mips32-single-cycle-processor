// Instruction memory testbench.
// Verifies aligned reads, zero initialization, and invalid addresses.

`timescale 1ns/1ps

module instruction_memory_tb;

    reg  [31:0] address;
    wire [31:0] instruction;
    integer fail_count;

    instruction_memory #(
        .ADDR_WIDTH(4)
    ) uut (
        .address(address),
        .instruction(instruction)
    );

    task check_instruction;
        input [31:0] address_value;
        input [31:0] expected;
        input string test_name;
        begin
            address = address_value;
            #1;
            if (instruction === expected) begin
                $display("PASS: %s -> instruction=0x%08h", test_name, instruction);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %s -> got 0x%08h, expected 0x%08h",
                         test_name, instruction, expected);
            end
        end
    endtask

    initial begin
        fail_count = 0;
        address = 32'b0;

        // Seed representative words as a loader or integration test would.
        uut.memory[0] = 32'h20080001;
        uut.memory[1] = 32'h20090002;
        uut.memory[15] = 32'h0800000F;

        $display("===== Instruction Memory Unit Test =====");
        check_instruction(32'h00000000, 32'h20080001, "read word at address 0");
        check_instruction(32'h00000004, 32'h20090002, "read word at address 4");
        check_instruction(32'h0000003C, 32'h0800000F, "read last word in configured range");
        check_instruction(32'h00000008, 32'h00000000, "uninitialized word reads as zero");
        check_instruction(32'h00000002, 32'h00000000, "unaligned address returns zero");
        check_instruction(32'h00000040, 32'h00000000, "out-of-range address returns zero");
        check_instruction(32'h80000000, 32'h00000000, "high address returns zero");

        if (fail_count != 0) begin
            $fatal(1, "Instruction memory test failed: %0d check(s)", fail_count);
        end

        $display("PASS: Instruction memory test completed with no failures");
        $finish;
    end

endmodule