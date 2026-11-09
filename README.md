# Digital IC DFT Design and Verification

**Verilog · Vivado 2022.2 (XSim) · Python · Tcl**

An educational, RTL-level project exploring the fundamentals of **Design for Testability (DFT)** through scan chains, scan-based fault testing, basic test-pattern generation, a JTAG TAP controller model, and Vivado scripting.

The goal is to understand how internal flip-flop states can be controlled and observed, how stuck-at faults can be activated and propagated, and how simulation tasks can be automated.

> **Scope:** This is a learning project, **not** a production DFT flow. It does not use Synopsys TestMAX, perform automatic scan insertion or DFT DRC, generate production ATPG patterns, or implement a fully IEEE 1149.1-compliant boundary-scan device.

## Project modules

| Lab | Focus | Implementation |
| --- | --- | --- |
| **01 — Scan Chain** | Scan DFF and serial shifting | An 8-bit scan chain with functional capture, shift-in/shift-out, asynchronous reset, and a self-checking Verilog testbench |
| **02 — Scan-Based Fault Testing** | Stuck-at faults and basic ATPG | An 8-bit sequential logic block with scan access, simulated stuck-at-0/1 faults at one internal node, a self-checking testbench, and a Python exhaustive pattern search |
| **03 — JTAG TAP** | JTAG fundamentals | An educational 16-state TAP FSM with a 4-bit instruction register, an 8-bit demonstration data register, and a 1-bit BYPASS path |
| **04 — Tcl Automation** | EDA scripting | Vivado Tcl scripts that add sources, set the simulation top, launch XSim, and run the Lab 02 or Lab 03 testbench |

## Repository structure

```text
.
├── lab01_scan_basics/
│   ├── rtl/scan_dff.v
│   ├── rtl/scan_chain_8.v
│   └── tb/tb_scan_chain_8.v
├── lab02_scan_atpg/
│   ├── rtl/scan_dff.v
│   ├── rtl/scan_logic8.v
│   ├── tb/tb_scan_logic8.v
│   └── scripts/
│       ├── atpg_stuck_at.py
│       └── atpg_report.txt
├── lab03_jtag_tap/
│   ├── rtl/jtag_tap_demo.v
│   └── tb/tb_jtag_tap_demo.v
├── vivado_tcl/
│   ├── run_lab02.tcl
│   └── run_lab03.tcl
├── .gitignore
└── README.md
```

## Getting started

**Requirements:** Vivado 2022.2 with XSim (for RTL simulation) and Python 3 (for the Lab 02 pattern-generation script). A physical FPGA board is **not** required.

### Lab 01 — 8-bit scan chain

1. Create a new **RTL Project** in Vivado.
2. Add `lab01_scan_basics/rtl/scan_dff.v` and `lab01_scan_basics/rtl/scan_chain_8.v` as **Design Sources**.
3. Add `lab01_scan_basics/tb/tb_scan_chain_8.v` as a **Simulation Source**.
4. Set `tb_scan_chain_8` as the simulation top and run **Behavioral Simulation → Run All**.
5. Check the console and waveforms for reset, parallel capture, serial shift-in, and shift-out.

Expected final testbench message:

```text
ALL TESTS PASSED (28 state checks)
```

### Lab 02 — Scan-based stuck-at fault testing and pattern generation

1. Create a **separate** Vivado RTL project.
2. Add `lab02_scan_atpg/rtl/scan_dff.v` and `lab02_scan_atpg/rtl/scan_logic8.v` as Design Sources.
3. Add `lab02_scan_atpg/tb/tb_scan_logic8.v` as a Simulation Source.
4. Set `tb_scan_logic8` as the simulation top and run **Behavioral Simulation → Run All**.
5. Inspect `scan_en`, `scan_in`, `scan_out`, `scan_state`, `fault_mode`, and the internal `functional_next` signal.

The testbench exercises scan loading, functional capture, scan readout, fault detection, and fault masking. Its expected final message is:

```text
ALL LAB02 TESTS PASSED (5 cases)
```

Run the Python test-pattern search from the repository root:

```powershell
python .\lab02_scan_atpg\scripts\atpg_stuck_at.py
```

The script searches all 256 possible 8-bit input states and writes `lab02_scan_atpg/scripts/atpg_report.txt`.

**Modeled fault site:** `n0 = q[0] & q[1]`  
**Propagation path:** `next[0] = (n0 ^ q[2]) & q[3]`

| Modeled fault | Detecting patterns | First detecting input | Good capture | Faulty capture |
| --- | ---: | --- | --- | --- |
| `n0` stuck-at-0 | 32 / 256 | `0x0B` | `0x49` | `0x48` |
| `n0` stuck-at-1 | 96 / 256 | `0x08` | `0x0A` | `0x0B` |

Both **modeled** faults have at least one detecting pattern, giving **100% coverage of this two-fault model only**. This is **not** whole-circuit fault coverage. Faults are injected using an educational `fault_mode` control; no physical chip faults are measured.

### Lab 03 — Educational JTAG TAP controller

1. Create a new Vivado RTL project.
2. Add `lab03_jtag_tap/rtl/jtag_tap_demo.v` as a Design Source.
3. Add `lab03_jtag_tap/tb/tb_jtag_tap_demo.v` as a Simulation Source.
4. Set `tb_jtag_tap_demo` as the simulation top and run Behavioral Simulation.
5. Inspect the TAP state transitions (`TMS`/`TCK`), instruction shifting (`TDI`), and serial output (`TDO`).

The model includes the 16 TAP states, an instruction register, a demonstration data register, and a BYPASS path. The testbench is designed to report:

```text
ALL LAB03 TESTS PASSED
```

**Limitation:** This module demonstrates TAP control concepts; it is not a complete IEEE 1149.1 boundary-scan implementation.

### Lab 04 — Vivado Tcl automation

Open a Vivado **RTL project first**, then run a script in the **Tcl Console**. Replace the example path with the actual repository location:

```tcl
source D:/Digital-IC-DFT-Design-and-Verification/vivado_tcl/run_lab02.tcl
```

For Lab 03, open a separate project and run:

```tcl
source D:/Digital-IC-DFT-Design-and-Verification/vivado_tcl/run_lab03.tcl
```

These scripts **add the RTL and testbench files, set the top modules, launch simulation, and execute `run all`**. They do **not** automatically parse all logs or generate a combined PASS/FAIL dashboard.

## Verification status

- [x] **Lab 01:** 8-bit scan-chain waveforms and state checks observed in Vivado XSim.
- [x] **Lab 02 (Python):** Pattern search completed; `PYTHON MODEL CHECKS PASSED`.
- [ ] **Lab 02 (XSim):** Confirm the full testbench PASS log and save a waveform screenshot.
- [ ] **Lab 03 (XSim):** Confirm TAP testbench PASS and save a waveform screenshot.
- [ ] **Lab 04 (Tcl):** Confirm scripted runs in Vivado and archive logs.

Unchecked items indicate steps for which successful local execution has **not yet been documented**. Update this checklist as verification is completed.

## Concepts practiced

Scan-enabled flip-flops, controllability and observability, scan shift/capture, stuck-at fault activation and propagation, test-pattern generation, fault masking, JTAG TAP state transitions, RTL self-checking testbenches, and basic Tcl scripting for EDA tools.

## Further work

- Extend the fault list beyond one internal node and calculate coverage over a clearly defined fault universe.
- Add regression scripts that parse simulator logs and summarize PASS/FAIL results.
- Explore synthesis reports and introductory static timing analysis (setup, hold, slack).
