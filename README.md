# MIPS32 Single-Cycle Processor in Verilog

This repository is a small, readable implementation of a MIPS32-style
single-cycle processor. It is designed as a learning project: each hardware
block is kept visible, the interfaces are intentionally simple, and the
testbenches demonstrate how the blocks work together.

The processor is not intended to be a complete commercial MIPS
implementation. It implements a focused instruction subset and uses
simulation-friendly memories so that the complete fetch, decode, execute,
memory, and write-back path can be studied in one place.

## What “single-cycle” means here

Every instruction completes in one clock period:

1. The program counter (PC) supplies an instruction address.
2. Instruction memory returns the instruction.
3. The control unit decodes the opcode and function fields.
4. The register file supplies source operands.
5. The ALU performs an operation or calculates an address.
6. Data memory is read or written when required.
7. The result is written back to the register file at the clock edge.
8. The next PC is selected for the following cycle.

The combinational work happens between rising clock edges. The PC, register
file writes, and data-memory writes are clocked state changes.

## Current instruction subset

The supported instructions are:

| Class | Instructions |
| --- | --- |
| R-type | `add`, `sub`, `and`, `or`, `xor`, `slt`, `sll`, `jr` |
| I-type | `addi`, `andi`, `ori`, `xori`, `lui`, `slti`, `lw`, `sw`, `beq`, `bne` |
| J-type | `j`, `jal` |

Instruction encodings, immediate rules, and the current implementation
limitations are described in [`docs/instruction-set.md`](docs/instruction-set.md).

## Repository map

```text
rtl/
  alu.v                 Arithmetic and logic operations
  control_unit.v        Opcode/funct decoding and control signals
  data_memory.v         Combinational-read, clocked-write data memory
  datapath.v            Register, ALU, write-back, and next-PC datapath
  instruction_memory.v  Read-only instruction memory
  mips32_cpu.v          Top-level processor
  pc.v                  Program counter
  register_file.v       32-register file with two async reads

tb/
  *_tb.v                Unit, datapath, and end-to-end testbenches

docs/
  architecture.md       Hardware organization and instruction flow
  instruction-set.md    Encodings and supported behavior
  verification.md       Simulation and CI strategy
  learning-notes.md     Design decisions and suggested experiments
```

The RTL is intentionally organized around the processor data path rather than
around a software-style abstraction layer. Reading `mips32_cpu.v` first gives
the top-level connections; reading `datapath.v` next shows how an instruction
flows through the machine.

## Requirements

For local simulation, install:

- Git
- Icarus Verilog with SystemVerilog-2012 support
- `vvp` (normally installed with Icarus Verilog)

Ubuntu/Debian:

```sh
sudo apt-get update
sudo apt-get install -y iverilog
```

## Run the complete CPU simulation

From the repository root:

```sh
iverilog -g2012 -o cpu_sim \
  tb/mips32_cpu_tb.v \
  rtl/mips32_cpu.v \
  rtl/pc.v \
  rtl/instruction_memory.v \
  rtl/data_memory.v \
  rtl/datapath.v \
  rtl/control_unit.v \
  rtl/register_file.v \
  rtl/alu.v

vvp cpu_sim
```

The testbench loads a small program directly into the instruction-memory
array. It then advances the clock and checks register values, memory values,
and PC transitions. A successful run ends with:

```text
PASS: CPU integration test completed with no failures
```

Generated simulation binaries are local artifacts and are ignored by the
repository's `.gitignore`.

## Run an individual unit test

For example, to test only the ALU:

```sh
iverilog -g2012 -o alu_sim tb/alu_tb.v rtl/alu.v
vvp alu_sim
```

The other unit tests follow the same pattern. The exact source lists used by
continuous integration are in [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

## Processor parameters

The top-level module is:

```verilog
mips32_cpu #(
    .IM_ADDR_WIDTH(8),
    .DM_ADDR_WIDTH(8),
    .IM_INIT_FILE(""),
    .DM_INIT_FILE("")
) cpu (
    .clk(clk),
    .reset(reset),
    .pc(pc)
);
```

`IM_ADDR_WIDTH` and `DM_ADDR_WIDTH` select the number of address-index bits.
Each memory contains `2**ADDR_WIDTH` 32-bit words. Because instructions and
data are words, the low two address bits are used for alignment and are not
part of the word index.

When an initialization filename is supplied, the memory uses Verilog
`$readmemh`. An empty filename leaves the memory zero-initialized. The
testbench can also initialize memories hierarchically, which is convenient
for small educational programs.

## Important behavioral conventions

### Reset

Reset is synchronous and active high:

- `pc.v` resets the PC to address `0` on a rising edge.
- `register_file.v` clears all 32 registers on a rising edge.
- `data_memory.v` clears all data words on a rising edge.

The testbenches therefore hold `reset` high across a clock edge before
executing the first instruction.

### Register file

The register file has two asynchronous read ports and one synchronous write
port. Register `$zero` always reads as zero, and writes to register zero are
ignored. Register `$ra` is register 31 and receives `PC + 4` for `jal`.

### Memory

Instruction and data addresses must be word-aligned. Invalid or out-of-range
addresses return zero on reads and are ignored on writes. Data-memory reads
are combinational; data-memory writes occur on the rising edge when
`mem_write` is asserted.

### Control safety

The control unit starts every decode with safe defaults. Unsupported opcodes
and unsupported R-type function codes do not write a register, access data
memory, branch, or jump.

## Suggested reading order

Readers who are new to processor design can follow this sequence:

1. Read this file to learn the vocabulary and repository layout.
2. Read `rtl/pc.v` and `rtl/register_file.v` to see sequential state.
3. Read `rtl/alu.v` to see pure combinational computation.
4. Read `rtl/control_unit.v` to connect instruction fields to controls.
5. Read `rtl/datapath.v` to follow operands, write-back, and PC selection.
6. Read `rtl/mips32_cpu.v` to see the complete wiring.
7. Run `tb/mips32_cpu_tb.v` and compare each instruction with the RTL.
8. Use the documentation chapters and suggested experiments to extend it.

## Scope and current limitations

This is a teaching implementation, so it deliberately leaves out features
that would distract from the single-cycle datapath:

- It has no pipeline, forwarding, hazard detection, cache, or exception unit.
- It does not implement coprocessors, interrupts, privileged modes, or delay
  slots.
- The instruction and data memories are simple simulation memories, not
  synthesizable memory-controller interfaces.
- The supported ISA is the subset listed above; unsupported instructions
  safely become no-operations rather than raising exceptions.
- Arithmetic overflow is not reported separately.

These are useful directions for future study, not bugs in the current
learning objective.

## Further documentation

- [Architecture and datapath](docs/architecture.md)
- [Instruction set and encodings](docs/instruction-set.md)
- [Verification and CI](docs/verification.md)
- [Learning notes and experiments](docs/learning-notes.md)

## License

See [`LICENSE`](LICENSE).
