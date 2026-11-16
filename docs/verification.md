# Verification and Continuous Integration

Verification is organized from small combinational units to the complete
processor. This makes failures easier to localize: if the end-to-end test
fails, the unit tests help determine whether the problem is in the ALU,
decode, state, memory, or wiring.

## Testbench layers

| Testbench | Main responsibility |
| --- | --- |
| `tb/alu_tb.v` | ALU operations and zero flag |
| `tb/register_file_tb.v` | Reset, asynchronous reads, writes, `$zero` protection |
| `tb/control_unit_tb.v` | Opcode/funct decoding and safe defaults |
| `tb/pc_tb.v` | Synchronous reset and next-PC loading |
| `tb/instruction_memory_tb.v` | Aligned reads, bounds, and initialization behavior |
| `tb/data_memory_tb.v` | Reads, writes, reset, alignment, and bounds |
| `tb/datapath_tb.v` | Operand selection, write-back, branches, jumps, and memory interface |
| `tb/mips32_cpu_tb.v` | A small program executed through the complete CPU |

Each testbench prints `PASS` and `FAIL` messages and tracks failures. The
integration tests call `$fatal` when any check fails, which gives the
simulator and CI a non-zero exit status.

## What the end-to-end program demonstrates

The current CPU program executes a sequence containing:

1. `addi` instructions to create operands;
2. `add` to calculate a result;
3. `sw` followed by `lw`;
4. `beq` to skip an instruction;
5. `jal` to save a return address and jump;
6. `xori`, `lui`, and `sll`;
7. `jr` to return through `$ra`;
8. an instruction after the return target.

The testbench checks both architectural results and control flow. For
example, it verifies that the skipped instruction does not change `$t4`, that
`jal` writes `PC + 4` to register 31, and that `jr` returns to that address.

## Running the tests locally

The simplest complete test is the CPU command in the root README. To run all
eight testbenches in the same style as CI, use:

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

The commands use `&&`, so a failing compile or simulation stops the sequence.
The workflow file runs the tests as separate steps so that it can preserve
logs for every test even when one test fails.

## GitHub Actions

`.github/workflows/ci.yml` runs on:

- pushes;
- pull requests;
- manual workflow dispatches.

The job installs Icarus Verilog, compiles each testbench, runs it with `vvp`,
and uploads the simulator logs as an artifact. Test steps use
`continue-on-error` so all logs are collected. A final evaluation step checks
every step outcome and fails the workflow if any test did not succeed.

This last step is important: collecting all failures must not accidentally
turn a broken build green.

## How to add a test for a new instruction

When extending the ISA, use this sequence:

1. Add a focused ALU test if the instruction needs a new ALU operation.
2. Add control-unit assertions for every relevant control signal.
3. Add a datapath test for operands, destination, write-back, or PC behavior.
4. Add an end-to-end program instruction and check its architectural result.
5. Update the instruction-set documentation.
6. Run the same command locally that CI will run.

Tests should check behavior rather than implementation details wherever
possible. Hierarchical access to internal arrays is useful in this educational
repository, but externally observable outputs and register/memory effects
should remain the primary assertions.

## Useful failure diagnosis

| Symptom | First places to inspect |
| --- | --- |
| Wrong arithmetic result | `alu.v`, ALU testbench, `alu_op` decode |
| Correct value in wrong register | `reg_dst`, instruction fields, register file |
| Load returns zero | `mem_read`, address alignment, `mem_to_reg`, data memory |
| Store does not persist | `mem_write`, clock edge, valid address |
| Branch goes wrong way | subtraction, `zero`, `branch_ne`, immediate shift |
| Jump target is wrong | `PC + 4` upper bits and target concatenation |
| Return fails | `jal` write-back, register 31, `jr` PC priority |
| Unsupported instruction changes state | control-unit safe defaults |

## Current verification boundary

The suite verifies the intended subset and the simulation memory model. It
does not yet prove timing closure, synthesis portability across all tools,
formal properties, or behavior under asynchronous reset. Those are separate
verification topics for future work.
