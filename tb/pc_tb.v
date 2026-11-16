// Program Counter testbench.
// Verifies synchronous reset, next-PC loading, and reset priority.

`timescale 1ns/1ps

module pc_tb;

    reg        clk;
    reg        reset;
    reg [31:0] next_pc;
    wire [31:0] pc_value;
    integer fail_count;

    pc uut (
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .pc(pc_value)
    );

    always #5 clk = ~clk;

    task check_pc;
        input [31:0] expected;
        input [255:0] test_name;
        begin
            if (pc_value === expected) begin
                $display("PASS: %s -> pc=0x%08h", test_name, pc_value);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %s -> got pc=0x%08h, expected pc=0x%08h",
                         test_name, pc_value, expected);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        next_pc = 32'h12345678;
        fail_count = 0;

        $display("===== PC Unit Test =====");

        #1;
        if (pc_value !== 32'bx) begin
            fail_count = fail_count + 1;
            $display("FAIL: PC should not reset before a clock edge; got 0x%08h", pc_value);
        end else begin
            $display("PASS: reset is synchronous before the first clock edge");
        end

        @(posedge clk);
        #1;
        check_pc(32'b0, "synchronous reset");

        reset = 1'b0;
        next_pc = 32'h00000004;
        @(posedge clk);
        #1;
        check_pc(32'h00000004, "load first next_pc");

        next_pc = 32'h00000020;
        @(posedge clk);
        #1;
        check_pc(32'h00000020, "load second next_pc");

        reset = 1'b1;
        next_pc = 32'hFFFFFFFF;
        @(posedge clk);
        #1;
        check_pc(32'b0, "reset has priority over next_pc");

        if (fail_count != 0) begin
            $fatal(1, "PC test failed: %0d check(s)", fail_count);
        end

        $display("PASS: PC test completed with no failures");
        $finish;
    end

endmodule