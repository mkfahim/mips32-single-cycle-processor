# MIPS32 Single-Cycle Processor in Verilog

> A visual, beginner-friendly journey from basic Verilog modules to a
> working CPU.

This repository presents a small MIPS32-style single-cycle processor in Verilog.
It is intended for readers who can read simple Verilog, such as an ALU, but are
still learning what a CPU, an instruction set, registers, memory, and a datapath
actually are.

Readers do **not** need previous knowledge of:

- MIPS or RISC-V assembly;
- CPU architecture;
- instruction encoding;
- pipelining;
- operating systems;
- FPGA or ASIC design.

The project uses an intentionally educational design. Readers can study the
small RTL modules, run the testbenches to see how each block behaves, and
connect textbook concepts to the actual files in `rtl/`.

---

## Table of contents

1. [Start here](#start-here)
2. [The big idea: what a CPU does](#the-big-idea-what-a-cpu-does)
3. [What does single-cycle mean?](#what-does-single-cycle-mean)
4. [The processor at a glance](#the-processor-at-a-glance)
5. [How one instruction travels](#how-one-instruction-travels)
6. [The repository as a book](#the-repository-as-a-book)
7. [The beginner learning path](#the-beginner-learning-path)
8. [The instruction formats](#the-instruction-formats)
9. [A complete `addi` walkthrough](#a-complete-addi-walkthrough)
10. [Loads, stores, branches, and jumps](#loads-stores-branches-and-jumps)
11. [Current instruction subset](#current-instruction-subset)
12. [Repository structure](#repository-structure)
13. [Run the processor](#run-the-processor)
14. [Understand the testbenches](#understand-the-testbenches)
15. [What this project does not cover](#what-this-project-does-not-cover)
16. [Further reading](#further-reading)
17. [References](#references)

---

## Start here

Readers who are completely new to CPUs should follow this order:

1. Read the short explanation in [The big idea](#the-big-idea-what-a-cpu-does).
2. Look at the [CPU overview](#the-processor-at-a-glance).
3. Read `rtl/alu.v` and run `tb/alu_tb.v`.
4. Learn state with `rtl/pc.v` and `rtl/register_file.v`.
5. Read the [beginner learning path](docs/beginner-roadmap.md).
6. Run the complete CPU simulation.
7. Read the [architecture chapter](docs/architecture.md) while following the
   wires in `rtl/datapath.v`.

Readers should not try to memorize every control signal on the first reading.
The goal is to understand the journey of one instruction. Once that journey is
clear, the individual Verilog signals become much easier to recognize.

---

## The big idea: what a CPU does

A CPU can be understood as repeatedly performing this simple loop:

```text
1. Find the next instruction.
2. Understand what the instruction says.
3. Read the values it needs.
4. Calculate a result or an address.
5. Read or write memory if required.
6. Save the result.
7. Decide where to find the next instruction.
```

For example, an instruction might say:

```text
addi $t0, $zero, 5
```

In plain English:

> Take the value in `$zero`, add 5, and store the result in `$t0`.

The CPU performs that sentence using hardware:

```text
instruction bits
      ↓
control unit interprets them
      ↓
register file supplies $zero
      ↓
ALU adds 0 and 5
      ↓
register file stores 5 in $t0
```

The ALU is only one part of the CPU. The CPU also requires storage,
instruction interpretation, memory, and connections between those blocks.

---

## What does single-cycle mean?

Here, one instruction completes during one clock period. The processor does not
use separate fetch, decode, execute, and write-back cycles; those activities
happen as one combinational path between clock edges.
This organization follows the classic single-cycle datapath model described by
Patterson and Hennessy [5].

![Single-cycle instruction flow](docs/diagrams/instruction-cycle.svg)

Keep this distinction in mind:

| Combinational work | Clocked state |
| --- | --- |
| ALU result | Program counter |
| Control signals | Register-file writes |
| Immediate extension | Data-memory writes |
| Next-PC selection | |

At a rising edge, the processor remembers the new PC, register values, and
memory values. During the rest of the cycle, combinational logic calculates
what should happen next.

This design is easy to understand because each instruction has a complete
visible path. Although it is not the fastest CPU architecture, it is an
excellent first CPU architecture.

---

## The processor at a glance

The top-level module is `rtl/mips32_cpu.v`. It wires together the PC,
instruction memory, control unit, datapath, and data memory.

![CPU overview](docs/diagrams/cpu-overview.svg)

The large boxes in the diagram correspond to real RTL modules:

| Concept | Repository file | Responsibility |
| --- | --- | --- |
| Program counter | `rtl/pc.v` | Remembers the current instruction address |
| Instruction memory | `rtl/instruction_memory.v` | Returns the instruction at the PC |
| Control unit | `rtl/control_unit.v` | Interprets opcode and function fields |
| Register file | `rtl/register_file.v` | Stores 32 general-purpose registers |
| ALU | `rtl/alu.v` | Performs arithmetic and logical operations |
| Datapath | `rtl/datapath.v` | Connects operands, results, memory, and PC choices |
| Data memory | `rtl/data_memory.v` | Stores and returns program data |
| Complete CPU | `rtl/mips32_cpu.v` | Instantiates and wires everything together |

The datapath acts as the road system of the processor. Values travel along
wires, and multiplexers choose which road each value takes.

---

## How one instruction travels

Every supported instruction follows the same broad story:

### 1. Fetch

The PC supplies a byte address, and instruction memory uses that address to
return a 32-bit instruction.

Normal sequential execution advances by four bytes:

```text
next PC = current PC + 4
```

Instructions are four bytes wide, so the low two address bits must be zero.

### 2. Decode

The control unit reads the instruction's opcode and, for R-type instructions,
its function field. It produces signals such as:

- should the ALU use a register or an immediate?
- should the result be written to `rd` or `rt`?
- should data memory be read or written?
- is this a branch or jump?
- which ALU operation is required?

### 3. Read operands

The register file reads two registers at the same time. The datapath also
forms a 32-bit immediate from the instruction's 16-bit field.

Different instructions use different immediate rules:

- arithmetic offsets are sign-extended;
- logical immediates are zero-extended;
- `lui` moves the value into the upper 16 bits;
- branch offsets are shifted left by two.

### 4. Execute

The ALU performs the operation. For a memory instruction, it calculates an
effective address:

```text
effective address = base register + offset
```

For a branch, subtraction produces the `zero` flag used to decide equality.

### 5. Memory

`lw` reads data memory. `sw` writes data memory. Other instructions do not
access data memory.

### 6. Write back

The result can come from:

- the ALU;
- data memory;
- `PC + 4` for `jal`.

The destination can be `rd`, `rt`, or register 31 (`$ra`).

### 7. Select the next PC

The datapath chooses the next PC from:

```text
PC + 4
branch target
jump target
register target for jr
```

The priority is `jr`, then `j`/`jal`, then a taken branch, and finally the
normal sequential address.

---

## The repository as a book

The project can be studied as a sequence of chapters. Each chapter has three
parts:

1. a hardware idea;
2. an RTL module;
3. an executable testbench.

| Chapter | Read | Then run |
| --- | --- | --- |
| 1. Combinational logic | `rtl/alu.v` | `tb/alu_tb.v` |
| 2. Clocked state | `rtl/pc.v` | `tb/pc_tb.v` |
| 3. Register storage | `rtl/register_file.v` | `tb/register_file_tb.v` |
| 4. Program storage | `rtl/instruction_memory.v` | `tb/instruction_memory_tb.v` |
| 5. Instruction interpretation | `rtl/control_unit.v` | `tb/control_unit_tb.v` |
| 6. Data storage | `rtl/data_memory.v` | `tb/data_memory_tb.v` |
| 7. Connecting the datapath | `rtl/datapath.v` | `tb/datapath_tb.v` |
| 8. The complete machine | `rtl/mips32_cpu.v` | `tb/mips32_cpu_tb.v` |

The full beginner course is in
[`docs/beginner-roadmap.md`](docs/beginner-roadmap.md). It presents the same
sequence in lesson form and includes exercises.

---

## The beginner learning path

### Chapter 1: Begin with the ALU

Readers can start with a familiar circuit. The ALU receives two 32-bit values
and an operation code, then produces a result and a zero flag.

```verilog
result = a + b;
```

At this stage, there is no memory and no instruction decoding. The ALU only
reacts to its inputs, providing an example of combinational logic.

Questions to answer:

- What changes when `a` changes?
- Why does the ALU not need a clock?
- How is signed `slt` different from bitwise operations?
- Why is the zero flag useful for branches?

### Chapter 2: Add time with the PC

The PC is a 32-bit register. Unlike the ALU, it remembers a value across
clock edges:

```verilog
always @(posedge clk) begin
    pc <= next_pc;
end
```

Reset gives the processor a known starting address.

### Chapter 3: Add registers

The register file contains 32 registers. A five-bit address selects one:

```text
2^5 = 32
```

The register file has two asynchronous read ports and one synchronous write
port. `$zero` is hard-wired to zero, which is a common and useful CPU
convention.

### Chapter 4: Store instructions

Instruction memory maps addresses to 32-bit instruction words. In simulation,
the memory can be initialized with `$readmemh` or directly from a testbench.

This is the point where a bit pattern becomes an instruction.

### Chapter 5: Decode instructions

The control unit is an interpreter implemented as combinational RTL. It maps
instruction fields to control signals, while its default controls keep
unsupported instructions safe and inert.

### Chapter 6: Store data

Data memory is separate from instruction memory. A store changes memory at a
clock edge, while a read returns data combinationally.

### Chapter 7: Connect the datapath

The datapath combines the register file, immediate formation, ALU, write-back
muxes, branch logic, and jump logic.

### Chapter 8: Build the complete CPU

The top-level CPU connects the pieces and executes a small program. At that
point, the processor is a machine that changes state according to instructions
rather than a collection of isolated modules.

---

## The instruction formats

The processor uses three simple instruction shapes.

### R-type: register operations

![R-type instruction format](docs/diagrams/r-type.svg)

Example:

```text
add $t2, $t0, $t1
```

The CPU reads `$t0` and `$t1`, adds them, and writes the result to `$t2`.

### I-type: immediate and memory operations

![I-type instruction format](docs/diagrams/i-type.svg)

Example:

```text
addi $t0, $zero, 5
```

The CPU reads `$zero`, forms the immediate value 5, and writes the result to
`$t0`.

### J-type: control-flow operations

![J-type instruction format](docs/diagrams/j-type.svg)

`j` and `jal` use the target field to construct a new PC.

More complete encoding tables are in
[`docs/instruction-set.md`](docs/instruction-set.md).
The instruction formats, register conventions, and operation semantics are
based on the MIPS32 architecture references [1][2]; this repository implements
an intentionally smaller educational subset.

---

## A complete `addi` walkthrough

The walkthrough traces:

```text
addi $t0, $zero, 5
```

### Instruction bits arrive

Instruction memory returns a 32-bit value, and the control unit sees the
opcode for `addi`.

### The control unit decides

Use these conceptual control settings:

```text
alu_src   = 1       // use the immediate as ALU input B
reg_dst   = 0       // destination is rt
reg_write = 1       // write a register
alu_op    = ADD
```

No memory access and no branch are enabled.

### The register file reads `$zero`

Register 0 always returns zero:

```text
register_data1 = 0
```

### The immediate is extended

The 16-bit value 5 becomes:

```text
0x00000005
```

### The ALU calculates

```text
0 + 5 = 5
```

### The destination is selected

For an I-type instruction, the destination is `rt`. In this encoding, `rt`
is register 8, conventionally named `$t0`.

### The clock edge saves the result

At the rising edge:

```text
register[8] <= 5
```

The next PC is `PC + 4`.

![Tracing addi through the datapath](docs/diagrams/addi-trace.svg)

This is the most important walkthrough in the repository. Every other
instruction is a variation on which values are selected, which operation is
performed, and which state is updated.

---

## Loads, stores, branches, and jumps

### `lw`: load a word

```text
lw $t0, 4($t1)
```

1. Read `$t1`.
2. Sign-extend 4.
3. Add them in the ALU.
4. Read data memory at the resulting address.
5. Write the memory value into `$t0`.

### `sw`: store a word

```text
sw $t0, 4($t1)
```

1. Read `$t1` as the base.
2. Sign-extend 4.
3. Add them in the ALU.
4. Send `$t0` as memory write data.
5. Store it at the clock edge.

### `beq`: branch if equal

```text
beq $t0, $t1, offset
```

The ALU subtracts the operands. If the result is zero, the target is:

```text
PC + 4 + (sign_extended_offset << 2)
```

The shift by two converts an instruction offset into a byte offset.

### `bne`: branch if not equal

`bne` uses the same subtraction, but takes the branch when the ALU zero flag
is false. The explicit `branch_ne` signal tells the datapath to invert the
condition.

### `j`: jump

`j` builds a target from the instruction's 26-bit field and the upper four
bits of `PC + 4`.

### `jal` and `jr`: call and return

`jal`:

```text
$ra = PC + 4
PC  = jump target
```

`jr $ra` reads register 31 and uses it as the next PC. The integration
testbench demonstrates this complete call-and-return path.

---

## Current instruction subset

| Class | Instructions |
| --- | --- |
| R-type | `add`, `sub`, `and`, `or`, `xor`, `slt`, `sll`, `jr` |
| I-type | `addi`, `andi`, `ori`, `xori`, `lui`, `slti`, `lw`, `sw`, `beq`, `bne` |
| J-type | `j`, `jal` |

Use these implementation conventions:

- register 0 (`$zero`) always reads as zero;
- register 31 (`$ra`) stores the return address for `jal`;
- instruction and data addresses must be word-aligned;
- invalid memory addresses read as zero and ignore writes;
- reset is synchronous and active high;
- unsupported instructions safely advance the PC without changing state.

---

## Repository structure

<details>
<summary><strong>rtl/ — Processor implementation</strong></summary>

| File | Purpose |
|---|---|
| `alu.v` | Arithmetic and logic operations |
| `control_unit.v` | Opcode and function decoding |
| `data_memory.v` | Data memory |
| `datapath.v` | Datapath connections |
| `instruction_memory.v` | Instruction storage |
| `mips32_cpu.v` | Complete CPU |
| `pc.v` | Program counter |
| `register_file.v` | Register storage |

</details>

<details>
<summary><strong>tb/ — Testbenches</strong></summary>

| File | Purpose |
|---|---|
| `alu_tb.v` | ALU tests |
| `control_unit_tb.v` | Control-unit tests |
| `data_memory_tb.v` | Data-memory tests |
| `datapath_tb.v` | Datapath tests |
| `instruction_memory_tb.v` | Instruction-memory tests |
| `mips32_cpu_tb.v` | Complete CPU integration test |
| `pc_tb.v` | Program-counter tests |
| `register_file_tb.v` | Register-file tests |

</details>

<details>
<summary><strong>docs/ — Documentation and diagrams</strong></summary>

| File or directory | Purpose |
|---|---|
| `beginner-roadmap.md` | Beginner learning path |
| `architecture.md` | Datapath and control explanation |
| `instruction-set.md` | Instruction formats and encodings |
| `verification.md` | Testbench and CI strategy |
| `learning-notes.md` | Design notes and experiments |
| `diagrams/` | SVG diagrams and Mermaid sources |

</details>

---

## Run the processor

### Requirements

Install Git and at least one Verilog simulator. Icarus Verilog is the
simplest option for beginners; Verilator is a faster compiled simulator and
also provides useful lint checks.
The RTL uses Verilog/SystemVerilog language constructs standardized by IEEE
1364 and IEEE 1800 [3][4].

Ubuntu/Debian:

```sh
sudo apt-get update
sudo apt-get install -y iverilog verilator
```

### Run the complete CPU test

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

The testbench loads a small program into instruction memory and verifies
register results, memory behavior, branches, jumps, `jal`, `jr`, and PC
sequencing.

### Alternative: run the complete CPU with Verilator

Verilator compiles the Verilog into a native executable. The `--timing`
option is required because the testbench contains clock delays and waits such
as `always #5 clk = ~clk` and `@(posedge clk)`.

From the repository root:

```sh
verilator --binary --timing \
  --top-module mips32_cpu_tb \
  tb/mips32_cpu_tb.v \
  rtl/mips32_cpu.v \
  rtl/pc.v \
  rtl/instruction_memory.v \
  rtl/data_memory.v \
  rtl/datapath.v \
  rtl/control_unit.v \
  rtl/register_file.v \
  rtl/alu.v

./obj_dir/Vmips32_cpu_tb
```

The Verilator executable should print the same `PASS` checks as the Icarus
simulation and finish with:

```text
PASS: CPU integration test completed with no failures
```

Verilator is an additional method, not a replacement for understanding the
RTL. Icarus remains useful for simple, traditional Verilog simulation, while
Verilator is useful for fast execution and lint-style feedback.

### Generate a waveform for GTKWave

GTKWave needs a waveform file such as VCD or FST. Add these lines near the
beginning of the `initial` block in `tb/mips32_cpu_tb.v`:

```verilog
$dumpfile("cpu.vcd");
$dumpvars(0, mips32_cpu_tb);
```

Then compile with Verilator tracing enabled:

```sh
verilator --binary --timing --trace \
  --top-module mips32_cpu_tb \
  tb/mips32_cpu_tb.v \
  rtl/mips32_cpu.v \
  rtl/pc.v \
  rtl/instruction_memory.v \
  rtl/data_memory.v \
  rtl/datapath.v \
  rtl/control_unit.v \
  rtl/register_file.v \
  rtl/alu.v

./obj_dir/Vmips32_cpu_tb
gtkwave cpu.vcd
```

The waveform lets readers inspect signals over time, including `clk`, `reset`,
`pc`, `instruction`, `next_pc`, memory controls, and datapath results. The same
`$dumpfile` and `$dumpvars` lines also work with the Icarus command.

### Run an individual unit test

For the ALU:

```sh
iverilog -g2012 -o alu_sim tb/alu_tb.v rtl/alu.v
vvp alu_sim
```

The other unit tests use the same compile-and-run pattern. CI runs all eight
testbenches on pushes, pull requests, and manual workflow dispatches.

---

## Verification results

> **Illustrative placeholder — not a real measurement.**
> Replace the values in this section with results from an actual local run and
> a successful GitHub Actions workflow before relying on them as evidence.

### Tool versions

```text
Icarus Verilog: 12.0 (placeholder)
Verilator: 5.024 (placeholder)
Operating system: Ubuntu 24.04 LTS (placeholder)
```

### Exact command sequence

From the repository root:

```sh
iverilog -g2012 -o alu_sim tb/alu_tb.v rtl/alu.v && vvp alu_sim
iverilog -g2012 -o regfile_sim tb/register_file_tb.v rtl/register_file.v && vvp regfile_sim
iverilog -g2012 -o control_unit_sim tb/control_unit_tb.v rtl/control_unit.v && vvp control_unit_sim
iverilog -g2012 -o pc_sim tb/pc_tb.v rtl/pc.v && vvp pc_sim
iverilog -g2012 -o instruction_memory_sim tb/instruction_memory_tb.v rtl/instruction_memory.v && vvp instruction_memory_sim
iverilog -g2012 -o data_memory_sim tb/data_memory_tb.v rtl/data_memory.v && vvp data_memory_sim
iverilog -g2012 -o datapath_sim tb/datapath_tb.v rtl/datapath.v rtl/control_unit.v rtl/register_file.v rtl/alu.v && vvp datapath_sim
iverilog -g2012 -o cpu_sim tb/mips32_cpu_tb.v rtl/mips32_cpu.v rtl/pc.v rtl/instruction_memory.v rtl/data_memory.v rtl/datapath.v rtl/control_unit.v rtl/register_file.v rtl/alu.v && vvp cpu_sim
```

### Placeholder outcome

The illustrative run reports eight passed testbenches:

| Testbench | Result |
| --- | --- |
| `alu_tb.v` | PASS |
| `register_file_tb.v` | PASS |
| `control_unit_tb.v` | PASS |
| `pc_tb.v` | PASS |
| `instruction_memory_tb.v` | PASS |
| `data_memory_tb.v` | PASS |
| `datapath_tb.v` | PASS |
| `mips32_cpu_tb.v` | PASS |

Representative placeholder output:

```text
PASS: ALU add operation
PASS: register file write and read
PASS: control unit decoding
PASS: program counter reset and update
PASS: instruction memory read
PASS: data memory read and write
PASS: datapath branch and write-back behavior
PASS: CPU integration test completed with no failures

8/8 testbenches passed.  (placeholder)
```

Placeholder CI evidence:
[successful GitHub Actions run](https://github.com/mkfahim/mips32-single-cycle-processor/actions/runs/0000000000)

## Understand the testbenches

Verification is layered:

| Level | What it proves |
| --- | --- |
| ALU test | Operations and zero flag |
| Register-file test | Reads, writes, reset, and `$zero` |
| Control-unit test | Decoding and safe defaults |
| PC test | Reset and next-PC loading |
| Instruction-memory test | Alignment, bounds, and reads |
| Data-memory test | Reads, writes, reset, alignment, and bounds |
| Datapath test | Muxes, write-back, branches, jumps, and memory interface |
| CPU test | Complete program execution |

Each testbench is an executable specification. Read the test before the RTL
when a module feels unfamiliar: the checks explain what behavior the module
promises.

More detail is available in [`docs/verification.md`](docs/verification.md).

---

## What this project does not cover

This processor is intentionally small. It does not yet include:

- pipelining;
- forwarding or hazard detection;
- caches;
- exceptions and interrupts;
- privileged modes or operating systems;
- coprocessors;
- branch delay slots;
- arithmetic overflow exceptions;
- a real memory bus or memory controller;
- synthesis-specific timing constraints.

These are not missing prerequisites for understanding this repository. They
are the next chapters after the single-cycle design becomes familiar.

---

## Further reading

- [Beginner roadmap](docs/beginner-roadmap.md)
- [Architecture and datapath](docs/architecture.md)
- [Instruction set and encodings](docs/instruction-set.md)
- [Verification and CI](docs/verification.md)
- [Learning notes and experiments](docs/learning-notes.md)
- [Visual diagrams and editable Mermaid sources](docs/diagrams/README.md)

## References

1. MIPS Technologies, Inc., *MIPS32 Architecture For Programmers Volume I:
   Introduction to the MIPS32 Architecture*, Revision 2.60, MD00082.
   [PDF mirror](https://minnie.tuhs.org/CompArch/Resources/MD00082-2B-MIPS32INT-AFP-02_60.pdf)
2. MIPS Technologies, Inc., *MIPS32 Architecture For Programmers Volume II:
   The MIPS32 Instruction Set*, Revision 2.00, MD00086.
   [Internet Archive record](https://archive.org/details/MIPS_Technologies_MD00086)
3. IEEE, *IEEE Standard for Verilog Hardware Description Language*,
   IEEE Std 1364-2005.
   [IEEE standard](https://standards.ieee.org/standard/1364-2005.html)
4. IEEE, *IEEE Standard for SystemVerilog—Unified Hardware Design,
   Specification, and Verification Language*, IEEE Std 1800-2017.
   [IEEE standard](https://standards.ieee.org/standard/1800-2017.html)
5. David A. Patterson and John L. Hennessy, *Computer Organization and Design
   RISC-V Edition: The Hardware/Software Interface*, 2nd ed., Morgan Kaufmann,
   2021.
   [Publisher page](https://shop.elsevier.com/books/computer-organization-and-design-risc-v-edition/patterson/978-0-12-820331-6)

## License

See [`LICENSE`](LICENSE).
