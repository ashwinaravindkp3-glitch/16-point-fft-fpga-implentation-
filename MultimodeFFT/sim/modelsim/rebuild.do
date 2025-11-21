# rebuild.do
# Force clean rebuild of all modules

# Quit any running simulation
quit -sim

# Delete work library
vdel -lib work -all

# Recreate and compile
vlib work
vmap work work

set PROJECT_ROOT "e:/MultimodeFFT"

puts "Compiling common modules..."
vlog -work work "$PROJECT_ROOT/rtl/common/complex_adder.v"
vlog -work work "$PROJECT_ROOT/rtl/common/complex_subtractor.v"
vlog -work work "$PROJECT_ROOT/rtl/common/complex_multiplier.v"
vlog -work work "$PROJECT_ROOT/rtl/common/register_bank.v"

puts "Compiling radix2 modules..."
vlog -work work "$PROJECT_ROOT/rtl/radix2/butterfly_radix2.v"
vlog -work work "$PROJECT_ROOT/rtl/radix2/twiddle_rom_radix2.v"
vlog -work work "$PROJECT_ROOT/rtl/radix2/control_radix2.v"
vlog -work work "$PROJECT_ROOT/rtl/radix2/fft_radix2_top.v"

puts "Compiling radix4 modules..."
vlog -work work "$PROJECT_ROOT/rtl/radix4/butterfly_radix4.v"
vlog -work work "$PROJECT_ROOT/rtl/radix4/twiddle_rom_radix4.v"
vlog -work work "$PROJECT_ROOT/rtl/radix4/control_radix4.v"
vlog -work work "$PROJECT_ROOT/rtl/radix4/fft_radix4_top.v"

puts "Compiling radix2_2 modules..."
vlog -work work "$PROJECT_ROOT/rtl/radix2_2/butterfly_radix2_2.v"
vlog -work work "$PROJECT_ROOT/rtl/radix2_2/twiddle_rom_radix2_2.v"
vlog -work work "$PROJECT_ROOT/rtl/radix2_2/control_radix2_2.v"
vlog -work work "$PROJECT_ROOT/rtl/radix2_2/fft_radix2_2_top.v"

puts "Compiling testbenches..."
vlog -work work "$PROJECT_ROOT/tb/unit_tests/tb_butterfly_radix2.v"
vlog -work work "$PROJECT_ROOT/tb/unit_tests/tb_adder_simple.v"
vlog -work work "$PROJECT_ROOT/tb/unit_tests/tb_butterfly_comprehensive.v"
vlog -work work "$PROJECT_ROOT/tb/integration_tests/tb_fft_radix2_top.v"
vlog -work work "$PROJECT_ROOT/tb/integration_tests/tb_fft_dc_signal.v"
vlog -work work "$PROJECT_ROOT/tb/integration_tests/tb_fft_radix4_top.v"
vlog -work work "$PROJECT_ROOT/tb/radix2_2/tb_fft_radix2_2_top.v"

puts "Clean rebuild complete!"
