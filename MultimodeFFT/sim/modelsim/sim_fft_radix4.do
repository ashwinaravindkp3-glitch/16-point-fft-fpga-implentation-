# sim_fft_radix4.do
# Run Radix-4 FFT test

vsim -voptargs="+acc" work.tb_fft_radix4_top

# Add waves
add wave -radix decimal sim:/tb_fft_radix4_top/clk
add wave -radix decimal sim:/tb_fft_radix4_top/rst_n
add wave -radix decimal sim:/tb_fft_radix4_top/start
add wave -radix decimal sim:/tb_fft_radix4_top/done
add wave -radix decimal sim:/tb_fft_radix4_top/valid
add wave -radix decimal sim:/tb_fft_radix4_top/data_in_real
add wave -radix decimal sim:/tb_fft_radix4_top/data_out_real

run -all
