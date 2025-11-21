# Radix-2² FFT Implementation - Vivado Synthesis Tutorial

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Understanding Radix-2² for FPGA](#understanding-radix-2-for-fpga)
4. [Project Setup in Vivado](#project-setup-in-vivado)
5. [Running Synthesis](#running-synthesis)
6. [Implementation](#implementation)
7. [Resource Utilization Analysis](#resource-utilization-analysis)
8. [Timing Analysis](#timing-analysis)
9. [Comparing with Radix-2](#comparing-with-radix-2)
10. [Hardware Testing](#hardware-testing)
11. [Troubleshooting](#troubleshooting)

---

## Introduction

This tutorial guides you through synthesizing and implementing a 16-point FFT using the **Radix-2²** algorithm on an FPGA with **Xilinx Vivado**. You'll learn how this algorithm compares to standard Radix-2 in terms of hardware resources and performance.

### What Makes Radix-2² Different?

**Architecture**:
- **2 stages** instead of 4 (like Radix-2)
- **4 butterflies per stage** (processing 4 points each)
- **Similar to Radix-4** but uses nested Radix-2 structure

**Performance**:
- **Lower latency** than Radix-2 (fewer stages)
- **Similar resource usage** to Radix-4
- **Different optimization opportunities** than pure Radix-4

---

## Prerequisites

### Software Required
- **Xilinx Vivado** (2018.1 or later)
  - Design, System, or WebPACK edition

### Hardware (Optional)
- Any Xilinx FPGA development board
- USB programming cable

### Files Required
- `radix2_2/fft_radix2_2_top.v` - Top FFT module
- `radix2_2/butterfly_radix2_2.v` - Radix-2² butterfly
- `radix2_2/control_radix2_2.v` - Control FSM
- `radix2_2/twiddle_rom_radix2_2.v` - Twiddle factors
- `common/complex_adder.v` - Complex adder
- `common/complex_subtractor.v` - Complex subtractor
- `common/complex_multiplier.v` - Complex multiplier
- `common/register_bank.v` - Register bank
- `master_wrapper.v` - Unified FPGA wrapper (optional)

---

## Understanding Radix-2² for FPGA

### Hardware Architecture

**Pipeline Structure**:
```
Input → Stage 0 → Register Bank → Stage 1 → Output
         (4x4)                      (4x4)
```

Each stage has:
- **4 Radix-2² butterflies** (processing 4 inputs → 4 outputs)
- **Complex multipliers** for twiddle factors
- **Register banks** for data storage between stages

### Resource Requirements

**Per Butterfly**:
- ~800-1200 LUTs (more complex than Radix-2 butterfly)
- ~300-500 Flip-Flops
- 4 Complex Multipliers = 16 real multipliers

**Total Design** (estimated):
- ~4000-6000 LUTs
- ~1500-2500 FFs
- ~32-48 DSP slices

### Advantages Over Radix-2

✅ **Fewer pipeline stages** (2 vs. 4)
✅ **Lower latency** (~50% reduction)
✅ **Easier to pipeline** for high throughput
✅ **Better resource efficiency** than Radix-2

### Comparison with Radix-4

- **Similar performance** (both use 2 stages)
- **Same resource usage** (±5%)
- **Different structure** allows different optimizations
- **Radix-2²** is a special case of mixed-radix algorithm

---

## Project Setup in Vivado

### Step 1: Launch Vivado and Create Project

1. Open **Vivado**
2. Click **Create Project**
3. Click **Next**

### Step 2: Project Configuration

1. **Project name**: `radix2_2_fft_fpga`
2. **Project location**: Choose your workspace folder
3. ☑ **Create project subdirectory**
4. Click **Next**

### Step 3: Project Type

1. Select **RTL Project**
2. ☑ **Do not specify sources at this time**
3. Click **Next**

### Step 4: Select Target Device

**Option A - With Physical Board**:
- Click **Boards** tab
- Search for your board (e.g., "Basys3", "Arty")
- Select your board

**Option B - Generic FPGA**:
- **Parts** tab
- **Family**: Artix-7
- **Package**: Any
- **Speed**: -1
- Select: `xc7a35tcpg236-1` (Basys3 chip)

5. Click **Next**, then **Finish**

---

## Adding Source Files

### Step 5: Add Design Sources

1. **Flow Navigator** → **Add Sources**
2. Select **Add or create design sources**
3. Click **Next**

### Step 6: Add Verilog Files

Click **Add Files** and add these in order:

**Common modules**:
```
../common/complex_adder.v
../common/complex_subtractor.v
../common/complex_multiplier.v
../common/register_bank.v
```

**Radix-2² specific modules**:
```
butterfly_radix2_2.v
control_radix2_2.v
twiddle_rom_radix2_2.v
fft_radix2_2_top.v
```

**Top-level wrapper**:
```
../master_wrapper.v
```

### Step 7: Configure Master Wrapper

**IMPORTANT**: The `master_wrapper.v` needs to be configured for Radix-2²:

1. Before adding sources, open `master_wrapper.v` in a text editor
2. Find line ~35-45 (FFT core instantiation section)
3. Make sure the **Radix-2² section is uncommented**:

```verilog
// Radix-2^2 FFT
fft_radix2_2_top fft_core (
    .clk(clk),
    .rst(rst),
    .start(fft_start),
    .real_in(real_in),
    .imag_in(imag_in),
    .real_out(real_out),
    .imag_out(imag_out),
    .done(fft_done)
);
```

4. **Comment out** other FFT instantiations (Radix-2 and Radix-4)
5. Save the file
6. Now add it to the Vivado project

### Step 8: Set Top Module

1. In **Sources** window, expand **Design Sources**
2. Right-click **master_wrapper.v** (or `wrapper_top.v` if using simple wrapper)
3. Select **Set as Top**

---

## Running Synthesis

### Step 9: Check RTL Elaboration

1. **Flow Navigator** → **RTL Analysis** → **Open Elaborated Design**
2. Wait for elaboration (~30 seconds)
3. Click **Schematic** in toolbar
4. Verify hierarchy:
   - Top: `master_wrapper`
   - FFT core: `fft_radix2_2_top`
   - 4 butterfly instances visible

5. Close elaborated design

### Step 10: Run Synthesis

1. **Flow Navigator** → **Run Synthesis**
2. Set **Number of jobs** to 2-8 (based on your CPU)
3. Click **OK**
4. **Wait** ~2-5 minutes

### Step 11: Review Synthesis Results

When synthesis completes:

1. Select **Open Synthesized Design**
2. Click **OK**

Check **Messages** tab:
- ❌ **Errors**: Must fix
- ⚠ **Critical Warnings**: Review carefully
- ℹ **Warnings**: Usually okay

**Common acceptable warnings**:
- Timing constraints not met (we'll add constraints later)
- Parallel synthesis criteria
- Unused input bits

**Critical warnings to investigate**:
- Inferred latches
- Multi-driven nets
- Combinational loops

---

## Implementation

### Step 12: Run Implementation

1. **Flow Navigator** → **Run Implementation**
2. Click **OK**
3. **Wait** ~3-7 minutes

Implementation performs:
- **Placement**: Assigns logic to physical FPGA locations
- **Routing**: Connects placed logic with wires

### Step 13: Open Implemented Design

When complete:
1. Select **Open Implemented Design**
2. Click **OK**

### Step 14: Generate Bitstream (Optional)

Only if you have hardware:

1. **Flow Navigator** → **Generate Bitstream**
2. Click **OK**
3. Wait ~1-2 minutes

---

## Resource Utilization Analysis

### Step 15: View Utilization Report

1. **Reports** → **Report Utilization**
2. Click **OK**

### Step 16: Analyze Resource Usage

**Expected Results for Radix-2²**:

| Resource | Used | Available | Utilization % | Notes |
|----------|------|-----------|---------------|-------|
| **LUT** | ~4000-5500 | 20800 | ~20-26% | Logic gates |
| **LUTRAM** | ~100-300 | 9600 | ~1-3% | Distributed RAM |
| **FF** | ~1500-2200 | 41600 | ~3-5% | Registers |
| **BRAM** | 0 | 50 | 0% | Not used |
| **DSP** | 32-48 | 90 | ~35-53% | Multipliers |
| **IO** | 17-33 | 106 | ~16-31% | Input/output pins |

### Resource Breakdown by Module

View detailed utilization:
1. In Utilization Report, expand **Utilization by Hierarchy**
2. You'll see:

```
master_wrapper (Total)
├── fft_radix2_2_top (~80% of resources)
│   ├── butterfly_radix2_2[0] (~15% each)
│   ├── butterfly_radix2_2[1]
│   ├── butterfly_radix2_2[2]
│   ├── butterfly_radix2_2[3]
│   ├── control_radix2_2 (~5%)
│   └── twiddle_rom_radix2_2 (~1%)
└── Control logic (~20%)
```

### Comparing Resource Usage

| Implementation | LUTs | FFs | DSPs |
|----------------|------|-----|------|
| Radix-2 | ~5000 | ~2000 | 32-48 |
| **Radix-2²** | **~4500** | **~1800** | **32-48** |
| Radix-4 | ~4300 | ~1700 | 32-48 |

**Observations**:
- ✅ Radix-2² uses **~10% fewer LUTs** than Radix-2
- ✅ Similar efficiency to Radix-4
- 🔵 DSP usage is the same (same number of complex multiplications)

---

## Timing Analysis

### Step 17: Add Timing Constraints

1. **Add Sources** → **Add or create constraints**
2. **Create File**: `timing_constraints.xdc`
3. Add this line:
   ```tcl
   create_clock -period 10.000 -name clk [get_ports clk]
   ```
   This defines a **100 MHz clock** (10 ns period)

4. Click **Finish**
5. **Re-run Implementation**

### Step 18: Check Timing Summary

1. **Reports** → **Report Timing Summary**
2. Click **OK**

### Step 19: Interpret Timing Results

**Key Metrics**:

**Worst Negative Slack (WNS)**:
- **Target**: < 0 ns (negative means design is faster than required)
- **Expected for Radix-2²**: -1.5 to -4.0 ns
- **Interpretation**:
  - WNS = -3.2 ns → 3.2 ns of timing margin (GOOD ✅)
  - WNS = +0.5 ns → Design is too slow (BAD ❌)

**Total Negative Slack (TNS)**:
- Sum of all negative slacks
- Should be ≤ 0

**Worst Hold Slack (WHS)**:
- Must be ≥ 0 (otherwise data corruption)

### Expected Timing Performance

| Clock Frequency | Expected WNS | Status |
|----------------|--------------|--------|
| 100 MHz (10 ns) | -2 to -4 ns | ✅ Easy |
| 150 MHz (6.67 ns) | -0.5 to -2 ns | ✅ Achievable |
| 200 MHz (5 ns) | -0.2 to +1 ns | ⚠ Challenging |

**Critical Path** (slowest logic):
- Likely through complex multiplier → butterfly → register
- Check detailed timing report to see exact path

### Step 20: Maximum Frequency Calculation

If WNS = -3.2 ns, the max frequency is:
```
Clock period = 10 ns (target)
Actual path delay = 10 - 3.2 = 6.8 ns
Max frequency = 1 / 6.8ns = 147 MHz
```

So your design can run up to **147 MHz**!

---

## Comparing with Radix-2

### Step 21: Side-by-Side Comparison

If you've completed the Radix-2 tutorial, compare:

| Metric | Radix-2 | Radix-2² | Improvement |
|--------|---------|----------|-------------|
| **Stages** | 4 | 2 | 50% fewer |
| **LUTs** | ~5000 | ~4500 | 10% fewer |
| **FFs** | ~2000 | ~1800 | 10% fewer |
| **DSPs** | 32-48 | 32-48 | Same |
| **Latency** | 8 cycles | 4 cycles | 50% faster |
| **Max Freq** | ~150 MHz | ~150 MHz | Similar |
| **Throughput** | 1 FFT/8 cyc | 1 FFT/4 cyc | 2× better |

### Why Radix-2² is Better

✅ **Performance**: Fewer stages = lower latency
✅ **Resources**: Slightly fewer LUTs and FFs
✅ **Efficiency**: Same result with less hardware

### Why You Might Still Use Radix-2

- **Simplicity**: Easier to understand and debug
- **Flexibility**: Easier to modify for non-power-of-4 sizes
- **Education**: Better for learning FFT basics

---

## Hardware Testing

### Step 22: Program the FPGA (Optional)

**Skip if you don't have hardware.**

1. Connect your FPGA board via USB
2. Power on the board
3. **Flow Navigator** → **Open Hardware Manager**
4. **Open Target** → **Auto Connect**
5. Right-click the FPGA device
6. **Program Device**
7. Select bitstream: `.../impl_1/master_wrapper.bit`
8. Click **Program**

### Step 23: Observe LED Output

After programming:

**Expected Behavior**:
- **All 16 LEDs should light up** (or most of them)
- This shows FFT bin 0 magnitude ≈ 32767
- LEDs represent binary magnitude of the selected bin

**LED Meaning**:
- LED[15] = MSB (most significant bit) - should be ON
- LED[14-1] = middle bits - most should be ON
- LED[0] = LSB (least significant bit) - may flicker

### Step 24: Verify Continuous Operation

The design runs continuously:
1. Generates impulse input
2. Computes FFT
3. Updates LEDs
4. Repeats

You should see stable LED output (not flickering, except LSB).

### Step 25: Select Different Bins (Advanced)

To display different bins, modify `master_wrapper.v`:

Find line ~60:
```verilog
wire [3:0] bin_select = sw[3:0];  // From switches
```

If your board doesn't have switches, hardcode:
```verilog
wire [3:0] bin_select = 4'd5;  // Display bin 5
```

Re-synthesize, implement, and program. LEDs now show bin 5 magnitude.

---

## Troubleshooting

### Problem: Synthesis Fails

**Error**: `Cannot find module: fft_radix2_2_top`

**Solution**:
- Verify `fft_radix2_2_top.v` is added to project
- Check Sources window for the file
- Ensure file path is correct

---

**Error**: `Multiple drivers on net`

**Solution**:
- Check that only ONE FFT core is instantiated in wrapper
- Comment out other FFT instantiations (Radix-2, Radix-4)

---

### Problem: Implementation Fails - Design Too Large

**Error**: `Cannot fit design on device`

**Solution**:
- Select a larger FPGA (e.g., xc7a100t instead of xc7a35t)
- Or reduce design complexity

---

### Problem: Timing Violation

**Error**: `Timing constraints are not met, WNS = +2.3 ns`

**Solutions**:

1. **Reduce clock frequency**:
   ```tcl
   create_clock -period 15.000 -name clk [get_ports clk]  # 66 MHz
   ```

2. **Add pipelining**: Modify complex_multiplier.v to add more pipeline stages

3. **Check critical path**:
   - Open timing report
   - Find slowest path
   - Consider optimizing that module

---

### Problem: LEDs Don't Light Up

**Possible Causes**:

1. **Wrong pin constraints**: Need to create .xdc file with LED pin mappings
2. **Clock issue**: Clock not connected or wrong frequency
3. **Reset stuck**: Check reset logic

**Solution**:
- Create pin constraints file (board-specific)
- Example for Basys3:
  ```tcl
  set_property PACKAGE_PIN W5 [get_ports clk]
  set_property PACKAGE_PIN U16 [get_ports {led[0]}]
  set_property PACKAGE_PIN E19 [get_ports {led[1]}]
  # ... etc for all 16 LEDs
  ```

---

### Problem: Utilization Report Shows 0% for Everything

**Cause**: Design wasn't synthesized/implemented properly

**Solution**:
- Close implemented design
- Re-run synthesis
- Re-run implementation
- Open implemented design
- View utilization report again

---

## Advanced Optimizations

### Optimization 1: Reduce DSP Usage

If your FPGA has limited DSP slices, modify `complex_multiplier.v`:

Change:
```verilog
assign real_product = (ar * br - ai * bi) >>> 15;
```

To use LUT-based multiplication (slower but no DSP):
```verilog
// Add directive
(* use_dsp = "no" *)
assign real_product = (ar * br - ai * bi) >>> 15;
```

Re-synthesize and compare resource usage.

### Optimization 2: Increase Throughput

Add more pipeline stages in butterflies for higher clock frequency:

1. Modify `butterfly_radix2_2.v`
2. Add register stages after each operation
3. Update control FSM to account for longer latency

### Optimization 3: Power Optimization

Enable Vivado's power optimization:

1. **Tools** → **Settings** → **Implementation**
2. **Strategy**: Select "Power_DefaultOpt"
3. Re-run implementation
4. Check power report

---

## Summary

You've successfully:
1. ✅ Created a Vivado project for Radix-2² FFT
2. ✅ Synthesized the design (Verilog → Gates)
3. ✅ Implemented on FPGA (Gates → Physical layout)
4. ✅ Analyzed resource utilization (~20-26% of Artix-7)
5. ✅ Verified timing closure at 100 MHz
6. ✅ Compared with Radix-2 (10% more efficient)
7. ✅ (Optional) Programmed real FPGA hardware

### Key Takeaways

**Performance**:
- ✅ **50% lower latency** than Radix-2 (2 stages vs. 4)
- ✅ **2× better throughput** (4 cycles vs. 8)
- ✅ **Same max frequency** (~150 MHz)

**Resources**:
- ✅ **10% fewer LUTs** than Radix-2
- ✅ **Similar to Radix-4** efficiency
- ✅ **~20-26% utilization** on mid-range Artix-7

**When to Use Radix-2²**:
- Need better performance than Radix-2
- Want to understand mixed-radix algorithms
- Exploring optimization opportunities

### Next Steps

- Try **Radix-4** for comparison
- Experiment with higher clock frequencies
- Add input/output interfaces (UART, SPI, etc.)
- Implement continuous streaming mode
- Explore power consumption in detail

---

**Need Help?** Check Troubleshooting or review the ModelSim tutorial for simulation guidance.
