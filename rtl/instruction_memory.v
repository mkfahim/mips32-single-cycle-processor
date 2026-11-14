// Read-only instruction memory for the MIPS32 single-cycle processor.
//
// The PC supplies a byte address. Instructions must be word-aligned; an
// unaligned or out-of-range address returns a safe zero instruction.
// Memory contents may optionally be initialized from a hexadecimal file.

module instruction_memory #(
    parameter integer ADDR_WIDTH = 8,
    parameter INIT_FILE = ""
) (
    input  wire [31:0] address,
    output reg  [31:0] instruction
);

    localparam integer DEPTH = 1 << ADDR_WIDTH;
    reg [31:0] memory [0:DEPTH-1];
    integer index;

    initial begin
        for (index = 0; index < DEPTH; index = index + 1) begin
            memory[index] = 32'b0;
        end
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, memory);
        end
    end

    always @(*) begin
        if (address[1:0] != 2'b00) begin
            instruction = 32'b0;
        end else if (|address[31:ADDR_WIDTH+2]) begin
            instruction = 32'b0;
        end else begin
            instruction = memory[address[ADDR_WIDTH+1:2]];
        end
    end

endmodule