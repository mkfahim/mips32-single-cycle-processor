// Register File for MIPS32 Single-Cycle Processor
//
// 32 registers × 32 bits
// Two asynchronous read ports (combinational)
// One synchronous write port (positive-edge triggered)
// Register 0 ($zero) is hard-wired to zero; writes ignored

module register_file (
    input  wire        clk,           // System clock (positive edge)
    input  wire        reset,         // Synchronous active-high reset
    
    // Read port 1 (asynchronous/combinational)
    input  wire [4:0]  read_addr1,    // Address for first read port
    output wire [31:0] read_data1,    // Data from first read port
    
    // Read port 2 (asynchronous/combinational)
    input  wire [4:0]  read_addr2,    // Address for second read port
    output wire [31:0] read_data2,    // Data from second read port
    
    // Write port (synchronous)
    input  wire [4:0]  write_addr,    // Address for write port
    input  wire [31:0] write_data,    // Data to write
    input  wire        write_enable   // Write enable signal
);

    // 32 × 32-bit register storage
    reg [31:0] registers [0:31];

    // Synchronous write on positive clock edge
    always @(posedge clk) begin
        if (reset) begin
            // Reset all registers to zero
            integer i;
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (write_enable && write_addr != 5'b00000) begin
            // Write to register only if not $zero (register 0)
            registers[write_addr] <= write_data;
        end
        // If write_addr == 0, write is silently ignored
    end

    // Asynchronous (combinational) read port 1
    // $zero always reads as 0; other registers read their stored value
    assign read_data1 = (read_addr1 == 5'b00000) ? 32'b0 : registers[read_addr1];

    // Asynchronous (combinational) read port 2
    // $zero always reads as 0; other registers read their stored value
    assign read_data2 = (read_addr2 == 5'b00000) ? 32'b0 : registers[read_addr2];

endmodule
