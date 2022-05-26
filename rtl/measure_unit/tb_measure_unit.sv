`timescale 1ns/1ns

`define DUMPVARS
// `undef DUMPVARS    

module tb_measure_unit ();
    
    localparam CLK_T = 8; // clk period

	logic		hclk_i;
	logic        wb_clk_i;
	logic        wb_rst_i;
	logic [31:0] wb_dat_i;
	logic [31:0] wb_dat_o;
	logic [31:0] wb_adr_i;
	logic	 	 wb_we_i;
	logic [3:0]  wb_sel_i;
	logic	 	 wb_cyc_i;
	logic	 	 wb_stb_i;
	logic 		 wb_ack_o;

	logic dac1_sync_o, dac2_sync_o;
	logic dac1_sclk_o, dac2_sclk_o;
	logic dac1_sdi_o, 	dac2_sdi_o;

	logic [9:0] delay1_code_o, delay2_code_o;
	logic 	    delay1_stb_o, delay2_stb_o;

	logic cmp1_out_i = 0, cmp2_out_i = 0;

endmodule