# ASIC Implementation

This directory documents the ASIC implementation of the MIPS32 single-cycle
processor. The RTL in `rtl/` remains the reference functional design.

## Planned flow

```text
RTL -> simulation -> synthesis -> timing/area/power analysis
    -> physical design -> DRC/LVS verification
```

Initial target and tools:

```text
PDK: <PDK name and version>
Synthesis: <tool and version>
Physical design: <tool and version>
```

## Results

| Metric | Result |
|---|---|
| Commit | `<commit>` |
| Date | `<YYYY-MM-DD>` |
| Standard-cell area | `<value>` |
| Maximum frequency | `<value>` |
| Timing slack | `<value>` |
| Power | `<value>` |
| DRC/LVS | `<PASS or pending>` |

No ASIC measurements are claimed until the flow has been run and the tools,
PDK, constraints, and reports have been recorded.
