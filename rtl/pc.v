// Program Counter for the MIPS32 single-cycle processor.
//
// The PC loads next_pc on each rising clock edge. Reset is synchronous
// and active high, and resets the PC to address zero.

module pc (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] next_pc,
    output reg  [31:0] pc
);

    always @(posedge clk) begin
        if (reset) begin
            pc <= 32'b0;
        end else begin
            pc <= next_pc;
        end
    end

endmodule