// Data memory for the MIPS32 single-cycle processor.
//
// Reads are combinational. Writes and reset occur on the rising clock edge.
// Only aligned addresses within the configured word range are accessed.

module data_memory #(
    parameter integer ADDR_WIDTH = 8,
    parameter INIT_FILE = ""
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
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

    wire valid_address = (address[1:0] == 2'b00) &&
                         !(|address[31:ADDR_WIDTH+2]);

    always @(posedge clk) begin
        if (reset) begin
            for (index = 0; index < DEPTH; index = index + 1) begin
                memory[index] <= 32'b0;
            end
        end else if (mem_write && valid_address) begin
            memory[address[ADDR_WIDTH+1:2]] <= write_data;
        end
    end

    always @(*) begin
        if (mem_read && valid_address) begin
            read_data = memory[address[ADDR_WIDTH+1:2]];
        end else begin
            read_data = 32'b0;
        end
    end

endmodule