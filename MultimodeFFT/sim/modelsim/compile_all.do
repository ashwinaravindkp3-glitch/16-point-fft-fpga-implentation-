# compile_all.do
# ModelSim compilation script for Radix-2 FFT

# Create work library
vlib work

# Set project root
set PROJECT_ROOT "e:/MultimodeFFT"

# Compile common modules
vlog -work work "$PROJECT_ROOT/rtl/common/complex_adder.v"
vlog -work work "$PROJECT_ROOT/rtl/common/complex_subtractor.v"
vlog -work work "$PROJECT_ROOT/rtl/common/complex_multiplier.v"

# Compile radix2 modules
vlog -work work "$PROJECT_ROOT/rtl/radix2/butterfly_radix2.v"

# Compile testbenches
vlog -work work "$PROJECT_ROOT/tb/unit_tests/tb_butterfly_radix2.v"
vlog -work work "$PROJECT_ROOT/tb/unit_tests/tb_adder_simple.v"

puts "Compilation complete!"
