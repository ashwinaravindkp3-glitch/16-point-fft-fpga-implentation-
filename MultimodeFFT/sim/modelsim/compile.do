# compile.do
# Create work library
vlib work

# Compile common modules
vlog -work work ../../rtl/common/complex_adder.v
vlog -work work ../../rtl/common/complex_subtractor.v
vlog -work work ../../rtl/common/complex_multiplier.v
vlog -work work ../../rtl/common/register_bank.v

# Compile radix2 modules
vlog -work work ../../rtl/radix2/twiddle_rom_radix2.v
vlog -work work ../../rtl/radix2/butterfly_radix2.v
vlog -work work ../../rtl/radix2/control_radix2.v
vlog -work work ../../rtl/radix2/fft_radix2_top.v

# Compile testbench
vlog -work work ../../tb/integration_tests/tb_fft_radix2_top.v

puts "Compilation complete!"
