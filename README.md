# FPGA Window Analyzer

A synthesizable SystemVerilog module that collects a variable-length window of 8-bit data samples and computes two outputs: the maximum value and the range (max − min). Designed and verified for the Basys3 FPGA using Vivado.

## What It Does

On assertion of `start` and `din_valid`, the module reads the window length from the lower 4 bits of the first incoming byte, then collects that many samples into an internal 16-entry memory. It then makes two passes through the memory, one to find the maximum, one to find the minimum, and outputs the maximum followed by the range (max − min) in sequence. The `busy`, `done`, and `dout_valid` signals provide handshaking for integration into a larger system.

## FSM Design

The module is controlled by a 6-state FSM: IDLE, COLLECT, COMPUTE_PRIMARY, COMPUTE_SECONDARY, OUTPUT_PRIMARY, and OUTPUT_SECONDARY. Combinational next-state logic is kept in a separate `always_comb` block from the registered datapath to avoid latches and keep the synthesis clean.

The decision to compute max and min in separate states rather than a single pass was a deliberate trade-off. It adds one extra traversal of memory but significantly simplifies the control logic, which mattered given the project's time constraints.

## Files

- `src/window_analyzer.sv`: top-level RTL module
- `src/tb_window_analyzer.v`: testbench
- `docs/`: simulation screenshots, TCL console output, and Vivado timing and utilization reports

## Simulation Results

![Simulation Results](docs/Simulation%20Results%20-%20annotated.png)

![TCL Screenshot 1](docs/tclscreenshot1.png)
![TCL Screenshot 2](docs/tclscreenshot2.png)

## Tools

SystemVerilog (IEEE 1800), Xilinx Vivado, Digilent Basys3 (Artix-7)

## Author

Christian Watts — B.S. Electrical Engineering, University of Alabama
