# Learning Notes and Suggested Experiments

This project is most useful when treated as a collection of experiments
rather than as a finished black box. The following notes highlight design
choices that are easy to miss when first learning processor RTL.

## Start with state

A processor is easier to understand when its state is identified first:

- The PC remembers which instruction is being executed.
- The register file remembers software-visible values.
- Data memory remembers stored program data.

The ALU and control unit do not remember anything between cycles. They react
to their inputs. This distinction explains why a register write is checked
after a clock edge while an ALU result can be checked immediately after input
signals settle.

## Why reads are asynchronous here

The register file and data memory use combinational reads to keep the
single-cycle datapath straightforward:

- register operands are available during the same cycle as decode;
- a load value can travel from data memory to write-back before the edge.

Real FPGA and ASIC memories often have different timing and port constraints.
Changing these reads to synchronous interfaces would require a different
microarchitecture, likely with extra cycles or pipeline stages.

## Why the branch uses subtraction

The ALU already knows how to subtract. If two operands are equal, their
difference is zero. Reusing the ALU avoids a separate comparator:

```text
beq: branch && zero
bne: branch && !zero
```

The explicit `branch_ne` signal is important. A single `branch` signal alone
cannot distinguish equality from inequality without retaining the opcode or
adding another control output.

## Why `jal` is a special write-back case

Most instructions choose between an ALU result and memory data. `jal` instead
writes the address of the instruction after the call:

```text
$ra = PC + 4
PC  = jump target
```

The datapath therefore overrides both the destination register and the
write-back value when `jal` is active.

## Why unsupported instructions are inert

The control unit initializes outputs to safe values before decoding. This is
an important RTL habit: every combinational output gets a value on every
evaluation, and unknown instructions do not accidentally enable a write.

In a production processor, an unsupported instruction would normally enter an
exception path. Here, treating it as a no-op keeps the educational machine
small and deterministic.

## Suggested experiments

### Experiment 1: Trace one `addi`

Use `addi $t0, $zero, 5` and follow:

1. opcode selection in `control_unit.v`;
2. register addresses in `datapath.v`;
3. sign extension of the immediate;
4. ALU operand selection;
5. destination selection of `rt`;
6. register-file write at the rising edge.

Then change the immediate to `-1` (`16'hffff`) and observe sign extension.

### Experiment 2: Compare logical and arithmetic immediates

Use the same bit pattern with `andi`, `ori`, `xori`, and `addi`. The logical
instructions zero-extend the immediate, while `addi` sign-extends it. This
shows why the opcode participates in immediate formation.

### Experiment 3: Break branch control deliberately

Temporarily remove the `branch_ne` distinction and run the `bne` test. The
test should expose that `bne` cannot use the `beq` condition unchanged.
Restore the signal and rerun the suite.

### Experiment 4: Observe load/store timing

In the data-memory testbench, write a word on a clock edge and read it
combinationally afterward. Try an unaligned address and confirm that the
write is ignored and the read returns zero.

### Experiment 5: Follow `jal` and `jr`

Set a breakpoint or add displays around the clock edges in the integration
testbench. Observe that `jal` writes register 31 with the return address and
that `jr $ra` selects that register as the next PC.

### Experiment 6: Add an instruction

A useful next instruction is `addu`, which can reuse the add datapath:

1. decide whether a distinct control encoding is necessary;
2. add the function decode;
3. add focused control and end-to-end tests;
4. document the encoding and behavior;
5. confirm that unsupported-instruction defaults remain safe.

More substantial additions, such as byte loads/stores or exceptions, require
new datapath and memory behavior rather than only a new `case` item.

## Questions to ask while reading RTL

For every new signal, ask:

- Is it combinational or clocked?
- Which module produces it?
- Which module consumes it?
- What happens for an unsupported instruction?
- What happens during reset?
- Is the signal needed for data computation, state update, or PC control?

These questions turn a large-looking processor into a set of small,
traceable contracts.

## Ideas for future extensions

Once the current subset is comfortable, useful next projects include:

- more complete arithmetic and comparison instructions;
- byte and halfword memory operations;
- an assembler or program-loader format;
- waveform generation with `$dumpfile` and `$dumpvars`;
- formal assertions for `$zero`, alignment, and PC selection;
- a multi-cycle or pipelined version of the same ISA subset;
- exception handling for invalid instructions and addresses.

Each extension should preserve the discipline used here: define the
architectural behavior, change the smallest set of RTL interfaces, add tests,
and update the documentation.
