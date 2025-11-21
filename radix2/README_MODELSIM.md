# Radix-2 FFT Implementation - ModelSim Simulation Tutorial

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Understanding Radix-2 FFT](#understanding-radix-2-fft)
4. [Project Setup](#project-setup)
5. [Running the Simulation](#running-the-simulation)
6. [Understanding the Output](#understanding-the-output)
7. [Troubleshooting](#troubleshooting)

---

## Introduction

This tutorial will guide you through simulating a 16-point FFT (Fast Fourier Transform) using the **Radix-2** algorithm in **ModelSim**. We'll start from scratch, assuming you have zero experience with ModelSim.

### What is Radix-2 FFT?
- **Radix-2** is the simplest FFT algorithm
- For a 16-point FFT, it uses **4 stages** (since 2^4 = 16)
- Each stage processes the data using "butterfly" operations
- It's slower than Radix-4 but easier to understand

---

## Prerequisites

### Software Required
- **ModelSim** (Intel/Altera Edition or SE/PE/DE versions)
- This FFT project files

### Files You'll Need
Located in the project directories:
- `model_sim_tb.v` - Testbench (in root folder)
- `radix2/fft_radix2_top.v` - Top module
- `radix2/butterfly_radix2.v` - Butterfly unit
- `radix2/control_radix2.v` - Control FSM
- `radix2/twiddle_rom_radix2.v` - Twiddle factor memory
- `common/complex_adder.v` - Complex adder
- `common/complex_subtractor.v` - Complex subtractor
- `common/complex_multiplier.v` - Complex multiplier
- `common/register_bank.v` - Register bank

---

## Understanding Radix-2 FFT

### How It Works
1. **Input**: 16 complex numbers (each has real and imaginary parts)
2. **Processing**: Data flows through 4 stages
3. **Each Stage**: Uses 8 radix-2 butterflies
4. **Output**: 16 frequency bins

### Radix-2 Butterfly Operation
```
        x0 ──────(+)──────> y0 = x0 + x1
                  │
        x1 ──(×W)─(-)──────> y1 = (x0 - x1) × W
```
Where W is a "twiddle factor" (rotation in complex plane)

### Test Input (Impulse)
The testbench sends an **impulse signal**:
- Input[0] = 32767 (maximum positive value)
- Input[1..15] = 0

**Expected Output**: All 16 bins should be approximately equal to 32767

---

## Project Setup

### Step 1: Launch ModelSim

1. Open **ModelSim** from your Start Menu or Applications folder
2. You'll see the main ModelSim window with:
   - Menu bar at top
   - Workspace/Library pane on left
   - Transcript window at bottom (command line)
   - Main viewing area in center

### Step 2: Create a New Project

1. Click **File → New → Project**
2. A "Create Project" dialog appears:
   - **Project Name**: `radix2_fft`
   - **Project Location**: Browse to your project folder (e.g., `/home/user/16-point-fft-fpga-implentation-/radix2`)
   - **Default Library Name**: Leave as `work`
3. Click **OK**

### Step 3: Add Project Files

An "Add Items to Project" window will appear.

**Add files in this order:**

1. Click **Add Existing File**
2. Navigate and add:
   ```
   ../common/complex_adder.v
   ../common/complex_subtractor.v
   ../common/complex_multiplier.v
   ../common/register_bank.v
   ./butterfly_radix2.v
   ./control_radix2.v
   ./twiddle_rom_radix2.v
   ./fft_radix2_top.v
   ../model_sim_tb.v
   ```
3. For each file:
   - Click **Add Existing File**
   - Browse to the file
   - Make sure **File Type** is "Verilog"
   - Click **OK**

4. When all files are added, click **Close** on the "Add Items" window

### Step 4: Verify File List

In the **Library** tab (left pane), you should see all 9 files listed under `work`.

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

### Step 6: Check Testbench Configuration

**IMPORTANT**: Before simulating, verify the testbench is configured for Radix-2:

1. Double-click `model_sim_tb.v` in the Library tab to open it
2. Find line ~30 (the FFT instantiation)
3. Make sure it says:
   ```verilog
   fft_radix2_top uut (
   ```
   NOT `fft_radix4_top` or `fft_radix2_2_top`

4. If it's wrong, change it and recompile (**Compile → Compile All**)

### Step 7: Start Simulation

1. Click **Simulate → Start Simulation**
2. In the "Start Simulation" dialog:
   - Expand the `work` library in the "Design" tab
   - Select `model_sim_tb` (the testbench)
   - Click **OK**

3. The simulation loads, and you'll see:
   - **Objects** window showing signals
   - **Wave** window (might be empty)
   - Transcript shows: `# vsim work.model_sim_tb`

### Step 8: Add Signals to Waveform

To see what's happening:

1. In the **Objects** window, select these signals:
   - `clk`
   - `rst`
   - `start`
   - `done`
   - `real_out[255:0]`
   - `imag_out[255:0]`

2. Right-click and select **Add Wave**

3. The signals appear in the **Wave** window

### Step 9: Run the Simulation

1. In the Transcript window (bottom), type:
   ```tcl
   run 500 ns
   ```
   Then press **Enter**

2. Or use the toolbar buttons:
   - Click the **Run** button and enter `500 ns`

3. Watch the **Transcript** window for the output table (see next section)

### Step 10: View Waveforms

1. In the **Wave** window, click the **Zoom Full** button (binoculars icon)
2. You'll see:
   - Clock toggling
   - Reset pulse at the start
   - Start pulse
   - Done signal going high after computation
   - Real and imaginary outputs changing

---

## Understanding the Output

### Transcript Window Output

After the simulation runs, you'll see a table like this:

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

### What This Means

**Input Signal**: Impulse (single spike at time 0)
- Time 0: Value = 32767
- Time 1-15: Value = 0

**FFT Property**: The FFT of an impulse is a **flat spectrum**
- All frequencies contain equal energy
- Each bin = 32767 (the same as input amplitude)
- Imaginary parts = 0 (impulse is a real signal)

### Interpreting the Bins

| Bin | Frequency | What It Represents |
|-----|-----------|-------------------|
| 0   | DC (0 Hz) | Average value |
| 1   | f_s/16    | Lowest frequency |
| 2   | 2f_s/16   | Second harmonic |
| ... | ...       | ... |
| 7   | 7f_s/16   | Nyquist - 1 |
| 8   | f_s/2     | Nyquist frequency |
| 9-15| Negative freqs | Mirror of bins 1-7 |

Where `f_s` is the sampling frequency.

### Expected vs. Actual Values

**Ideal Output**: All bins = 32767

**Actual Output**: You might see small variations like:
- Bin 3: 32765 (off by 2)
- Bin 7: 32769 (off by 2)

**Why?**
- Fixed-point arithmetic causes **quantization errors**
- Errors of ±10 are normal and acceptable
- Errors > 100 indicate a problem

### Checking for Correctness

✅ **Good Results**:
- All real values between 32700 and 32800
- All imaginary values between -50 and +50
- No huge spikes or zeros

❌ **Bad Results**:
- Any bin = 0 (except imaginary)
- Wild variations (e.g., bin 5 = 100)
- All outputs = 0
- Simulation shows 'X' or 'Z' values

---

## Troubleshooting

### Problem: Compilation Errors

**Error**: `File not found: complex_adder.v`

**Solution**:
- Check file paths when adding files
- Use `../common/` for common files
- Use `./` for radix2 files

---

**Error**: `Undefined module: complex_adder`

**Solution**:
- Make sure `complex_adder.v` is added to the project
- Compile the common modules first

---

### Problem: Wrong FFT Module

**Error**: `Undefined module: fft_radix2_top`

**Solution**:
- Open `model_sim_tb.v`
- Line 30: Change the instantiation to `fft_radix2_top`
- Recompile

---

### Problem: No Output in Transcript

**Solution**:
- Make sure you ran for at least 500 ns
- Type `run 500 ns` in Transcript window
- Check that `done` signal went high (in Wave window)

---

### Problem: Output Values Are All Zero

**Possible Causes**:
1. **Start signal not pulsed**: Check waveform, `start` should pulse high
2. **Reset stuck high**: Check `rst` in waveform
3. **Clock not running**: Check `clk` toggles

**Solution**:
- Re-run simulation: `restart -f` then `run 500 ns`

---

### Problem: Output Values Are 'X' (Unknown)

**Possible Causes**:
- Uninitialized registers
- Setup/hold timing violations (shouldn't happen in ModelSim)

**Solution**:
- Check compilation for warnings
- Make sure all files compiled successfully

---

### Problem: Simulation Runs Forever

**Solution**:
- Click **Break** button (or press Ctrl+C in Transcript)
- Check if `done` signal is stuck low
- Common cause: start signal not pulsing correctly

---

## Advanced: Trying Different Inputs

Want to test with different inputs? Edit `model_sim_tb.v`:

### Find the Input Generation Section (around line 45):
```verilog
// Generate impulse input
for (i = 0; i < 16; i = i + 1) begin
    real_in[i*16 +: 16] = (i == 0) ? 16'd32767 : 16'd0;
    imag_in[i*16 +: 16] = 16'd0;
end
```

### Try a DC Signal (Constant):
```verilog
for (i = 0; i < 16; i = i + 1) begin
    real_in[i*16 +: 16] = 16'd1000;  // All samples = 1000
    imag_in[i*16 +: 16] = 16'd0;
end
```
**Expected**: Bin 0 = 16000, all others ≈ 0

### Try a Sine Wave (Bin 1):
```verilog
// Sine wave at bin 1 frequency
real_in[0*16 +: 16] = 16'd0;
real_in[1*16 +: 16] = 16'd12539;
real_in[2*16 +: 16] = 16'd23170;
real_in[3*16 +: 16] = 16'd30273;
real_in[4*16 +: 16] = 16'd32767;
real_in[5*16 +: 16] = 16'd30273;
real_in[6*16 +: 16] = 16'd23170;
real_in[7*16 +: 16] = 16'd12539;
real_in[8*16 +: 16] = 16'd0;
real_in[9*16 +: 16] = -16'd12539;
real_in[10*16 +: 16] = -16'd23170;
real_in[11*16 +: 16] = -16'd30273;
real_in[12*16 +: 16] = -16'd32767;
real_in[13*16 +: 16] = -16'd30273;
real_in[14*16 +: 16] = -16'd23170;
real_in[15*16 +: 16] = -16'd12539;
```
**Expected**: Large spike at Bin 1, all others ≈ 0

---

## Summary

You've successfully:
1. ✅ Created a ModelSim project for Radix-2 FFT
2. ✅ Added and compiled all necessary Verilog files
3. ✅ Run a simulation with impulse input
4. ✅ Interpreted the FFT output
5. ✅ Learned how to debug common issues

### Key Takeaways
- **Radix-2** uses 4 stages for 16-point FFT
- **Impulse input** → **Flat spectrum output**
- **All bins should be equal** for an impulse
- **Small errors** (±10) are normal in fixed-point

### Next Steps
- Try the **Vivado synthesis** tutorial (README_VIVADO.md)
- Compare with **Radix-4** (faster, 2 stages instead of 4)
- Experiment with different input signals

---

**Need Help?** Check the Troubleshooting section or review the waveforms in detail.
