# Radix-2 FFT Implementation - Vivado Synthesis Tutorial

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Understanding the FPGA Implementation](#understanding-the-fpga-implementation)
4. [Project Setup in Vivado](#project-setup-in-vivado)
5. [Running Synthesis](#running-synthesis)
6. [Implementation and Bitstream Generation](#implementation-and-bitstream-generation)
7. [Understanding Resource Utilization](#understanding-resource-utilization)
8. [Timing Analysis](#timing-analysis)
9. [Hardware Testing (Optional)](#hardware-testing-optional)
10. [Troubleshooting](#troubleshooting)

---

## Introduction

This tutorial will guide you through **synthesizing** and **implementing** a 16-point FFT using the **Radix-2** algorithm on an FPGA using **Xilinx Vivado**. Starting from absolute zero, you'll learn how to take Verilog code and turn it into actual FPGA hardware.

### What is FPGA Synthesis?
- **Synthesis**: Converts Verilog code → Hardware gates (LUTs, flip-flops)
- **Implementation**: Places and routes those gates on actual FPGA chip
- **Bitstream**: Binary file that programs the FPGA

### What You'll Learn
1. Create a Vivado project from scratch
2. Add Verilog source files
3. Synthesize the design (check it works)
4. Run implementation (fit it on FPGA)
5. Analyze resource usage and timing
6. Optionally program a real FPGA board

---

## Prerequisites

### Software Required
- **Xilinx Vivado** (2018.1 or later recommended)
  - Design Edition, System Edition, or WebPACK (free version)
- This FFT project files

### Hardware (Optional)
If you want to test on real hardware:
- Any Xilinx FPGA board (Basys3, Arty, Nexys, ZedBoard, etc.)
- USB cable for programming

**Note**: You can complete this tutorial without hardware!

### Files You'll Need
- `radix2/wrapper_top.v` - FPGA wrapper with LED outputs
- `radix2/fft_radix2_top.v` - Top FFT module
- `radix2/butterfly_radix2.v` - Butterfly unit
- `radix2/control_radix2.v` - Control FSM
- `radix2/twiddle_rom_radix2.v` - Twiddle factors
- `common/complex_adder.v` - Adder
- `common/complex_subtractor.v` - Subtractor
- `common/complex_multiplier.v` - Multiplier
- `common/register_bank.v` - Register bank

---

## Understanding the FPGA Implementation

### Wrapper Architecture

The `wrapper_top.v` module is designed for FPGA boards with:

**Inputs**:
- `clk` - System clock (e.g., 100 MHz on most boards)
- `rst` - Reset button

**Outputs**:
- `led[15:0]` - 16 LEDs showing one FFT bin's magnitude

### How It Works

1. **Automatic Stimulus**: Generates impulse input internally (no external input needed)
2. **Continuous Operation**: Automatically restarts FFT after each completion
3. **Single Bin Display**: Shows the magnitude of bin 0 on LEDs
4. **Visual Feedback**: LED brightness shows FFT result magnitude

### Block Diagram
```
┌─────────────────────────────────────────┐
│         wrapper_top.v                    │
│                                          │
│  ┌────────────┐      ┌──────────────┐  │
│  │  Impulse   │─────→│  FFT Core    │  │
│  │ Generator  │      │ (Radix-2)    │  │
│  └────────────┘      └──────┬───────┘  │
│                              │           │
│                              ▼           │
│                      ┌──────────────┐   │
│                      │ Bin Selector │   │
│                      │ (Bin 0)      │   │
│                      └──────┬───────┘   │
│                              │           │
│                              ▼           │
│                      [LED Outputs]       │
└─────────────────────────────────────────┘
```

---

## Project Setup in Vivado

### Step 1: Launch Vivado

1. Open **Vivado** from Start Menu or Applications
2. You'll see the Vivado startup screen with:
   - "Quick Start" section
   - "Recent Projects" list
   - "Tasks" section

### Step 2: Create a New Project

1. Click **Create Project** under Quick Start
2. Click **Next** on the welcome screen

### Step 3: Project Name and Location

1. **Project name**: `radix2_fft_fpga`
2. **Project location**: Browse to a workspace folder (e.g., `C:/FPGA_Projects` or `/home/user/fpga_work`)
3. ☑ Check **Create project subdirectory**
4. Click **Next**

### Step 4: Project Type

1. Select **RTL Project**
2. ☑ Check **Do not specify sources at this time**
   - We'll add them manually for better understanding
3. Click **Next**

### Step 5: Select FPGA Part

**Option A: If you have a physical board:**

1. Click the **Boards** tab
2. Search for your board (e.g., "Basys3", "Arty A7")
3. Select your board
4. Click **Next**

**Option B: No physical board (simulation only):**

1. Stay on the **Parts** tab
2. Filter settings:
   - **Family**: Artix-7 (good mid-range FPGA)
   - **Package**: Any
   - **Speed grade**: -1
3. Select: `xc7a35tcpg236-1` (Basys3 chip, common for learning)
4. Click **Next**

### Step 6: Finish Project Creation

1. Review the project summary
2. Click **Finish**
3. Vivado will create the project and open the main workspace

---

## Adding Source Files

### Step 7: Add Design Sources

1. In the **Flow Navigator** (left panel), under "Project Manager", click **Add Sources**
2. Select **Add or create design sources**
3. Click **Next**

### Step 8: Add Verilog Files

1. Click **Add Files**
2. Navigate to your project folder
3. **Add these files in order**:

   **Common modules first**:
   ```
   ../common/complex_adder.v
   ../common/complex_subtractor.v
   ../common/complex_multiplier.v
   ../common/register_bank.v
   ```

   **Radix-2 specific modules**:
   ```
   butterfly_radix2.v
   control_radix2.v
   twiddle_rom_radix2.v
   fft_radix2_top.v
   ```

   **Top-level wrapper**:
   ```
   wrapper_top.v
   ```

4. ☐ **UNCHECK** "Copy sources into project" (keep original files)
5. Click **Finish**

### Step 9: Set Top Module

1. In the **Sources** window (usually top-left), expand **Design Sources**
2. You'll see all your .v files
3. Right-click on **wrapper_top.v**
4. Select **Set as Top**
5. The file should now have a different icon (house or chip symbol)

---

## Running Synthesis

### Step 10: Check RTL Schematic (Optional but Recommended)

Before synthesis, view the RTL structure:

1. In **Flow Navigator**, under "RTL Analysis", click **Open Elaborated Design**
2. Wait for elaboration to complete (~30 seconds)
3. Click **Schematic** in the top toolbar
4. You'll see a block diagram:
   - `wrapper_top` at the top
   - `fft_radix2_top` inside
   - 8 `butterfly_radix2` instances
   - Complex arithmetic modules

5. This confirms the hierarchy is correct
6. Close the Elaborated Design: Click the **X** on the "Elaborated Design" tab

### Step 11: Run Synthesis

1. In **Flow Navigator**, under "Synthesis", click **Run Synthesis**
2. A dialog appears asking about launching runs:
   - **Number of jobs**: Select based on your CPU (2-8 is good)
   - Click **OK**

3. Vivado starts synthesis. You'll see:
   - Progress bar at top-right
   - Messages scrolling in the **Tcl Console** (bottom)
   - Estimated time remaining

4. **Wait for completion** (~2-5 minutes depending on your computer)

### Step 12: Synthesis Results

When synthesis completes, a dialog appears with options:

1. Select **Open Synthesized Design**
2. Click **OK**

You'll see:
- Schematic view (gate-level, more detailed than RTL)
- Reports panel on the bottom

### Step 13: Check for Errors/Warnings

1. Click the **Messages** tab (bottom)
2. Look for:
   - **Critical Warnings** (yellow/orange) - Should investigate
   - **Errors** (red) - Must fix
   - **Warnings** (yellow) - Usually okay if < 10

**Common warnings you can ignore**:
- "Parallel synthesis criteria is not met"
- "Could not find timing constraint"
- Unconnected ports for debugging signals

**Critical warnings to address**:
- Inferred latches (usually a coding error)
- Combinational loops (serious problem)
- Multi-driven nets (serious problem)

---

## Implementation and Bitstream Generation

### Step 14: Run Implementation

1. In **Flow Navigator**, under "Implementation", click **Run Implementation**
2. A dialog may ask about launching runs:
   - Click **OK** with default settings

3. Implementation runs in two phases:
   - **Placement**: Assigns logic to physical locations on FPGA
   - **Routing**: Connects the placed logic with wiring

4. **Wait for completion** (~3-7 minutes)

### Step 15: Implementation Results

When done, a dialog appears:

1. Select **Open Implemented Design**
2. Click **OK**

You now see the final implemented design.

### Step 16: Generate Bitstream (Optional)

Only needed if you have hardware:

1. In **Flow Navigator**, under "Program and Debug", click **Generate Bitstream**
2. Click **OK** in the dialog
3. Wait for bitstream generation (~1-2 minutes)
4. When complete, click **Cancel** on the dialog (or proceed to programming)

---

## Understanding Resource Utilization

### Step 17: Open Utilization Report

1. After implementation completes, click **Reports** at the top
2. Select **Report Utilization**
3. Click **OK** with default settings

### Step 18: Interpret the Utilization Report

You'll see a table with these resources:

| Resource | Used | Available | Utilization % | What It Is |
|----------|------|-----------|---------------|------------|
| **LUT** (Look-Up Table) | ~3000-5000 | 20800 | ~15-25% | Logic gates |
| **LUTRAM** | ~100-300 | ~9600 | ~1-3% | Small memories |
| **FF** (Flip-Flop) | ~1000-2000 | 41600 | ~2-5% | Registers |
| **BRAM** | 0 | 50 | 0% | Block RAM (not used) |
| **DSP** | 32-48 | 90 | ~35-50% | Multiply-accumulate units |
| **IO** | 17 | 106 | ~16% | Input/output pins |

### What These Numbers Mean

**LUTs (Look-Up Tables)**:
- Used for: Adders, subtractors, comparators, control logic
- Radix-2 uses many LUTs because it has 4 stages

**DSP Slices**:
- Used for: Complex multipliers (each complex multiply = 4 real multiplies)
- Radix-2 has 8 butterflies × 4 DSPs = 32 DSP minimum
- You might see 48 due to pipelining

**Flip-Flops (FF)**:
- Used for: Registers, state machines, pipelines
- Radix-2 has register banks between stages

### Good vs. Bad Utilization

✅ **Good**:
- < 80% of any resource
- Leaves room for future additions
- Design will route easily

⚠ **Warning**:
- 80-95% utilization
- Design may have timing issues
- Hard to add features

❌ **Problem**:
- > 95% utilization
- May not route successfully
- Need a bigger FPGA or optimize code

**For this Radix-2 design**: ~20-30% utilization is expected and healthy.

---

## Timing Analysis

### Step 19: Check Timing Summary

1. After implementation, click **Reports** → **Report Timing Summary**
2. Click **OK**

### Step 20: Understand Timing Results

Look for these key metrics:

**Worst Negative Slack (WNS)**:
- **WNS > 0**: ❌ Design FAILS timing (too slow)
- **WNS = 0**: ✅ Design MEETS timing (just barely)
- **WNS < 0**: ✅ Design EXCEEDS timing (good!)

Example:
```
WNS: -2.347 ns  ← This is GOOD (negative means margin)
```

**Worst Hold Slack (WHS)**:
- Should always be ≥ 0
- If < 0: Serious problem (data corruption)

**Maximum Delay**:
- Shows the slowest path in your design
- Typical: 8-15 ns for 100 MHz clock

### Step 21: Interpret Timing for Radix-2

**Expected Results**:
- Design should easily meet 100 MHz timing
- WNS should be -1 to -5 ns (negative is good!)
- Critical path likely through butterfly multipliers

**If timing fails** (WNS > 0):
- Reduce clock frequency
- Add pipeline stages
- Optimize complex multipliers

### Clock Constraints (Advanced)

**If you see "No constraints"**:

1. Create a constraints file:
   - Click **Add Sources** (Flow Navigator)
   - Select **Add or create constraints**
   - Create new file: `timing_constraints.xdc`

2. Add this line:
   ```tcl
   create_clock -period 10.000 -name clk [get_ports clk]
   ```
   This defines a 100 MHz clock (10 ns period)

3. Re-run implementation

---

## Hardware Testing (Optional)

### Step 22: Connect Your FPGA Board

**Skip this section if you don't have hardware!**

1. Connect your FPGA board to your computer via USB
2. Power on the board
3. Wait for Windows/Linux to recognize it

### Step 23: Program the FPGA

1. In **Flow Navigator**, under "Program and Debug", click **Open Hardware Manager**
2. Click **Open Target** → **Auto Connect**
3. Vivado detects your board
4. Right-click on the FPGA device (e.g., `xc7a35t_0`)
5. Select **Program Device**
6. Browse to the bitstream:
   - Should be: `radix2_fft_fpga.runs/impl_1/wrapper_top.bit`
7. Click **Program**

### Step 24: Observe the LEDs

After programming:

1. **All 16 LEDs should light up** (or most of them)
2. This shows the FFT output bin 0 = 32767 (maximum)
3. If using impulse input, all bins are equal, so bin 0 ≈ 32767

**LED Mapping**:
- Each LED represents one bit of the magnitude
- LED[15] = most significant bit (should be ON)
- LED[0] = least significant bit (may flicker)

### Step 25: Modify to Select Different Bins

To display different bins on LEDs:

1. Open `wrapper_top.v`
2. Find this line (around line 50):
   ```verilog
   wire [3:0] bin_select = 4'd0;  // Select bin 0
   ```
3. Change to:
   ```verilog
   wire [3:0] bin_select = 4'd5;  // Select bin 5
   ```
4. Re-run synthesis, implementation, bitstream generation
5. Re-program the FPGA
6. LEDs now show bin 5's magnitude

---

## Troubleshooting

### Problem: Synthesis Fails

**Error**: `Cannot find <module_name>`

**Solution**:
- Check all source files are added
- Verify file paths are correct
- Make sure `wrapper_top.v` is set as top module

---

**Error**: `Multi-driven net`

**Solution**:
- Check for signals assigned in multiple always blocks
- Look for port connection mistakes

---

### Problem: Implementation Fails

**Error**: `Design does not fit on device`

**Solution**:
- You selected too small an FPGA
- Choose a larger part (e.g., xc7a100t instead of xc7a35t)

---

### Problem: Timing Fails

**Error**: `Timing constraints are not met`

**Solution**:
1. Reduce clock frequency:
   - Change constraint: `create_clock -period 20.000` (50 MHz)
2. Add more pipelining in complex multipliers
3. Check critical path in timing report

---

### Problem: Hardware Doesn't Work

**Symptom**: All LEDs off after programming

**Solutions**:
1. Check power supply to board
2. Verify bitstream programmed successfully
3. Try a different USB port/cable
4. Check constraints file has correct pin assignments

---

**Symptom**: Random LED pattern

**Solutions**:
1. Clock might be wrong frequency
2. Add clock constraints
3. Check timing report for violations

---

### Problem: Can't Find FPGA Board

**Error**: `No hardware targets found`

**Solutions**:
1. Install board drivers (Vivado → Help → Add Board Files)
2. Check USB cable is data-capable (not charge-only)
3. Try different USB port
4. Restart Vivado and reconnect board

---

## Advanced Exploration

### Change Clock Frequency

Edit constraints file:
```tcl
create_clock -period 5.000 -name clk [get_ports clk]  # 200 MHz
```

Re-run implementation and check if timing still passes.

### View Power Consumption

1. After implementation: **Reports** → **Report Power**
2. You'll see estimated power usage (likely 0.1-0.5 W)

### Explore Floor Plan

1. After implementation, click **Device** in the top toolbar
2. You'll see the physical FPGA chip layout
3. Colored blocks show where your design is placed

### Compare with Radix-4

- Radix-4 uses fewer stages (2 instead of 4)
- Should use fewer LUTs
- Might use similar DSPs
- See `radix4/README_VIVADO.md` to compare

---

## Summary

You've successfully:
1. ✅ Created a Vivado project for Radix-2 FFT
2. ✅ Added all Verilog source files
3. ✅ Synthesized the design (Verilog → Gates)
4. ✅ Implemented the design (Gates → Physical FPGA)
5. ✅ Analyzed resource utilization (~20-30%)
6. ✅ Verified timing closure
7. ✅ (Optional) Programmed real FPGA hardware

### Key Takeaways

- **Synthesis**: Converts code to logic gates
- **Implementation**: Places gates on FPGA chip
- **Radix-2**: Uses ~5000 LUTs, ~32-48 DSPs, ~2000 FFs
- **Timing**: Should meet 100 MHz easily
- **LEDs**: Display FFT output magnitude visually

### Design Performance Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| Max Frequency | ~150-200 MHz | Depends on FPGA |
| Latency | ~8 clock cycles | 4 stages × 2 cycles |
| Throughput | 1 FFT per 8 cycles | After pipeline fills |
| LUT Utilization | ~20-30% | On xc7a35t |
| DSP Utilization | ~35-50% | 32-48 of 90 |

### Next Steps

- Compare with **Radix-4** implementation (more efficient)
- Try **Radix-2^2** for hybrid approach
- Add external inputs instead of auto-generated impulse
- Implement streaming mode (continuous FFTs)

---

**Need Help?** Review the Troubleshooting section or check Vivado's built-in documentation (Help → Documentation).
