vlib work
vlog RAM.v CONTROL.v CONTROL_tb.v CASH.v
vsim -voptargs=+acc work.CONTROL_tb
add wave *
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/cache_inst/hit
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/cache_inst/Data
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/cache_inst/Tag
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/cache_inst/Valid
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/ram_inst/mem
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/next_state
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/state
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/ram_rdata
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/ram_re
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/ram_we
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/ram_rdata_reg
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/loade
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/cache_enable
add wave -position insertpoint  \
sim:/CONTROL_tb/dut/hit_q


run -all
