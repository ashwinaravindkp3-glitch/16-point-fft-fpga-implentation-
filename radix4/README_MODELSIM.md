# Radix-4 FFT Implementation - ModelSim Simulation Tutorial

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Understanding Radix-4 FFT](#understanding-radix-4-fft)
4. [Project Setup](#project-setup)
5. [Running the Simulation](#running-the-simulation)
6. [Understanding the Output](#understanding-the-output)
7. [Performance Comparison](#performance-comparison)
8. [Troubleshooting](#troubleshooting)

---

## Introduction

This tutorial will guide you through simulating a 16-point FFT using the **Radix-4** algorithm in **ModelSim**. Radix-4 is the most efficient algorithm for power-of-4 sized FFTs and is widely used in commercial implementations.

### What is Radix-4 FFT?
- **Radix-4** is the fastest FFT algorithm for 16-point transforms
- Uses only **2 stages** (since 4² = 16)
- Each butterfly processes **4 inputs → 4 outputs** simultaneously
- **Most efficient** in terms of speed and resources
- Industry standard for power-of-4 FFT sizes

### Why Use Radix-4?
✅ **Minimum latency** (fewest stages)
✅ **Highest throughput** (processes 4 points per butterfly)
✅ **Optimal efficiency** for N = 4^k points
✅ **Widely used** in DSP applications (Wi-Fi, LTE, audio processing)

---

## Prerequisites

### Software Required
- **ModelSim** (Intel/Altera Edition or SE/PE/DE versions)
- This FFT project files

### Files You'll Need
Located in the project directories:
- `model_sim_tb.v` - Testbench (in root folder)
- `radix4/fft_radix4_top.v` - Top module
- `radix4/butterfly_radix4.v` - Radix-4 butterfly unit
- `radix4/control_radix4.v` - Control FSM
- `radix4/twiddle_rom_radix4.v` - Twiddle factor memory
- `common/complex_adder.v` - Complex adder
- `common/complex_subtractor.v` - Complex subtractor
- `common/complex_multiplier.v` - Complex multiplier
- `common/register_bank.v` - Register bank

---

## Understanding Radix-4 FFT

### Algorithm Overview

**Key Concept**: Radix-4 decomposes a 16-point DFT into 2 stages of 4-point DFTs.

**Stage Structure**:
- **Stage 0**: Process groups with stride 4: {0,4,8,12}, {1,5,9,13}, {2,6,10,14}, {3,7,11,15}
- **Stage 1**: Process contiguous groups: {0,1,2,3}, {4,5,6,7}, {8,9,10,11}, {12,13,14,15}

### Radix-4 Butterfly Operation

Each butterfly processes **4 complex inputs** and produces **4 complex outputs**:

```
Input Stage:
    x0, x1, x2, x3

Stage 1 - Horizontal Operations:
    A = x0 + x2
    B = x0 - x2
    C = x1 + x3
    D = x1 - x3

Stage 2 - Vertical Operations:
    t0 = A + C
    t1 = B - j×D    (j-multiplication = rotate by 90°)
    t2 = A - C
    t3 = B + j×D

Stage 3 - Twiddle Factor Multiplication:
    y0 = t0 × W0    (W0 = 1, so no multiplication)
    y1 = t1 × W1
    y2 = t2 × W2
    y3 = t3 × W3

Output:
    y0, y1, y2, y3
```

### j-Multiplication (90° Rotation)

**Important Concept**: Multiplying by **j** (imaginary unit) rotates complex numbers:

```
j × (a + jb) = ja + j²b = ja - b = -b + ja
```

In Verilog:
```verilog
real_out = -imag_in
imag_out = real_in
```

This is **free** in hardware (just wire swapping and negation)!

### Comparison with Other Algorithms

| Feature | Radix-2 | Radix-2² | Radix-4 |
|---------|---------|----------|---------|
| **Stages** | 4 | 2 | 2 |
| **Butterflies/stage** | 8 (2-input) | 4 (4-input) | 4 (4-input) |
| **Points/butterfly** | 2 | 4 | 4 |
| **Total cycles** | ~8 | ~4 | ~4 |
| **Complexity** | Simplest | Medium | Medium |
| **Efficiency** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

### Test Input (Impulse)
The testbench sends an **impulse signal**:
- Input[0] = 32767 (maximum positive value)
- Input[1..15] = 0

**Expected Output**: All 16 bins should be approximately equal to 32767

---

## Project Setup

### Step 1: Launch ModelSim

1. Open **ModelSim**
2. Main window appears with Workspace, Library, and Transcript panes

### Step 2: Create a New Project

1. **File → New → Project**
2. In the "Create Project" dialog:
   - **Project Name**: `radix4_fft`
   - **Project Location**: `/home/user/16-point-fft-fpga-implentation-/radix4`
   - **Default Library Name**: `work`
3. Click **OK**

### Step 3: Add Project Files

The "Add Items to Project" window appears.

**Add files in this exact order:**

1. Click **Add Existing File** for each file:

**Common modules** (shared with other implementations):
```
../common/complex_adder.v
../common/complex_subtractor.v
../common/complex_multiplier.v
../common/register_bank.v
```

**Radix-4 specific modules**:
```
./butterfly_radix4.v
./control_radix4.v
./twiddle_rom_radix4.v
./fft_radix4_top.v
```

**Testbench**:
```
../model_sim_tb.v
```

2. For each file:
   - Browse to the location
   - Ensure **File Type** = "Verilog"
   - Click **OK**

3. After all files are added, click **Close**

### Step 4: Verify Files

In the **Library** tab (left pane), you should see all 9 files under the `work` library.

---

## Running the Simulation

### Step 5: Compile All Files

1. In the **Library** tab, right-click `work`
2. Select **Compile → Compile All**
3. Watch the **Transcript** window
4. Expected output:
   ```
   # Compile of complex_adder.v was successful.
   # Compile of complex_subtractor.v was successful.
   # Compile of complex_multiplier.v was successful.
   # Compile of register_bank.v was successful.
   # Compile of butterfly_radix4.v was successful.
   # Compile of control_radix4.v was successful.
   # Compile of twiddle_rom_radix4.v was successful.
   # Compile of fft_radix4_top.v was successful.
   # Compile of model_sim_tb.v was successful.
   # 9 compiles, 0 failed with no errors.
   ```

**If errors occur**: See [Troubleshooting](#troubleshooting)

### Step 6: Configure Testbench for Radix-4

**CRITICAL STEP**: Ensure testbench uses Radix-4 FFT core.

1. Double-click `model_sim_tb.v` in the Library tab
2. Find line ~30 (FFT instantiation)
3. **Verify it says**:
   ```verilog
   fft_radix4_top uut (
   ```

4. **If it says something else** (e.g., `fft_radix2_top` or `fft_radix2_2_top`):
   - Change it to `fft_radix4_top`
   - Save (Ctrl+S)
   - Recompile: **Compile → Compile All**

### Step 7: Start Simulation

1. **Simulate → Start Simulation**
2. In the "Start Simulation" dialog:
   - Design tab → Expand `work` library
   - Select `model_sim_tb`
   - Click **OK**

3. Simulation loads, showing:
   - **Objects** window with signals
   - **Transcript**: `# vsim work.model_sim_tb`

### Step 8: Add Signals to Waveform

1. In **Objects** window, select:
   - `clk`
   - `rst`
   - `start`
   - `done`
   - `real_in[255:0]`
   - `imag_in[255:0]`
   - `real_out[255:0]`
   - `imag_out[255:0]`

2. Right-click → **Add Wave**
3. Signals appear in **Wave** window

### Step 9: Run the Simulation

In the **Transcript** window, type:
```tcl
run 500 ns
```
Press **Enter**.

Or use the toolbar: Click **Run** button, enter `500 ns`, click **OK**.

### Step 10: Observe Results

1. **Transcript** window shows the output table (see next section)
2. **Wave** window shows signal waveforms
3. Click **Zoom Full** button (binoculars) to see all waveforms

---

## Understanding the Output

### Transcript Window Output

After running, you'll see:

```
============================================
         16-Point FFT Output
============================================
 Bin |   Real Output   |   Imag Output
-----|-----------------|------------------
  0  |      32767      |        0
  1  |      32767      |        0
  2  |      32767      |        0
  3  |      32767      |        0
  4  |      32767      |        0
  5  |      32767      |        0
  6  |      32767      |        0
  7  |      32767      |        0
  8  |      32767      |        0
  9  |      32767      |        0
 10  |      32767      |        0
 11  |      32767      |        0
 12  |      32767      |        0
 13  |      32767      |        0
 14  |      32767      |        0
 15  |      32767      |        0
============================================
```

### Interpreting the Results

**Input Signal**: Impulse at time 0
- Sample 0 = 32767
- Samples 1-15 = 0

**FFT Property**: Impulse → Flat spectrum
- All frequency bins have equal magnitude
- Each bin = 32767 (input amplitude)
- Imaginary parts ≈ 0 (impulse is real signal)

### Acceptable Deviations

**Perfect values**: All real = 32767, all imag = 0

**Acceptable range** (due to fixed-point quantization):
- Real: 32760 to 32775 (within ±8)
- Imaginary: -10 to +10

**Warning signs** (check for errors):
- Any bin < 32700 or > 32800
- Any imaginary value > ±50
- Any bin = 0 (except imaginary)

### Waveform Analysis

In the **Wave** window, observe:

**Clock (clk)**:
- Toggles every 10 ns (50 MHz)
- Steady square wave

**Reset (rst)**:
- High (1) at start
- Goes low after ~50 ns
- Stays low

**Start (start)**:
- Brief pulse (1 clock cycle)
- Triggers FFT computation

**Done (done)**:
- Low during computation
- Goes high when FFT completes
- **Note timing**: Done goes high at ~100-120 ns
  - Radix-2: Done at ~200 ns
  - **Radix-4: 50% faster!** ⚡

**Outputs (real_out, imag_out)**:
- Change during computation
- Stabilize when done goes high
- All 16 bins visible in 256-bit bus

### Measuring Latency

To see exact latency:

1. In Wave window, click on `start` rising edge
2. Note the time (e.g., 60 ns)
3. Click on `done` rising edge
4. Note the time (e.g., 120 ns)
5. **Latency = 120 - 60 = 60 ns = 3 clock cycles**

**Comparison**:
- Radix-2: ~140 ns (7 cycles)
- Radix-2²: ~80 ns (4 cycles)
- **Radix-4: ~60 ns (3 cycles)** - Fastest! 🏆

---

## Performance Comparison

### Run All Three Implementations

To fully appreciate Radix-4's advantages, compare all three:

**Test 1: Radix-2**
1. Edit `model_sim_tb.v` line 30: `fft_radix2_top uut (`
2. Recompile and run
3. Record: `done` time = _____ ns

**Test 2: Radix-2²**
1. Edit `model_sim_tb.v` line 30: `fft_radix2_2_top uut (`
2. Recompile and run
3. Record: `done` time = _____ ns

**Test 3: Radix-4**
1. Edit `model_sim_tb.v` line 30: `fft_radix4_top uut (`
2. Recompile and run
3. Record: `done` time = _____ ns

### Expected Results

| Implementation | Latency (ns) | Clock Cycles | Stages | Speed Improvement |
|----------------|--------------|--------------|--------|-------------------|
| Radix-2 | ~140-160 | 7-8 | 4 | Baseline |
| Radix-2² | ~80-100 | 4-5 | 2 | ~50% faster |
| **Radix-4** | **~60-80** | **3-4** | **2** | **~60% faster** |

### Why Radix-4 is Fastest

**Fewer Stages**:
- Radix-2: 4 stages (each takes 2 cycles)
- Radix-4: 2 stages (each takes 2 cycles)
- **50% fewer stages = 50% lower latency**

**More Parallelism**:
- Radix-2 butterfly: 2 inputs → 2 outputs
- Radix-4 butterfly: 4 inputs → 4 outputs
- **2× more parallel processing**

### Accuracy Comparison

All three implementations should produce identical results (within ±1 due to rounding):

| Bin | Radix-2 | Radix-2² | Radix-4 | Difference |
|-----|---------|----------|---------|------------|
| 0 | 32767 | 32767 | 32767 | 0 |
| 1 | 32767 | 32766 | 32767 | ±1 |
| 2 | 32767 | 32767 | 32767 | 0 |
| ... | ... | ... | ... | ... |

**Conclusion**: All three are equally accurate, but Radix-4 is fastest!

---

## Troubleshooting

### Problem: Compilation Errors

**Error**: `Undefined module: fft_radix4_top`

**Solution**:
- Verify `fft_radix4_top.v` is added to project
- Check file path is correct (`./fft_radix4_top.v`)
- Ensure it compiled successfully

---

**Error**: `Cannot find file: butterfly_radix4.v`

**Solution**:
- Use correct path: `./butterfly_radix4.v` (relative to radix4 folder)
- Or use absolute path

---

### Problem: Wrong FFT Module

**Error**: `Port 'real_in' not found on module fft_radix2_top`

**Cause**: Testbench is using wrong FFT module

**Solution**:
1. Open `model_sim_tb.v`
2. Line 30: Change to `fft_radix4_top uut (`
3. Save and recompile

---

### Problem: Output is All Zeros

**Possible Causes**:
1. Simulation didn't run long enough
2. Start signal didn't pulse
3. Reset stuck high

**Solutions**:
1. Run longer: `run 1000 ns`
2. Check waveform: verify `start` pulses
3. Check waveform: verify `rst` goes low after ~50 ns
4. Restart: `restart -f` then `run 500 ns`

---

### Problem: Output Has 'X' (Unknown) Values

**Causes**:
- Uninitialized variables
- Simulation timing issues

**Solutions**:
1. Check all files compiled without warnings
2. Verify clock is running (check waveform)
3. Ensure reset sequence is correct
4. Restart simulation cleanly: `quit -sim` then restart

---

### Problem: Done Never Goes High

**Causes**:
- Control FSM stuck
- Start signal not detected

**Solutions**:
1. Check waveform: Does `start` pulse?
2. Check waveform: Is `clk` toggling?
3. Verify `rst` is low during operation
4. Look at internal FSM state (add to waveform):
   - In Objects: Expand `uut`
   - Add signal `uut/control_unit/current_state`
   - See if state changes

---

### Problem: Results Different from Expected

**Symptom**: Bin values not equal to 32767

**Solutions**:
1. **Small differences (±10)**: Normal quantization error, acceptable
2. **Large differences (>100)**: Check:
   - Correct FFT module is instantiated
   - Input signal is correct (impulse at index 0)
   - No compilation warnings

---

## Advanced Experiments

### Experiment 1: Visualize Intermediate Stages

Add internal signals to waveform:

1. In Objects, expand `uut` (the FFT core)
2. Add signals:
   - `stage0_real_out[255:0]` (output of stage 0)
   - `stage1_real_out[255:0]` (output of stage 1)
3. Run simulation
4. Observe how data transforms through each stage

### Experiment 2: Test with Sine Wave

Edit `model_sim_tb.v` input generation (around line 45):

```verilog
// Sine wave at bin 1 frequency (1 cycle in 16 samples)
real_in[0*16 +: 16]  = 16'd0;
real_in[1*16 +: 16]  = 16'd12539;  // sin(2π×1/16)
real_in[2*16 +: 16]  = 16'd23170;  // sin(2π×2/16)
real_in[3*16 +: 16]  = 16'd30273;
real_in[4*16 +: 16]  = 16'd32767;
real_in[5*16 +: 16]  = 16'd30273;
real_in[6*16 +: 16]  = 16'd23170;
real_in[7*16 +: 16]  = 16'd12539;
real_in[8*16 +: 16]  = 16'd0;
real_in[9*16 +: 16]  = -16'd12539;
real_in[10*16 +: 16] = -16'd23170;
real_in[11*16 +: 16] = -16'd30273;
real_in[12*16 +: 16] = -16'd32767;
real_in[13*16 +: 16] = -16'd30273;
real_in[14*16 +: 16] = -16'd23170;
real_in[15*16 +: 16] = -16'd12539;
// All imaginary inputs = 0
```

**Expected Output**:
- **Bin 1**: Large magnitude (~262,000)
- **Bin 15**: Large magnitude (mirror of bin 1)
- **All other bins**: ≈ 0

### Experiment 3: Frequency Response Test

Test all 16 bins by generating sine waves at each frequency:

**For bin k**, input is: `x[n] = cos(2πkn/16)`

Create a testbench loop:
```verilog
integer k, n;
for (k = 0; k < 16; k = k + 1) begin
    // Generate sine at frequency k
    for (n = 0; n < 16; n = n + 1) begin
        real_in[n*16 +: 16] = 32767 * $cos(2*3.14159*k*n/16);
        imag_in[n*16 +: 16] = 0;
    end
    // Run FFT
    start = 1; #20; start = 0;
    wait(done);
    // Check that bin k has large magnitude
    $display("Test bin %0d: Output[%0d] = %d", k, k, real_out[k*16 +: 16]);
end
```

### Experiment 4: Benchmark Against Other Radix

Automate the comparison:

```verilog
// Run all three and compare
`define RADIX2
`include "model_sim_tb.v"
// ... run and record time

`define RADIX2_2
`include "model_sim_tb.v"
// ... run and record time

`define RADIX4
`include "model_sim_tb.v"
// ... run and record time
```

---

## Summary

You've successfully:
1. ✅ Created a ModelSim project for Radix-4 FFT
2. ✅ Compiled all necessary Verilog files
3. ✅ Configured testbench for Radix-4
4. ✅ Run simulation with impulse input
5. ✅ Verified correct FFT output
6. ✅ Measured latency (~60-80 ns, 3-4 cycles)
7. ✅ Compared performance with Radix-2 and Radix-2²

### Key Takeaways

**Algorithm**:
- ✅ **Radix-4 is the fastest** for 16-point FFT
- ✅ Uses only **2 stages** (vs. 4 for Radix-2)
- ✅ Processes **4 points per butterfly** (vs. 2 for Radix-2)

**Performance**:
- ✅ **~60% faster** than Radix-2
- ✅ **Same accuracy** as other implementations
- ✅ **Industry standard** for power-of-4 FFT sizes

**When to Use Radix-4**:
- ✅ Need **maximum performance**
- ✅ FFT size is a power of 4 (4, 16, 64, 256, ...)
- ✅ Have sufficient hardware resources
- ✅ Commercial/production designs

### Performance Summary

| Metric | Value | Rank |
|--------|-------|------|
| **Latency** | ~60-80 ns | 🥇 Best |
| **Throughput** | 1 FFT / 3-4 cycles | 🥇 Best |
| **Stages** | 2 | 🥇 Fewest |
| **Accuracy** | ±5 LSB | 🥇 Equal to others |

### Next Steps

- Try **Vivado synthesis** (README_VIVADO.md)
- Compare **FPGA resource usage** with Radix-2
- Implement **streaming mode** for continuous FFTs
- Explore **higher-order FFTs** (64-point, 256-point)

---

**Congratulations!** You've mastered the most efficient FFT algorithm for 16-point transforms. Radix-4 is the foundation for high-performance DSP systems worldwide.
