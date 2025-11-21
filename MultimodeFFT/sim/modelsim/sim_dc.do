# sim_dc.do
# Run DC signal FFT test

vsim -voptargs="+acc" work.tb_fft_dc_signal

# Add waves
add wave -radix decimal sim:/tb_fft_dc_signal/clk
add wave -radix decimal sim:/tb_fft_dc_signal/rst_n
add wave -radix decimal sim:/tb_fft_dc_signal/start
add wave -radix decimal sim:/tb_fft_dc_signal/done
add wave -radix decimal sim:/tb_fft_dc_signal/valid
add wave -radix decimal sim:/tb_fft_dc_signal/data_in_real
add wave -radix decimal sim:/tb_fft_dc_signal/data_out_real

run -all
