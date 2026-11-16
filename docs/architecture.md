# Architecture and Datapath

This chapter explains how one instruction travels through the processor. The
goal is not only to describe what the modules do, but also to show why the
connections exist.

## The top-level machine

`rtl/mips32_cpu.v` instantiates five logical areas:

```text
                 +------------------+
        pc ---->| instruction      |
         |      | memory           |---- instruction
         |      +------------------+
         v               |
   +-----------+         v
   | next-PC   |<---- control unit
   | selection |         |
   +-----------+         v
         ^        +-------------+
         |        | datapath    |---- data-memory address
         |        |             |---- data-memory write data
         |        +-------------+
         |               ^
         |               |
         +---------------+
                         |
                    data memory
```

The datapath owns the register file and ALU. The top-level module keeps
instruction memory and data memory as separate blocks and connects their
interfaces to the datapath.

## Clocked state versus combinational logic

It is useful to classify every block before reading its Verilog:

| Block | State? | Main behavior |
| --- | --- | --- |
| PC | Yes | Loads `next_pc` on a rising edge |
| Register file | Yes | Writes one register on a rising edge; reads are asynchronous |
| Data memory | Yes | Writes on a rising edge; reads are combinational |
| Instruction memory | Yes in simulation | Contents are initialized once; reads are combinational |
| ALU | No | Produces a result from current inputs |
| Control unit | No | Decodes the current instruction |
| Datapath muxes/adders | No | Select operands, write-back, and next PC |

In a single-cycle design, the PC and other state elements change only at the
clock boundary. Everything needed to calculate the next state is evaluated
during the current cycle.

## Instruction fields

Every instruction is 32 bits:

```text
31             26 25       21 20       16 15       11 10        6 5       0
+----------------+-----------+-----------+-----------+-----------+---------+
| opcode         | rs        | rt        | rd        | shamt     | funct   |
+----------------+-----------+-----------+-----------+-----------+---------+
```

Not every format uses every field:

- R-type uses `rs`, `rt`, `rd`, `shamt`, and `funct`.
- I-type uses `rs`, `rt`, and the 16-bit immediate.
- J-type uses the 26-bit jump target.

The datapath reads `instruction[25:21]` and `instruction[20:16]` as the two
register-file addresses. The control unit receives `instruction[31:26]` and
`instruction[5:0]`.

## Fetch and PC selection

The normal next address is:

```text
PC + 4
```

The datapath calculates three alternatives:

```text
sequential = PC + 4
branch     = PC + 4 + (sign_extended_immediate << 2)
jump       = {PC + 4[31:28], instruction[25:0], 2'b00}
```

For `jr`, the next PC comes directly from register `rs`. The priority in the
current RTL is:

1. `jr`
2. `j` or `jal`
3. a taken conditional branch
4. `PC + 4`

The jump address uses the upper four bits of `PC + 4`, matching the usual
MIPS pseudo-direct jump construction. All instruction addresses are expected
to be word-aligned.

## Decode and control

The control unit converts the opcode and, for R-type instructions, the
function field into signals such as:

- `reg_dst`: choose `rd` instead of `rt` as the destination.
- `alu_src`: choose the immediate instead of register `rt` for ALU input B.
- `mem_to_reg`: choose data memory instead of the ALU for write-back.
- `reg_write`: enable the register-file write port.
- `mem_read` and `mem_write`: control data-memory access.
- `branch` and `branch_ne`: select equality or inequality branch behavior.
- `jump`, `jal`, and `jr`: select control-flow behavior.
- `alu_op`: select the ALU operation.

The decode block assigns safe values before its `case` statement. This avoids
unintended latches and makes unsupported instructions inert.

## Register operands and immediate values

The register file produces `register_data1` from `rs` and `register_data2`
from `rt`. The ALU's second operand is selected by `alu_src`:

```text
alu_b = alu_src ? immediate : register_data2
```

Immediate formation depends on the instruction:

- `addi`, `slti`, loads, stores, and branches sign-extend the immediate.
- `andi`, `ori`, and `xori` zero-extend it.
- `lui` places the immediate in bits 31 through 16 and clears bits 15
  through 0.

For branches, the already formed immediate is shifted left by two before
being added to `PC + 4`.

## ALU and comparisons

The ALU supports add, subtract, bitwise AND/OR/XOR, signed less-than, and
logical left shift. The `zero` output is true when the ALU result is zero.

Branches reuse subtraction:

```text
rs - rt == 0  -> equal
rs - rt != 0  -> not equal
```

The `branch_ne` signal tells the datapath whether to use `zero` directly
(`beq`) or invert it (`bne`).

## Write-back

The destination register is selected as follows:

```text
jal ? 31 : (reg_dst ? rd : rt)
```

The value written is selected as follows:

```text
jal       ? PC + 4 :
mem_to_reg ? data-memory read data :
             ALU result
```

This gives the three normal write-back paths:

- R-type and ALU-immediate instructions write the ALU result.
- `lw` writes the value returned by data memory.
- `jal` writes the return address to `$ra` (register 31).

`sw`, branches, jumps, and `jr` do not write a general-purpose register.

## Load and store timing

For `sw`, the ALU calculates:

```text
effective address = register[rs] + sign_extended_offset
```

The second register operand is sent to data memory as write data. The memory
stores it on the next rising edge.

For `lw`, the same address calculation occurs. Data memory produces its read
value combinationally, and the register file captures that value at the
rising edge.

## Reset behavior

Reset is synchronous and active high. On a rising edge with reset asserted:

- the PC becomes zero;
- all registers become zero;
- all data-memory words become zero.

Instruction memory is initialized at simulation start, rather than reset
through the clock. This is appropriate for a read-only program memory in
these educational simulations.
