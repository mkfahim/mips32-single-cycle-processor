// Top-level MIPS32 single-cycle CPU.
// Connects the program counter, instruction memory, control unit, datapath,
// and data memory into one clocked processor.

module mips32_cpu #(
    parameter integer IM_ADDR_WIDTH = 8,
    parameter integer DM_ADDR_WIDTH = 8,
    parameter IM_INIT_FILE = "",
    parameter DM_INIT_FILE = ""
) (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc
);

    wire [31:0] next_pc;
    wire [31:0] instruction;
    wire [31:0] data_mem_read_data;
    wire [31:0] data_mem_address;
    wire [31:0] data_mem_write_data;
    wire        data_mem_read;
    wire        data_mem_write;
    wire        reg_dst, alu_src, mem_to_reg, reg_write;
    wire        mem_read, mem_write, branch, branch_ne, jump, jal, jr;
    wire [3:0]  alu_op;

    pc pc_unit (
        .clk(clk), .reset(reset), .next_pc(next_pc), .pc(pc)
    );

    instruction_memory #(
        .ADDR_WIDTH(IM_ADDR_WIDTH), .INIT_FILE(IM_INIT_FILE)
    ) instruction_memory_unit (
        .address(pc), .instruction(instruction)
    );

    control_unit control_unit_unit (
        .opcode(instruction[31:26]), .funct(instruction[5:0]),
        .reg_dst(reg_dst), .alu_src(alu_src), .mem_to_reg(mem_to_reg),
        .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
        .branch(branch), .branch_ne(branch_ne), .jump(jump), .jal(jal), .jr(jr), .alu_op(alu_op)
    );

    datapath datapath_unit (
        .clk(clk), .reset(reset), .pc(pc), .instruction(instruction),
        .data_mem_read_data(data_mem_read_data), .reg_dst(reg_dst),
        .alu_src(alu_src), .mem_to_reg(mem_to_reg), .reg_write(reg_write),
        .mem_read(mem_read), .mem_write(mem_write), .branch(branch),
        .branch_ne(branch_ne), .jump(jump), .jal(jal), .jr(jr), .alu_op(alu_op),
        .next_pc(next_pc), .data_mem_address(data_mem_address),
        .data_mem_write_data(data_mem_write_data), .data_mem_read(data_mem_read),
        .data_mem_write(data_mem_write)
    );

    data_memory #(
        .ADDR_WIDTH(DM_ADDR_WIDTH), .INIT_FILE(DM_INIT_FILE)
    ) data_memory_unit (
        .clk(clk), .reset(reset), .mem_read(data_mem_read),
        .mem_write(data_mem_write), .address(data_mem_address),
        .write_data(data_mem_write_data), .read_data(data_mem_read_data)
    );

endmodule