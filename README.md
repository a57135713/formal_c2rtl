# JasperGold C2RTL Demo — 8-Tap FIR Filter

A complete, portable C2RTL formal verification environment demonstrating
**C/C++ to RTL sequential equivalence checking** with Cadence JasperGold.

## Directory Structure

```
formal_c2rtl/
├── c_model/                  # C/C++ reference model (algorithmic spec)
│   ├── fir_filter.h          #   header
│   └── fir_filter.cpp        #   implementation
├── rtl/                      # RTL implementation (SystemVerilog)
│   └── fir_filter.sv         #   8-tap FIR, 4-stage pipeline
├── cfg/                      # Configuration
│   ├── dut.f                 #   RTL filelist
│   └── c2rtl_setup.tcl       #   C2RTL app setup script
├── run/                      # Runtime directory (JG output)
└── README.md
```

## Design Overview

| Component | Language | Description |
|-----------|----------|-------------|
| Reference Model | C++ | `fir_filter(input, coeff[8], state[8])` — pure function |
| RTL | SystemVerilog | 4-stage pipelined FIR: shift → multiply → sum → quantize |
| Pipeline Latency | — | 4 clock cycles from `data_in` to `data_out` |

### Pipeline Stages

```
Stage 1 (S1):  Shift register — latch input, shift delay line
Stage 2 (S2):  Multiply      — 8 parallel 16×16→32 signed multipliers
Stage 3 (S3):  Sum           — adder tree (8→4→2→1, 37-bit)
Stage 4 (S4):  Quantize      — arithmetic right shift 16 → output
```

## Quick Start

### Prerequisites

- **Cadence JasperGold** (any version with C2RTL App support)
- `jg` command available on `$PATH`

### Run C2RTL Equivalence Check

```bash
cd formal_c2rtl
jg -batch -tcl cfg/c2rtl_setup.tcl
```

The script will:
1. Read the C model → `sec_read_c`
2. Read and elaborate RTL → `analyze` + `elaborate`
3. Map C variables to RTL signals → `sec_map`
4. Prove equivalence → `check_sec -app c2rtl`

### Expected Result

```
PROVED: fir_filter — C model and RTL are sequentially equivalent.
```

If mismatches are found, open JasperGold Visualize to compare C and RTL traces:

```bash
jg -tcl cfg/c2rtl_setup.tcl
# then in the JG GUI: Visualize → violation trace
```

## Signal Mapping

| C Variable | RTL Signal | Pipeline |
|-----------|------------|----------|
| `input` | `data_in` | 0 |
| `coeff[i]` | `coeff[i]` | 0 |
| `state[i]` | `fir_filter.state_reg[i]` | 0 |
| `fir_filter()` return | `data_out` | **4** |

The `-pipeline 4` on the output mapping tells the tool that RTL `data_out`
appears 4 clock cycles after the C function's return value.

## Portability

This project is **self-contained**. To run on another machine:

```bash
# 1. Copy the entire formal_c2rtl/ directory
scp -r formal_c2rtl/ user@remote:/path/to/

# 2. Run
cd /path/to/formal_c2rtl
jg -batch -tcl cfg/c2rtl_setup.tcl
```

All file paths in `cfg/dut.f` and `cfg/c2rtl_setup.tcl` are relative to the
project root — no absolute paths, no machine-specific configuration.
