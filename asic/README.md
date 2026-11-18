# ASIC Implementation

This directory contains the ASIC-oriented implementation plan for the
MIPS32 single-cycle processor. The RTL in `rtl/` remains the reference
functional design; this work evaluates how that design can be synthesized and
implemented as an ASIC.

## Objectives

- Keep the processor RTL synthesizable and technology-independent.
- Define reproducible synthesis and physical-design flows.
- Measure area, timing, and power after synthesis.
- Run physical-design checks such as design-rule checking (DRC) and
  layout-versus-schematic (LVS) when the flow is available.
- Document tool versions, PDK configuration, constraints, and results.

## Planned flow

```text
RTL
  -> lint and simulation
  -> logic synthesis
  -> timing, area, and power analysis
  -> floorplanning
  -> placement and clock-tree synthesis
  -> routing
  -> DRC/LVS verification
```

The initial open-source flow will target a suitable open PDK, such as SKY130,
using tools such as Yosys and OpenROAD. Commercial tools may be evaluated
separately when their licenses and project constraints permit.

## Planned layout

```text
asic/
├── constraints/   # Clock and timing constraints
├── scripts/       # Synthesis and physical-design scripts
├── results/       # Versioned reports and measurements
└── README.md      # This document
```

Generated databases, large build directories, and proprietary tool outputs
should not be committed unless they are needed to reproduce or review a
specific result.

## Evaluation metrics

| Metric | Status |
|---|---|
| RTL synthesis | Planned |
| Standard-cell area | Planned |
| Maximum frequency | Planned |
| Timing slack | Planned |
| Power estimate | Planned |
| DRC verification | Planned |
| LVS verification | Planned |

No ASIC measurements are claimed until the corresponding flow has been run
and the tool versions, PDK, constraints, and reports have been recorded.

## Relationship to verification

RTL simulation verifies functional behavior. ASIC implementation evaluates
whether that verified RTL can be mapped to physical hardware under a
technology library and timing constraints. Both results are required for a
complete implementation record.
