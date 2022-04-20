
module measure_unit #(
	parameter DAC_SPI_CLK_DIV = 3,
	parameter DAC_SPI_WAIT_CYCLES = 3,
	parameter STROBE_ZERO_HOLD_CYCLES = 3,
   	parameter STROBE_GEN_CNT_WIDTH = 32
) (
//Wihbone
	input   logic        wb_clk_i,
	input   logic        wb_rst_i,			
	input   logic [31:0] wb_dat_i,   
	output  logic [31:0] wb_dat_o,
	input   logic [31:0] wb_adr_i,
	input   logic	 	 wb_we_i,
	input   logic [3:0]  wb_sel_i,
	input   logic	 	 wb_cyc_i,
	input   logic	 	 wb_stb_i,
	output  logic 		 wb_ack_o,
//DAC
	output dac1_sync_o, dac2_sync_o,
	output dac1_sclk_o, dac2_sclk_o,
	output dac1_sdi_o, 	dac2_sdi_o,
//Delay Line
	output logic [9:0] delay1_code_o, delay2_code_o,
	output logic 	   delay1_stb_o, delay2_stb_o,
//CMP
	input logic cmp1_out_i, cmp2_out_i
);

	localparam DAC_DATA_WIDTH = 24;
	localparam DAC_CODE_WIDTH = 16;
	logic [DAC_CODE_WIDTH-1 : 0] ctl1_dac_code, ctl2_dac_code;
	logic ctl1_dac_wre, ctl2_dac_wre;
	logic ctl1_dac_rdy, ctl2_dac_rdy;
	logic internal_stb;

    logic [15:0] ctl_threshold_delta = 1;
    logic [9:0] ctl_d_code_delta_i = 1;

	logic ctl_run;

	assign delay1_stb_o = internal_stb;
	assign delay2_stb_o = internal_stb;

	spi_master_o #(
		.DATA_WIDTH	(DAC_DATA_WIDTH),
		.CLK_DIV 	(DAC_SPI_CLK_DIV),
		.WAIT_CYCLES(DAC_SPI_WAIT_CYCLES)
	) dac1_spi_inst (
		.clk_i 	(wb_clk_i),
		.arst_i	(wb_rst_i),
		.data_i	({4'b0011, ctl1_dac_code, 4'b0000}),
		.wre_i	(ctl1_dac_wre),
		.rdy_o	(ctl1_dac_rdy),
		.sdi_o	(dac1_sdi_o),
		.sclk_o	(dac1_sclk_o),
		.sync_o	(dac1_sync_o)
	);

	spi_master_o #(
		.DATA_WIDTH	(DAC_DATA_WIDTH),
		.CLK_DIV 	(DAC_SPI_CLK_DIV),
		.WAIT_CYCLES(DAC_SPI_WAIT_CYCLES)
	) dac2_spi_inst (
		.clk_i 	(wb_clk_i),
		.arst_i	(wb_rst_i),
		.data_i	({4'b0011, ctl2_dac_code, 4'b0000}),
		.wre_i	(ctl2_dac_wre),
		.rdy_o	(ctl2_dac_rdy),
		.sdi_o	(dac2_sdi_o),
		.sclk_o	(dac2_sclk_o),
		.sync_o	(dac2_sync_o)
	);

	ch_measure_ctl ch_ctl1_inst(
		.clk_i 					(wb_clk_i),
		.arst_i					(wb_rst_i),
    	.stb_i					(internal_stb),
    	.cmp_out_i				(cmp1_out_i),
    	.threshold_delta_i 		(ctl_threshold_delta),
    	.d_code_delta_i			(ctl_d_code_delta_i),
    	.threshold_o			(ctl1_dac_code),
    	.threshold_wre_o		(ctl1_dac_wre),
    	.threshold_rdy_i		(ctl1_dac_rdy),
    	.d_code_o				(delay1_code_o),
    	.run_i					(ctl_run),
    	.point_rdy_o			(),
    	.point_v_o				(),
    	.point_t_o				()
	);

	ch_measure_ctl ch_ctl2_inst(
		.clk_i 					(wb_clk_i),
		.arst_i					(wb_rst_i),
    	.stb_i					(internal_stb),
    	.cmp_out_i				(cmp2_out_i),
    	.threshold_delta_i 		(ctl_threshold_delta),
    	.d_code_delta_i			(ctl_d_code_delta_i),
    	.threshold_o			(ctl2_dac_code),
    	.threshold_wre_o		(ctl2_dac_wre),
    	.threshold_rdy_i		(ctl2_dac_rdy),
    	.d_code_o				(delay2_code_o),
    	.run_i					(ctl_run),
    	.point_rdy_o			(),
    	.point_v_o				(),
    	.point_t_o				()
	);

	logic stb_gen_cmp_sel = 0;
	logic stb_gen_run = 0;
	logic stb_gen_oe = 1;
	logic stb_gen_err;
	logic stb_gen_rdy;

	stb_gen #(
   		.ZERO_HOLD_CYCLES	(STROBE_ZERO_HOLD_CYCLES),
   		.T_CNT_WIDTH		(STROBE_GEN_CNT_WIDTH)
	) stb_gen_inst (
		.clk_i 		(wb_clk_i),
		.arst_i		(wb_rst_i),
		.sig_i		(stb_gen_cmp_sel ? cmp2_out_i : cmp1_out_i),
   		.run_det_i	(stb_gen_run),
   		.oe_i		(stb_gen_oe),
   		.err_o		(stb_gen_err),
   		.rdy_o		(stb_gen_rdy),
		.stb_o		(internal_stb)
	);

endmodule