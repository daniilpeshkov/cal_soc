.PHONY: all clean

# iverilog -o test2_stb_gen.vvp -g2005-sv tb2_stb_gen.sv stb_gen.sv sync_ff.sv
# iverilog -o test_measure_ctl.vvp -g2005-sv ch_measure_ctl.sv \
# tb_ch_measure_ctl.sv dac_spi/clk_divider.sv \
# dac_spi/spi_master_o.sv stb_gen.sv sync_ff.sv
# iverilog -o test_measure_unit.vvp -g2005-sv tb_measure_unit.sv \
# measure_unit.sv dac_spi/clk_divider.sv dac_spi/spi_master_o.sv \
# ch_measure_ctl.sv stb_gen.sv sync_ff.sv

all: ch_ctl stb_gen stb_gen2

ch_ctl:
	iverilog -o test_measure_ctl.vvp -g2005-sv tb_ch_measure_ctl.sv
	vvp -n test_measure_ctl.vvp

stb_gen:
	iverilog -o test_stb_gen.vvp -g2005-sv tb_stb_gen.sv 
	vvp -n test_stb_gen.vvp 

stb_gen2:
	iverilog -o test_stb_gen2.vvp -g2005-sv tb2_stb_gen.sv 
	vvp -n test_stb_gen2.vvp 

sc_fifo:
	iverilog -o test_sc_fifo.vvp -g2005-sv tb_sc_fifo.sv 
	vvp -n test_sc_fifo.vvp 

clean:
	rm *.vvp