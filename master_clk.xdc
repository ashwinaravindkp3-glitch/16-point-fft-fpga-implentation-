## ----------------------------------------------------------------------------
## GENERIC TIMING CONSTRAINTS (For XC7A25T)
## ----------------------------------------------------------------------------
## We are strictly defining the physics (Timing), not the geography (Pins).

# 1. Define the Clock (50 MHz = 20ns)
# We do NOT assign a PACKAGE_PIN. Vivado will pick a random one for us.
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports clk]

# 2. Input Delays (Standard 2ns safety margin)
set_input_delay -clock [get_clocks sys_clk_pin] -min -add_delay 1.00 [get_ports rst_n]
set_input_delay -clock [get_clocks sys_clk_pin] -max -add_delay 2.00 [get_ports rst_n]
set_input_delay -clock [get_clocks sys_clk_pin] -min -add_delay 1.00 [get_ports {bin_sel[*]}]
set_input_delay -clock [get_clocks sys_clk_pin] -max -add_delay 2.00 [get_ports {bin_sel[*]}]

# 3. Output Delays
set_output_delay -clock [get_clocks sys_clk_pin] -min -add_delay 0.00 [get_ports {leds_real[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -max -add_delay 2.00 [get_ports {leds_real[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -min -add_delay 0.00 [get_ports {leds_imag[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -max -add_delay 2.00 [get_ports {leds_imag[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -min -add_delay 0.00 [get_ports done_led]
set_output_delay -clock [get_clocks sys_clk_pin] -max -add_delay 2.00 [get_ports done_led]
