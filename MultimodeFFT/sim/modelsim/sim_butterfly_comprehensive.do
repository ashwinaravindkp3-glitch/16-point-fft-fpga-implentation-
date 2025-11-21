# sim_butterfly_comprehensive.do
# Run comprehensive butterfly tests

vsim -voptargs="+acc" work.tb_butterfly_comprehensive

# Add key signals
add wave -radix decimal sim:/tb_butterfly_comprehensive/clk
add wave -radix decimal sim:/tb_butterfly_comprehensive/test_count
add wave -radix decimal sim:/tb_butterfly_comprehensive/x0_real
add wave -radix decimal sim:/tb_butterfly_comprehensive/x1_real
add wave -radix decimal sim:/tb_butterfly_comprehensive/tw_real
add wave -radix decimal sim:/tb_butterfly_comprehensive/y0_real
add wave -radix decimal sim:/tb_butterfly_comprehensive/y1_real

run -all
