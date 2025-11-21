# Radix-2² FFT Implementation - ModelSim Simulation Tutorial

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Understanding Radix-2² FFT](#understanding-radix-2-fft)
4. [Project Setup](#project-setup)
5. [Running the Simulation](#running-the-simulation)
6. [Understanding the Output](#understanding-the-output)
7. [Comparing with Radix-2](#comparing-with-radix-2)
8. [Troubleshooting](#troubleshooting)

---

## Introduction

This tutorial will guide you through simulating a 16-point FFT using the **Radix-2²** (Radix-2-Squared) algorithm in **ModelSim**. This is an intermediate algorithm between Radix-2 and Radix-4.

### What is Radix-2² FFT?
- **Radix-2²** decomposes a 16-point FFT into **2 stages** (like Radix-4)
- Each stage processes **4 points at a time** (using nested Radix-2 butterflies)
- **Faster** than standard Radix-2 (2 stages instead of 4)
- **Same efficiency** as Radix-4 but different structure
- Good for understanding algorithm trade-offs

### Why Use Radix-2²?
- **Learning**: Bridges the gap between Radix-2 and Radix-4 concepts
- **Optimization**: Can be optimized differently than Radix-4
- **Flexibility**: Easier to extend to mixed-radix designs

---

## Prerequisites

### Software Required
- **ModelSim** (Intel/Altera Edition or SE/PE/DE versions)
- This FFT project files

### Files You'll Need
Located in the project directories:
- `model_sim_tb.v` - Testbench (in root folder)
- `radix2_2/fft_radix2_2_top.v` - Top module
- `radix2_2/butterfly_radix2_2.v` - Radix-2² butterfly unit
- `radix2_2/control_radix2_2.v` - Control FSM
- `radix2_2/twiddle_rom_radix2_2.v` - Twiddle factor memory
- `common/complex_adder.v` - Complex adder
- `common/complex_subtractor.v` - Complex subtractor
- `common/complex_multiplier.v` - Complex multiplier
- `common/register_bank.v` - Register bank

---

## Understanding Radix-2² FFT

### Algorithm Overview

**Radix-2² = Two nested Radix-2 operations**

For a 16-point FFT:
- **Stage 0**: Process indices {0,4,8,12}, {1,5,9,13}, {2,6,10,14}, {3,7,11,15}
- **Stage 1**: Process indices {0,1,2,3}, {4,5,6,7}, {8,9,10,11}, {12,13,14,15}

### Radix-2² Butterfly Operation

Each butterfly processes **4 inputs → 4 outputs**:

```
Stage 1: Horizontal Radix-2 butterflies
    x0 ──(+)──── t0
           │
    x2 ──(-)──── t1

    x1 ──(+)──── t2
           │
    x3 ──(-)──── t3

Stage 2: Vertical Radix-2 butterflies
    t0 ──(+)──── y0
           │
    t2 ──(-)──── y2

    t1 ──(+)──── y1
           │
   -j×t3 ─(-)─── y3

Stage 3: Twiddle factor multiplication
    y0 (no multiplication)
    y1 × W1
    y2 × W2
    y3 × W3
```

### Comparison with Radix-2 and Radix-4

| Feature | Radix-2 | Radix-2² | Radix-4 |
|---------|---------|----------|---------|
| **Stages** | 4 | 2 | 2 |
| **Butterflies/stage** | 8 | 4 | 4 |
| **Butterfly complexity** | Simple (2→2) | Medium (4→4) | Medium (4→4) |
| **Total cycles** | ~8 | ~4 | ~4 |
| **Algorithm** | Pure DIF-2 | Nested DIF-2 | Pure DIF-4 |

### Test Input (Impulse)
The testbench sends an **impulse signal**:
- Input[0] = 32767 (maximum positive value)
- Input[1..15] = 0

**Expected Output**: All 16 bins should be approximately equal to 32767

---

## Project Setup

### Step 1: Launch ModelSim

1. Open **ModelSim** from your Start Menu or Applications folder
2. You'll see the main ModelSim window

### Step 2: Create a New Project

1. Click **File → New → Project**
2. A "Create Project" dialog appears:
   - **Project Name**: `radix2_2_fft`
   - **Project Location**: Browse to your project folder (e.g., `/home/user/16-point-fft-fpga-implentation-/radix2_2`)
   - **Default Library Name**: Leave as `work`
3. Click **OK**

### Step 3: Add Project Files

An "Add Items to Project" window will appear.

**Add files in this order:**

1. Click **Add Existing File** for each:
   ```
   ../common/complex_adder.v
   ../common/complex_subtractor.v
   ../common/complex_multiplier.v
   ../common/register_bank.v
   ./butterfly_radix2_2.v
   ./control_radix2_2.v
   ./twiddle_rom_radix2_2.v
   ./fft_radix2_2_top.v
   ../model_sim_tb.v
   ```

2. For each file:
   - Browse to the file location
   - Ensure **File Type** is "Verilog"
   - Click **OK**

3. When all files are added, click **Close**

### Step 4: Verify File List

In the **Library** tab (left pane), verify all 9 files are listed under `work`.

---

## Running the Simulation

### Step 5: Compile the Design

1. In the **Library** tab, right-click on the `work` library
2. Select **Compile → Compile All**
3. Watch the **Transcript** window for compilation messages
4. You should see:
   ```
   # Compile of complex_adder.v was successful.
   # Compile of complex_subtractor.v was successful.
   ...
   # 9 compiles, 0 failed with no errors.
   ```

**If you see errors**: Check [Troubleshooting](#troubleshooting) section

### Step 6: Configure Testbench for Radix-2²

**CRITICAL STEP**: Configure the testbench to use Radix-2²:

1. Double-click `model_sim_tb.v` in the Library tab to open it
2. Find line ~30 (the FFT instantiation)
3. **Make sure it says**:
   ```verilog
   fft_radix2_2_top uut (
   ```

4. If it says `fft_radix2_top` or `fft_radix4_top`, **change it** to:
   ```verilog
   fft_radix2_2_top uut (
   ```

5. Save the file (Ctrl+S)
6. Recompile: **Compile → Compile All**

### Step 7: Start Simulation

1. Click **Simulate → Start Simulation**
2. In the "Start Simulation" dialog:
   - Expand the `work` library
   - Select `model_sim_tb`
   - Click **OK**

3. The simulation loads successfully

### Step 8: Add Signals to Waveform

1. In the **Objects** window, select these signals:
   - `clk`
   - `rst`
   - `start`
   - `done`
   - `real_out[255:0]`
   - `imag_out[255:0]`

2. Right-click → **Add Wave**

### Step 9: Run the Simulation

In the Transcript window, type:
```tcl
run 500 ns
```
Press **Enter**.

### Step 10: View Results

1. Check the **Transcript** window for the output table
2. In the **Wave** window, click **Zoom Full** to see all waveforms

---

## Understanding the Output

### Expected Transcript Output

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

### Why All Bins Are Equal

**Input = Impulse** (delta function)
- FFT of impulse = **flat spectrum** (all frequencies present equally)
- Each bin = 32767 (input amplitude)

### Acceptable Variations

Due to **fixed-point arithmetic**:
- Bin values between **32760-32775** are acceptable
- Imaginary parts between **-10 to +10** are acceptable
- Larger errors indicate problems

### Waveform Analysis

In the **Wave** window, observe:

1. **Clock**: Steady 20ns period
2. **Reset**: Pulse high at start, then low
3. **Start**: Brief pulse to initiate FFT
4. **Done**: Goes high after ~100-150 ns (much faster than Radix-2!)
5. **Outputs**: Stabilize when done goes high

**Timing Observation**:
- **Radix-2**: Done at ~200 ns (4 stages)
- **Radix-2²**: Done at ~120 ns (2 stages)
- **Speed improvement**: ~40% faster! ⚡

---

## Comparing with Radix-2

### Performance Comparison

Run both simulations and compare:

| Metric | Radix-2 | Radix-2² | Improvement |
|--------|---------|----------|-------------|
| **Stages** | 4 | 2 | 50% fewer |
| **Latency** | ~200 ns | ~120 ns | 40% faster |
| **Accuracy** | ±5 LSB | ±5 LSB | Same |
| **Complexity** | Low | Medium | Moderate increase |

### When to Use Each

**Use Radix-2 when**:
- Learning FFT basics
- Need simplest logic
- FPGA resources are very limited

**Use Radix-2² when**:
- Need better performance than Radix-2
- Want to understand nested algorithms
- Exploring mixed-radix optimizations

**Use Radix-4 when**:
- Need maximum performance
- Have sufficient FPGA resources
- Standard Radix-4 optimizations are well-known

---

## Troubleshooting

### Problem: Compilation Errors

**Error**: `Undefined module: fft_radix2_2_top`

**Solution**:
- Ensure `fft_radix2_2_top.v` is added to the project
- Check the file path is correct
- Verify the module name matches in the file

---

**Error**: `File not found: butterfly_radix2_2.v`

**Solution**:
- Use correct relative path: `./butterfly_radix2_2.v`
- Or browse to the file using absolute path

---

### Problem: Wrong FFT Module in Testbench

**Symptom**: Compile error about undefined module

**Solution**:
- Open `model_sim_tb.v`
- Line 30 must say `fft_radix2_2_top uut (`
- Save and recompile

---

### Problem: Simulation Produces Wrong Results

**Symptom**: Output values are wrong or all zero

**Solution**:
1. Check that `done` signal goes high (in waveform)
2. Verify `start` pulse occurs
3. Make sure simulation ran long enough (500 ns minimum)
4. Restart simulation: Type `restart -f` then `run 500 ns`

---

### Problem: 'X' (Unknown) Values in Output

**Possible Causes**:
- Uninitialized registers
- Testbench timing issues

**Solution**:
- Check all files compiled without warnings
- Verify reset signal pulses correctly at start
- Check clock is running (toggles in waveform)

---

### Problem: Simulation Too Slow

**Symptom**: Takes long time to simulate

**Solution**:
- ModelSim might be in GUI mode slowing things down
- Minimize waveform updates by running longer intervals
- Close schematic views

---

## Advanced Experiments

### Experiment 1: Measure Exact Latency

Add this to the testbench after line 40:

```verilog
integer start_time, end_time, latency;

initial begin
    ...
    @(posedge start);
    start_time = $time;
    @(posedge done);
    end_time = $time;
    latency = end_time - start_time;
    $display("FFT Latency: %0d ns (%0d clock cycles)", latency, latency/20);
end
```

Recompile and run. You'll see exact latency in nanoseconds.

### Experiment 2: Compare All Three Radix Implementations

Run simulations with:
1. Radix-2 (change line 30 to `fft_radix2_top`)
2. Radix-2² (change line 30 to `fft_radix2_2_top`)
3. Radix-4 (change line 30 to `fft_radix4_top`)

Record latencies:
- Radix-2: ~____ ns
- Radix-2²: ~____ ns
- Radix-4: ~____ ns

All three should produce identical outputs!

### Experiment 3: Test with DC Signal

Change testbench input (line ~45):

```verilog
// All inputs = 1000
for (i = 0; i < 16; i = i + 1) begin
    real_in[i*16 +: 16] = 16'd1000;
    imag_in[i*16 +: 16] = 16'd0;
end
```

**Expected Output**:
- Bin 0: 16000 (sum of all inputs)
- Bins 1-15: ~0

### Experiment 4: Test with Sine Wave

Input a sine wave at bin 2 frequency:

```verilog
// Values for sine at bin 2 (2 cycles in 16 samples)
integer sine_vals [0:15];
initial begin
    sine_vals[0]  = 0;
    sine_vals[1]  = 23170;
    sine_vals[2]  = 32767;
    sine_vals[3]  = 23170;
    sine_vals[4]  = 0;
    sine_vals[5]  = -23170;
    sine_vals[6]  = -32767;
    sine_vals[7]  = -23170;
    sine_vals[8]  = 0;
    sine_vals[9]  = 23170;
    sine_vals[10] = 32767;
    sine_vals[11] = 23170;
    sine_vals[12] = 0;
    sine_vals[13] = -23170;
    sine_vals[14] = -32767;
    sine_vals[15] = -23170;
end

// Apply to inputs
for (i = 0; i < 16; i = i + 1) begin
    real_in[i*16 +: 16] = sine_vals[i];
    imag_in[i*16 +: 16] = 16'd0;
end
```

**Expected Output**:
- Large spike at Bin 2 (and Bin 14, which is the mirror)
- All other bins ≈ 0

---

## Summary

You've successfully:
1. ✅ Created a ModelSim project for Radix-2² FFT
2. ✅ Compiled all necessary Verilog files
3. ✅ Configured the testbench correctly
4. ✅ Run simulation and verified output
5. ✅ Understood the Radix-2² algorithm
6. ✅ Compared performance with Radix-2

### Key Takeaways
- **Radix-2²** uses **2 stages** (vs. 4 for Radix-2)
- **40% faster** latency than Radix-2
- **Same accuracy** as other implementations
- **Nested Radix-2** butterflies, not pure Radix-4
- **Good middle ground** for learning and optimization

### Algorithm Complexity

| Algorithm | Stages | Butterflies | Multiplications |
|-----------|--------|-------------|-----------------|
| Radix-2   | 4      | 8 per stage | 32 total |
| Radix-2²  | 2      | 4 per stage | 32 total |
| Radix-4   | 2      | 4 per stage | 32 total |

All use the same number of complex multiplications, but fewer stages = lower latency!

### Next Steps
- Try **Vivado synthesis** tutorial (README_VIVADO.md)
- Compare hardware resource usage with Radix-2 and Radix-4
- Experiment with different input signals
- Study the butterfly implementation details

---

**Need Help?** Check the Troubleshooting section or compare your setup with the Radix-2 tutorial.
