// ALU (Arithmetic Logic Unit) for MIPS32 Single-Cycle Processor
//
// Supports:
//   - R-type operations: add, sub, and, or, xor, slt
//   - I-type operations: addi, andi, ori, slti
//
// ALU Control Encoding:
//   0000: add
//   0001: sub
//   0010: and
//   0011: or
//   0100: xor
//   0101: slt (set on less than, signed)
//   0110: addu (add unsigned)
//   0111: subu (sub unsigned)

module alu (
    input  wire [31:0] a,           // First operand
    input  wire [31:0] b,           // Second operand
    input  wire [3:0]  alu_control, // ALU operation code
    output reg  [31:0] result,      // ALU result
    output wire        zero         // Zero flag (result == 0)
);

    // Combinational logic for ALU operations
    always @(*) begin
        case (alu_control)
            4'b0000: result = a + b;           // add / addi
            4'b0001: result = a - b;           // sub
            4'b0010: result = a & b;           // and / andi
            4'b0011: result = a | b;           // or / ori
            4'b0100: result = a ^ b;           // xor / xori
            4'b0101: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;  // slt (signed)
            4'b0110: result = a + b;           // addu (same as add for 32-bit)
            4'b0111: result = a - b;           // subu (same as sub for 32-bit)
            default: result = 32'd0;           // Default to zero
        endcase
    end

    // Zero flag: true when result is all zeros
    assign zero = (result == 32'b0);

endmodule
