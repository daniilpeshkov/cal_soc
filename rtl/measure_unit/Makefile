.PHONY: all clean

all:
	iverilog -o test_stb_gen.vvp -g2005-sv tb_stb_gen.sv stb_gen.sv 
	iverilog -o test_measure_ctl.vvp -g2005-sv ch_measure_ctl.sv tb_ch_measure_ctl.sv dac_spi/clk_divider.sv dac_spi/spi_master_o.sv stb_gen.sv
	iverilog -o test_measure_unit.vvp -g2005-sv measure_unit.sv dac_spi/clk_divider.sv dac_spi/spi_master_o.sv ch_measure_ctl.sv stb_gen.sv
