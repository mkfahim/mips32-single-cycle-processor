// Control Unit for MIPS32 Single-Cycle Processor
//
// Decodes MIPS opcode and funct fields to generate control signals
// for the single-cycle datapath.
//
// Supported Instructions:
//   R-type: add, sub, and, or, xor, slt
//   I-type: addi, andi, ori, slti, lw, sw, beq, bne
//   J-type: j, jal

module control_unit (
    input  wire [5:0]  opcode,      // MIPS opcode field (bits 31:26)
    input  wire [5:0]  funct,       // MIPS funct field (bits 5:0) for R-type

    // Control signals
    output reg         reg_dst,     // 1=rd (R-type), 0=rt (I-type)
    output reg         alu_src,     // 1=immediate, 0=register
    output reg         mem_to_reg,  // 1=data_mem, 0=ALU result
    output reg         reg_write,   // 1=write to register file
    output reg         mem_read,    // 1=read from data memory
    output reg         mem_write,   // 1=write to data memory
    output reg         branch,      // 1=beq/bne branch
    output reg         jump,        // 1=j/jal jump
    output reg         jal,         // 1=jal (write return address)
    output reg [3:0]   alu_op       // ALU operation code
);

    // MIPS Opcodes
    localparam OP_RTYPE  = 6'b000000;  // R-type instructions
    localparam OP_ADDI   = 6'b001000;  // addi
    localparam OP_ANDI   = 6'b001100;  // andi
    localparam OP_ORI    = 6'b001101;  // ori
    localparam OP_SLTI   = 6'b001010;  // slti
    localparam OP_LW     = 6'b100011;  // lw
    localparam OP_SW     = 6'b101011;  // sw
    localparam OP_BEQ    = 6'b000100;  // beq
    localparam OP_BNE    = 6'b000101;  // bne
    localparam OP_J      = 6'b000010;  // j
    localparam OP_JAL    = 6'b000011;  // jal

    // MIPS R-type function codes
    localparam FUNCT_ADD = 6'b100000;  // add
    localparam FUNCT_SUB = 6'b100010;  // sub
    localparam FUNCT_AND = 6'b100100;  // and
    localparam FUNCT_OR  = 6'b100101;  // or
    localparam FUNCT_XOR = 6'b100110;  // xor
    localparam FUNCT_SLT = 6'b101010;  // slt

    // ALU operation codes (must match ALU module)
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLT  = 4'b0101;

    // Combinational control logic
    always @(*) begin
        // Default safe values for unsupported instructions
        reg_dst    = 1'b0;
        alu_src    = 1'b0;
        mem_to_reg = 1'b0;
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        jal        = 1'b0;
        alu_op     = 4'b0000;

        case (opcode)
            OP_RTYPE: begin
                // R-type instruction: decode funct
                reg_dst   = 1'b1;  // Write to rd
                reg_write = 1'b1;  // Write to register file
                alu_src   = 1'b0;  // ALU source is register

                case (funct)
                    FUNCT_ADD: alu_op = ALU_ADD;
                    FUNCT_SUB: alu_op = ALU_SUB;
                    FUNCT_AND: alu_op = ALU_AND;
                    FUNCT_OR:  alu_op = ALU_OR;
                    FUNCT_XOR: alu_op = ALU_XOR;
                    FUNCT_SLT: alu_op = ALU_SLT;
                    default:   reg_write = 1'b0;  // Unsupported funct -> no write
                endcase
            end

            OP_ADDI: begin
                // addi: Add Immediate (sign-extended at datapath)
                reg_dst   = 1'b0;  // Write to rt
                alu_src   = 1'b1;  // ALU source is immediate
                reg_write = 1'b1;
                alu_op    = ALU_ADD;
            end

            OP_ANDI: begin
                // andi: AND Immediate (zero-extended at datapath)
                reg_dst   = 1'b0;
                alu_src   = 1'b1;
                reg_write = 1'b1;
                alu_op    = ALU_AND;
            end

            OP_ORI: begin
                // ori: OR Immediate (zero-extended at datapath)
                reg_dst   = 1'b0;
                alu_src   = 1'b1;
                reg_write = 1'b1;
                alu_op    = ALU_OR;
            end

            OP_SLTI: begin
                // slti: Set Less Than Immediate (sign-extended at datapath)
                reg_dst   = 1'b0;
                alu_src   = 1'b1;
                reg_write = 1'b1;
                alu_op    = ALU_SLT;
            end

            OP_LW: begin
                // lw: Load Word
                reg_dst    = 1'b0;  // write to rt
                alu_src    = 1'b1;  // use immediate for address calc
                mem_to_reg = 1'b1;  // write memory data back
                reg_write  = 1'b1;  // write register
                mem_read   = 1'b1;  // enable memory read
                alu_op     = ALU_ADD;  // address = base + offset
            end

            OP_SW: begin
                // sw: Store Word
                alu_src   = 1'b1;  // use immediate for address calc
                mem_write = 1'b1;  // enable memory write
                alu_op    = ALU_ADD; // address = base + offset
            end

            OP_BEQ: begin
                // beq: Branch if Equal
                alu_src = 1'b0; // compare registers
                branch  = 1'b1;
                alu_op  = ALU_SUB; // perform subtraction to set zero
            end

            OP_BNE: begin
                // bne: Branch if Not Equal
                alu_src = 1'b0;
                branch  = 1'b1;
                alu_op  = ALU_SUB;
            end

            OP_J: begin
                jump = 1'b1;
            end

            OP_JAL: begin
                jump      = 1'b1;
                jal       = 1'b1;
                reg_write = 1'b1; // write return address to $ra (handled in datapath)
            end

            default: begin
                // unsupported opcode -> keep safe defaults
            end
        endcase
    end

endmodule
