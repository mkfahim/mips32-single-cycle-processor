# mips32-processor-verilog

MIPS32 single-cycle processor implemented in Verilog to demonstrate core CPU
architecture concepts.

## Current instruction subset

- R-type: `add`, `sub`, `and`, `or`, `xor`, `slt`, `sll`, `jr`
- I-type: `addi`, `andi`, `ori`, `xori`, `lui`, `slti`, `lw`, `sw`, `beq`, `bne`
- J-type: `j`, `jal`

The `sll` instruction uses the instruction's `shamt` field and is supported
through the ALU, control unit, datapath, and end-to-end CPU testbench.

## Verification

The testbenches use Icarus Verilog:

```sh
iverilog -g2012 -o cpu_sim tb/mips32_cpu_tb.v \
  rtl/mips32_cpu.v rtl/pc.v rtl/instruction_memory.v rtl/data_memory.v \
  rtl/datapath.v rtl/control_unit.v rtl/register_file.v rtl/alu.v
vvp cpu_sim
```

GitHub Actions runs all eight unit and integration testbenches on every push
and pull request.
