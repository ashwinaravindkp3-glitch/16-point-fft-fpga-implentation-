# sim_fft.do
# Run 16-point FFT test

vsim -voptargs="+acc" work.tb_fft_radix2_top

# Add waves
add wave -radix decimal sim:/tb_fft_radix2_top/clk
add wave -radix decimal sim:/tb_fft_radix2_top/rst_n
add wave -radix decimal sim:/tb_fft_radix2_top/start
add wave -radix decimal sim:/tb_fft_radix2_top/done
add wave -radix decimal sim:/tb_fft_radix2_top/valid
add wave -radix decimal sim:/tb_fft_radix2_top/data_in_real
add wave -radix decimal sim:/tb_fft_radix2_top/data_out_real

run -all
