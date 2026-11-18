# ASIC Implementation

This directory documents the ASIC implementation of the MIPS32 single-cycle
processor. The RTL in `rtl/` is the reference functional design.

## Directory structure

```text
asic/
├── constraints/   # Clock and timing constraints
├── scripts/       # Synthesis and physical-design scripts
├── results/       # Area, timing, power, and DRC/LVS reports
└── README.md      # ASIC flow and implementation results
```

| Component | Purpose |
|---|---|
| `constraints/` | Defines clocks, input/output delays, and timing requirements |
| `scripts/` | Runs synthesis, analysis, and physical-design stages |
| `results/` | Stores measured reports and implementation summaries |
| `README.md` | Records the flow, tools, configuration, and results |

## Implementation flow

```text
RTL -> simulation -> synthesis -> timing/area/power analysis
    -> physical design -> DRC/LVS verification
```

The implementation was completed with:

```text
PDK: <PDK name and version>
Synthesis: <tool and version>
Physical design: <tool and version>
```

## Results

The reported results correspond to commit `<commit>` and run date
`<YYYY-MM-DD>`.

| Metric | Result |
|---|---|
| Standard-cell area | `<value>` |
| Maximum frequency | `<value>` |
| Timing slack | `<value>` |
| Power | `<value>` |
| DRC/LVS | `<PASS or pending>` |

Tool versions, PDK configuration, constraints, and reports are recorded with
the results.
