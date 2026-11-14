// MIPS32 single-cycle datapath.
// Connects instruction fields, register file, ALU, write-back, memory
// interfaces, and next-PC selection. Control signals are supplied by the
// control unit; memories remain external to this module.

module datapath (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] pc,
    input  wire [31:0] instruction,
    input  wire [31:0] data_mem_read_data,
    input  wire        reg_dst,
    input  wire        alu_src,
    input  wire        mem_to_reg,
    input  wire        reg_write,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire        branch,
    input  wire        branch_ne,
    input  wire        jump,
    input  wire        jal,
    input  wire        jr,
    input  wire [3:0]  alu_op,
    output wire [31:0] next_pc,
    output wire [31:0] data_mem_address,
    output wire [31:0] data_mem_write_data,
    output wire        data_mem_read,
    output wire        data_mem_write
);

    wire [31:0] pc_plus4 = pc + 32'd4;
    wire [5:0] opcode = instruction[31:26];
    wire [31:0] immediate = (opcode == 6'b001111)
                          ? {instruction[15:0], 16'b0}
                          : ((opcode == 6'b001100 || opcode == 6'b001101 || opcode == 6'b001110)
                             ? {16'b0, instruction[15:0]}
                             : {{16{instruction[15]}}, instruction[15:0]});
    wire [31:0] branch_target = pc_plus4 + (immediate << 2);
    wire [31:0] jump_target = {pc_plus4[31:28], instruction[25:0], 2'b00};

    wire [31:0] register_data1;
    wire [31:0] register_data2;
    wire [31:0] alu_operand2 = alu_src ? immediate : register_data2;
    wire [31:0] alu_result;
    wire        alu_zero;
    wire [4:0]  write_register = jal ? 5'd31 : (reg_dst ? instruction[15:11] : instruction[20:16]);
    wire [31:0] write_data = jal ? pc_plus4 : (mem_to_reg ? data_mem_read_data : alu_result);
    wire        branch_taken = branch && (branch_ne ? !alu_zero : alu_zero);

    register_file rf (
        .clk(clk),
        .reset(reset),
        .read_addr1(instruction[25:21]),
        .read_data1(register_data1),
        .read_addr2(instruction[20:16]),
        .read_data2(register_data2),
        .write_addr(write_register),
        .write_data(write_data),
        .write_enable(reg_write)
    );

    alu alu_unit (
        .a(register_data1),
        .b(alu_operand2),
        .alu_control(alu_op),
        .result(alu_result),
        .zero(alu_zero)
    );

    assign data_mem_address = alu_result;
    assign data_mem_write_data = register_data2;
    assign data_mem_read = mem_read;
    assign data_mem_write = mem_write;

    assign next_pc = jr ? register_data1 :
                     (jump ? jump_target :
                     (branch_taken ? branch_target : pc_plus4));

endmodule