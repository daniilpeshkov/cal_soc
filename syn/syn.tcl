
set_device -name "GW1NR-9" "GW1NR-LV9QN88PC6/I5"

# Top level
add_file -type verilog "../rtl/calsoc_top.sv"

# CPU
add_file -type verilog "../rtl/picorv/picorv32.v"

# Memory modules
add_file -type verilog "../rtl/mem/wb_ram_sc_sw.v"
add_file -type verilog "../rtl/mem/wb_ram.v"
add_file -type verilog "../rtl/mem/wb_rom.v"

# UART
add_file -type verilog "../rtl/wbuart/rxuart.v"
add_file -type verilog "../rtl/wbuart/txuart.v"
add_file -type verilog "../rtl/wbuart/ufifo.v"
add_file -type verilog "../rtl/wbuart/wbuart.v"

# Wishbone crossbar
add_file -type verilog "../rtl/wbxbar/addrdecode.v"
add_file -type verilog "../rtl/wbxbar/skidbuffer.v"
add_file -type verilog "../rtl/wbxbar/wbxbar.v"

# GPIO
add_file -type verilog "../rtl/gpio/gpio_defines.v"
add_file -type verilog "../rtl/gpio/gpio_top.v"

# Measure Unit
add_file -type verilog "../rtl/measure_unit/ch_measure_ctl.sv"
add_file -type verilog "../rtl/measure_unit/stb_gen.sv"
add_file -type verilog "../rtl/measure_unit/measure_unit.sv"
add_file -type verilog "../rtl/measure_unit/dac_spi/clk_divider.sv"
add_file -type verilog "../rtl/measure_unit/dac_spi/spi_master_o.sv"

# PLL
add_file -type verilog "../rtl/gowin_rpll/gowin_rpll.v"

# Pins
add_file -type cst "./calsoc.cst"

# Timing constrains
add_file -type sdc "./calsoc.sdc"

set_option -output_base_name "calsoc"

set_option -verilog_std "sysv2017"
set_option -top_module "calsoc_top"

run all