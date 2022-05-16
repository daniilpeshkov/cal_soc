.PHONY: all clean

all:
	iverilog -o test2_stb_gen.vvp -g2005-sv tb2_stb_gen.sv stb_gen.sv sync_ff.sv
	iverilog -o test_measure_ctl.vvp -g2005-sv ch_measure_ctl.sv \
	 		tb_ch_measure_ctl.sv dac_spi/clk_divider.sv \
			dac_spi/spi_master_o.sv stb_gen.sv sync_ff.sv
	iverilog -o test_measure_unit.vvp -g2005-sv tb_measure_unit.sv \
	 		measure_unit.sv dac_spi/clk_divider.sv dac_spi/spi_master_o.sv \
			ch_measure_ctl.sv stb_gen.sv sync_ff.sv
stb_gen:
	iverilog -o test_stb_gen.vvp -g2005-sv stb_gen.sv tb_stb_gen.sv sync_ff.sv 
	vvp test_stb_gen.vvp 

clean:
	rm *.vvp