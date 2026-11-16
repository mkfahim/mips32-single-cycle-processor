# Instruction Set and Encodings

The processor implements a deliberately small MIPS32 subset. The tables below
describe the fields used by the RTL and the behavior that can be observed in
the testbenches.

## Register names used in examples

The RTL addresses registers by number. Common names used in comments and
examples are:

| Number | Name | Typical role |
| ---: | --- | --- |
| 0 | `$zero` | Constant zero |
| 8–15 | `$t0`–`$t7` | Temporary registers |
| 24–25 | `$t8`–`$t9` | More temporaries |
| 31 | `$ra` | Return address |

## R-type format

```text
opcode=0 | rs | rt | rd | shamt | funct
```

R-type instructions write `rd`, except `jr`, which uses `rs` as a jump
address and does not write a register.

| Instruction | Funct | Operation |
| --- | --- | --- |
| `add rd, rs, rt` | `100000` | `rd = rs + rt` |
| `sub rd, rs, rt` | `100010` | `rd = rs - rt` |
| `and rd, rs, rt` | `100100` | `rd = rs & rt` |
| `or rd, rs, rt` | `100101` | `rd = rs \| rt` |
| `xor rd, rs, rt` | `100110` | `rd = rs ^ rt` |
| `slt rd, rs, rt` | `101010` | `rd = signed(rs) < signed(rt)` |
| `sll rd, rt, shamt` | `000000` | `rd = rt << shamt` |
| `jr rs` | `001000` | `PC = rs` |

`sll` uses `rt` as its value input and the five-bit `shamt` field as the
shift amount. Its `rs` field is not used.

## I-type format

```text
opcode | rs | rt | immediate[15:0]
```

For arithmetic and logical instructions, `rt` is the destination. For loads,
`rt` is also the destination; for stores, `rt` supplies the value written to
memory.

| Instruction | Opcode | Immediate rule | Operation |
| --- | --- | --- | --- |
| `addi rt, rs, imm` | `001000` | Sign-extended | `rt = rs + imm` |
| `andi rt, rs, imm` | `001100` | Zero-extended | `rt = rs & imm` |
| `ori rt, rs, imm` | `001101` | Zero-extended | `rt = rs \| imm` |
| `xori rt, rs, imm` | `001110` | Zero-extended | `rt = rs ^ imm` |
| `lui rt, imm` | `001111` | Upper placement | `rt = imm << 16` |
| `slti rt, rs, imm` | `001010` | Sign-extended | `rt = signed(rs) < signed(imm)` |
| `lw rt, offset(rs)` | `100011` | Sign-extended | `rt = memory[rs + offset]` |
| `sw rt, offset(rs)` | `101011` | Sign-extended | `memory[rs + offset] = rt` |
| `beq rs, rt, offset` | `000100` | Sign-extended, shifted 2 | Branch if equal |
| `bne rs, rt, offset` | `000101` | Sign-extended, shifted 2 | Branch if not equal |

The branch target is:

```text
PC + 4 + (sign_extended_offset << 2)
```

The current memory model only supports aligned word accesses. An address
whose bottom two bits are not zero is treated as invalid.

## J-type format

```text
opcode | target[25:0]
```

| Instruction | Opcode | Operation |
| --- | --- | --- |
| `j target` | `000010` | Jump to pseudo-direct target |
| `jal target` | `000011` | Save `PC + 4` in `$ra`, then jump |

The jump address is formed as:

```text
{PC + 4[31:28], target[25:0], 2'b00}
```

This implementation does not model a MIPS branch delay slot. The instruction
at the selected target is the next instruction executed.

## Control encodings

The ALU control values used by `control_unit.v` are:

| Value | Operation |
| --- | --- |
| `0000` | Add |
| `0001` | Subtract |
| `0010` | AND |
| `0011` | OR |
| `0100` | XOR |
| `0101` | Signed less-than |
| `1000` | Shift left logical |

The values are an internal interface between the control unit and ALU; they
are not instruction encodings.

## Unsupported instructions

An unrecognized opcode, or an unrecognized R-type function code, receives
safe defaults from the control unit. In practice this means no register
write, no memory write, no branch, and no jump. The PC therefore advances by
four. This is useful for deterministic learning simulations, but it is not a
replacement for a real illegal-instruction exception unit.
