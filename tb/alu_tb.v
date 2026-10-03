// ALU Testbench for MIPS32 Single-Cycle Processor
//
// Tests all ALU operations with representative test cases:
// - Positive operands
// - Negative operands (two's complement)
// - Zero operands
// - Boundary values

`timescale 1ns / 1ps

module alu_tb;

    // Testbench signals
    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  alu_control;
    wire [31:0] result;
    wire        zero;

    // Instantiate ALU
    alu uut (
        .a(a),
        .b(b),
        .alu_control(alu_control),
        .result(result),
        .zero(zero)
    );

    // Test task: compare result against expected value
    task test_operation(
        input [31:0] a_val,
        input [31:0] b_val,
        input [3:0]  ctrl,
        input [31:0] expected,
        input        expected_zero,
        input string op_name
    );
        begin
            a = a_val;
            b = b_val;
            alu_control = ctrl;
            #1; // Allow combinational logic to settle
            
            if (result === expected && zero === expected_zero) begin
                $display("✓ PASS: %s (0x%08h, 0x%08h) => 0x%08h, zero=%b",
                    op_name, a_val, b_val, result, zero);
            end else begin
                $display("✗ FAIL: %s (0x%08h, 0x%08h) => got 0x%08h (zero=%b), expected 0x%08h (zero=%b)",
                    op_name, a_val, b_val, result, zero, expected, expected_zero);
            end
        end
    endtask

    // Main test sequence
    initial begin
        $display("===== ALU Unit Test =====\n");

        // Test ADD (4'b0000)
        $display("--- ADD Tests ---");
        test_operation(32'd5, 32'd3, 4'b0000, 32'd8, 1'b0, "add(5, 3)");
        test_operation(32'd0, 32'd0, 4'b0000, 32'd0, 1'b1, "add(0, 0)");
        test_operation(32'h7FFFFFFF, 32'd1, 4'b0000, 32'h80000000, 1'b0, "add(MAX_INT, 1)");

        // Test SUB (4'b0001)
        $display("\n--- SUB Tests ---");
        test_operation(32'd10, 32'd3, 4'b0001, 32'd7, 1'b0, "sub(10, 3)");
        test_operation(32'd3, 32'd10, 4'b0001, 32'hFFFFFFF9, 1'b0, "sub(3, 10) [negative]");
        test_operation(32'd5, 32'd5, 4'b0001, 32'd0, 1'b1, "sub(5, 5)");

        // Test AND (4'b0010)
        $display("\n--- AND Tests ---");
        test_operation(32'hFFFF0000, 32'h0000FFFF, 4'b0010, 32'h00000000, 1'b1, "and(0xFFFF0000, 0x0000FFFF)");
        test_operation(32'hFFFFFFFF, 32'hAAAAAAAA, 4'b0010, 32'hAAAAAAAA, 1'b0, "and(0xFFFFFFFF, 0xAAAAAAAA)");
        test_operation(32'h12345678, 32'h12345678, 4'b0010, 32'h12345678, 1'b0, "and(0x12345678, 0x12345678)");

        // Test OR (4'b0011)
        $display("\n--- OR Tests ---");
        test_operation(32'h0000FF00, 32'h000000FF, 4'b0011, 32'h0000FFFF, 1'b0, "or(0x0000FF00, 0x000000FF)");
        test_operation(32'h00000000, 32'h00000000, 4'b0011, 32'h00000000, 1'b1, "or(0, 0)");
        test_operation(32'hFFFF0000, 32'h0000FFFF, 4'b0011, 32'hFFFFFFFF, 1'b0, "or(0xFFFF0000, 0x0000FFFF)");

        // Test XOR (4'b0100)
        $display("\n--- XOR Tests ---");
        test_operation(32'hFFFFFFFF, 32'hFFFFFFFF, 4'b0100, 32'h00000000, 1'b1, "xor(0xFFFFFFFF, 0xFFFFFFFF)");
        test_operation(32'hAA55AA55, 32'h55AA55AA, 4'b0100, 32'hFFFFFFFF, 1'b0, "xor(0xAA55AA55, 0x55AA55AA)");
        test_operation(32'h12345678, 32'h12345678, 4'b0100, 32'h00000000, 1'b1, "xor(same, same)");

        // Test SLT - Signed Less Than (4'b0101)
        $display("\n--- SLT Tests (Signed) ---");
        test_operation(32'd5, 32'd10, 4'b0101, 32'd1, 1'b0, "slt(5, 10) => 1");
        test_operation(32'd10, 32'd5, 4'b0101, 32'd0, 1'b1, "slt(10, 5) => 0");
        test_operation(32'hFFFFFFFF, 32'd1, 4'b0101, 32'd1, 1'b0, "slt(-1, 1) => 1 [signed]");
        test_operation(32'hFFFFFFFF, 32'hFFFFFFFE, 4'b0101, 32'd0, 1'b1, "slt(-1, -2) => 0 [signed]");
        test_operation(32'h80000000, 32'd0, 4'b0101, 32'd1, 1'b0, "slt(MIN_INT, 0) => 1 [signed]");
        test_operation(32'd5, 32'd5, 4'b0101, 32'd0, 1'b1, "slt(5, 5) => 0");

        // Test ADDU (4'b0110)
        $display("\n--- ADDU Tests ---");
        test_operation(32'd100, 32'd50, 4'b0110, 32'd150, 1'b0, "addu(100, 50)");
        test_operation(32'hFFFFFFFF, 32'd1, 4'b0110, 32'h00000000, 1'b1, "addu(0xFFFFFFFF, 1) [wrap]");

        // Test SUBU (4'b0111)
        $display("\n--- SUBU Tests ---");
        test_operation(32'd20, 32'd8, 4'b0111, 32'd12, 1'b0, "subu(20, 8)");
        test_operation(32'd0, 32'd1, 4'b0111, 32'hFFFFFFFF, 1'b0, "subu(0, 1) [wrap]");

        $display("\n===== ALU Test Complete =====\n");
        $finish;
    end

endmodule
