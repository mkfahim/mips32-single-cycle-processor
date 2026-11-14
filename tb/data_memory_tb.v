// Data memory testbench.
// Verifies synchronous reset, clocked writes, combinational reads, and
// safe behavior for disabled, unaligned, and out-of-range accesses.

`timescale 1ns/1ps

module data_memory_tb;

    reg        clk;
    reg        reset;
    reg        mem_read;
    reg        mem_write;
    reg [31:0] address;
    reg [31:0] write_data;
    wire [31:0] read_data;
    integer fail_count;

    data_memory #(
        .ADDR_WIDTH(4)
    ) uut (
        .clk(clk),
        .reset(reset),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .address(address),
        .write_data(write_data),
        .read_data(read_data)
    );

    always #5 clk = ~clk;

    task check_read;
        input [31:0] address_value;
        input [31:0] expected;
        input [255:0] test_name;
        begin
            address = address_value;
            mem_read = 1'b1;
            #1;
            if (read_data === expected) begin
                $display("PASS: %s -> read_data=0x%08h", test_name, read_data);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %s -> got 0x%08h, expected 0x%08h",
                         test_name, read_data, expected);
            end
            mem_read = 1'b0;
        end
    endtask

    task write_word;
        input [31:0] address_value;
        input [31:0] value;
        begin
            address = address_value;
            write_data = value;
            mem_write = 1'b1;
            @(posedge clk);
            #1;
            mem_write = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        mem_read = 1'b0;
        mem_write = 1'b0;
        address = 32'b0;
        write_data = 32'b0;
        fail_count = 0;

        $display("===== Data Memory Unit Test =====");

        @(posedge clk);
        #1;
        reset = 1'b0;
        check_read(32'h00000000, 32'h00000000, "reset clears address 0");

        write_word(32'h00000000, 32'hDEADBEEF);
        check_read(32'h00000000, 32'hDEADBEEF, "write and read address 0");

        write_word(32'h00000004, 32'h12345678);
        check_read(32'h00000004, 32'h12345678, "write and read address 4");
        check_read(32'h00000000, 32'hDEADBEEF, "independent words retain values");

        address = 32'h00000004;
        mem_read = 1'b0;
        #1;
        if (read_data !== 32'b0) begin
            fail_count = fail_count + 1;
            $display("FAIL: disabled read should return zero, got 0x%08h", read_data);
        end else begin
            $display("PASS: disabled read returns zero");
        end

        write_word(32'h00000008, 32'hAAAAAAAA);
        address = 32'h00000008;
        write_data = 32'hBBBBBBBB;
        mem_write = 1'b0;
        @(posedge clk);
        #1;
        check_read(32'h00000008, 32'hAAAAAAAA, "disabled write does not change memory");

        check_read(32'h00000002, 32'h00000000, "unaligned address returns zero");
        check_read(32'h00000040, 32'h00000000, "out-of-range address returns zero");

        reset = 1'b1;
        @(posedge clk);
        #1;
        reset = 1'b0;
        check_read(32'h00000000, 32'h00000000, "second reset clears prior data");
        check_read(32'h00000004, 32'h00000000, "second reset clears all data");

        if (fail_count != 0) begin
            $fatal(1, "Data memory test failed: %0d check(s)", fail_count);
        end

        $display("PASS: Data memory test completed with no failures");
        $finish;
    end

endmodule