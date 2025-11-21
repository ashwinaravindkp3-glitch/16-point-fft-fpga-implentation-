# sim_butterfly.do
# Run butterfly unit test

vsim -voptargs="+acc" work.tb_butterfly_radix2

# Add waves
add wave -radix decimal sim:/tb_butterfly_radix2/clk
add wave -radix decimal sim:/tb_butterfly_radix2/rst_n
add wave -radix decimal sim:/tb_butterfly_radix2/enable
add wave -radix decimal sim:/tb_butterfly_radix2/x0_real
add wave -radix decimal sim:/tb_butterfly_radix2/x1_real
add wave -radix decimal sim:/tb_butterfly_radix2/dut/sum_real
add wave -radix decimal sim:/tb_butterfly_radix2/dut/diff_real
add wave -radix decimal sim:/tb_butterfly_radix2/y0_real
add wave -radix decimal sim:/tb_butterfly_radix2/y1_real
add wave -radix decimal sim:/tb_butterfly_radix2/valid

run -all
