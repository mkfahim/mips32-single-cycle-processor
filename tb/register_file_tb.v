// Register File Testbench for MIPS32 Single-Cycle Processor
//
// Tests:
// - Reset behavior
// - Normal write/read
// - Simultaneous reads
// - Writes to $zero are blocked
// - $zero always reads as zero
// - Representative values

`timescale 1ns / 1ps

module register_file_tb;

    // Testbench signals
    reg        clk;
    reg        reset;
    reg  [4:0] read_addr1;
    reg  [4:0] read_addr2;
    wire [31:0] read_data1;
    wire [31:0] read_data2;
    reg  [4:0] write_addr;
    reg  [31:0] write_data;
    reg        write_enable;

    // Instantiate register file
    register_file uut (
        .clk(clk),
        .reset(reset),
        .read_addr1(read_addr1),
        .read_data1(read_data1),
        .read_addr2(read_addr2),
        .read_data2(read_data2),
        .write_addr(write_addr),
        .write_data(write_data),
        .write_enable(write_enable)
    );

    // Clock generation: 10ns period
    always begin
        clk = 1'b0;
        #5;
        clk = 1'b1;
        #5;
    end

    // Test helper: wait for clock edge
    task wait_clock;
        @(posedge clk);
        #1;  // Small delay after clock edge for setup
    endtask

    // Test helper: write a value to a register
    task write_register(
        input [4:0]  addr,
        input [31:0] data,
        input string desc
    );
        begin
            write_addr = addr;
            write_data = data;
            write_enable = 1'b1;
            wait_clock;
            write_enable = 1'b0;
            $display("  WRITE: reg[%d] <= 0x%08h  (%s)", addr, data, desc);
        end
    endtask

    // Test helper: verify a register value
    task verify_register(
        input [4:0]  addr,
        input [31:0] expected,
        input string desc
    );
        begin
            read_addr1 = addr;
            #1;  // Combinational read
            if (read_data1 === expected) begin
                $display("✓ PASS: reg[%d] = 0x%08h  (%s)", addr, read_data1, desc);
            end else begin
                $display("✗ FAIL: reg[%d] expected 0x%08h, got 0x%08h  (%s)", addr, expected, read_data1, desc);
            end
        end
    endtask

    // Main test sequence
    initial begin
        $display("===== Register File Unit Test =====\n");

        // Initialize signals
        reset = 1'b1;
        clk = 1'b0;
        write_enable = 1'b0;
        read_addr1 = 5'b0;
        read_addr2 = 5'b0;
        write_addr = 5'b0;
        write_data = 32'b0;

        // Test 1: Reset behavior
        $display("--- Reset Test ---");
        wait_clock;
        reset = 1'b0;
        wait_clock;
        
        verify_register(5'd0, 32'h00000000, "reset: $zero must be 0");
        verify_register(5'd1, 32'h00000000, "reset: $at must be 0");
        verify_register(5'd31, 32'h00000000, "reset: $ra must be 0");

        // Test 2: Basic write and read
        $display("\n--- Basic Write/Read Test ---");
        write_register(5'd1, 32'h12345678, "write to reg[1]");
        verify_register(5'd1, 32'h12345678, "read from reg[1]");

        write_register(5'd2, 32'hDEADBEEF, "write to reg[2]");
        verify_register(5'd2, 32'hDEADBEEF, "read from reg[2]");

        // Test 3: Simultaneous reads
        $display("\n--- Simultaneous Read Test ---");
        write_register(5'd3, 32'hAAAAAAAA, "write to reg[3]");
        write_register(5'd4, 32'h55555555, "write to reg[4]");
        
        read_addr1 = 5'd3;
        read_addr2 = 5'd4;
        #1;
        if (read_data1 === 32'hAAAAAAAA && read_data2 === 32'h55555555) begin
            $display("✓ PASS: simultaneous reads (reg[3]=0x%08h, reg[4]=0x%08h)", read_data1, read_data2);
        end else begin
            $display("✗ FAIL: simultaneous reads (got reg[3]=0x%08h, reg[4]=0x%08h)", read_data1, read_data2);
        end

        // Test 4: $zero behavior (always zero)
        $display("\n--- $zero Register Test ---");
        verify_register(5'd0, 32'h00000000, "$zero always reads as zero (initial)");
        
        write_register(5'd0, 32'hFFFFFFFF, "attempt write to $zero with 0xFFFFFFFF");
        verify_register(5'd0, 32'h00000000, "$zero still reads as zero (write ignored)");
        
        write_register(5'd0, 32'h12345678, "attempt write to $zero with 0x12345678");
        verify_register(5'd0, 32'h00000000, "$zero still reads as zero (write ignored)");

        // Test 5: Representative values
        $display("\n--- Representative Values Test ---");
        write_register(5'd5, 32'h00000000, "write zero to reg[5]");
        verify_register(5'd5, 32'h00000000, "read zero from reg[5]");

        write_register(5'd6, 32'h7FFFFFFF, "write MAX_INT (0x7FFFFFFF) to reg[6]");
        verify_register(5'd6, 32'h7FFFFFFF, "read MAX_INT from reg[6]");

        write_register(5'd7, 32'h80000000, "write MIN_INT (0x80000000) to reg[7]");
        verify_register(5'd7, 32'h80000000, "read MIN_INT from reg[7]");

        write_register(5'd8, 32'hFFFFFFFF, "write -1 (0xFFFFFFFF) to reg[8]");
        verify_register(5'd8, 32'hFFFFFFFF, "read -1 from reg[8]");

        // Test 6: Write to various registers
        $display("\n--- Write to Various Registers ---");
        write_register(5'd10, 32'hCAFEBABE, "write to reg[10]");
        write_register(5'd20, 32'hDEADC0DE, "write to reg[20]");
        write_register(5'd31, 32'hBEEFBEEF, "write to reg[31]");

        verify_register(5'd10, 32'hCAFEBABE, "read from reg[10]");
        verify_register(5'd20, 32'hDEADC0DE, "read from reg[20]");
        verify_register(5'd31, 32'hBEEFBEEF, "read from reg[31]");

        // Test 7: Multiple writes to same register
        $display("\n--- Multiple Writes to Same Register ---");
        write_register(5'd15, 32'h11111111, "first write to reg[15]");
        verify_register(5'd15, 32'h11111111, "read after first write");

        write_register(5'd15, 32'h22222222, "second write to reg[15]");
        verify_register(5'd15, 32'h22222222, "read after second write");

        write_register(5'd15, 32'h33333333, "third write to reg[15]");
        verify_register(5'd15, 32'h33333333, "read after third write");

        // Test 8: Read from unwritten register (should be zero from reset)
        $display("\n--- Read from Unwritten Register ---");
        verify_register(5'd25, 32'h00000000, "read from unwritten reg[25] (should be zero)");

        $display("\n===== Register File Test Complete =====\n");
        $finish;
    end

endmodule
