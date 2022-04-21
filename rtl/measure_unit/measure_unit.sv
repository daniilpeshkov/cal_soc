
module measure_unit #(
	parameter DAC_SPI_CLK_DIV = 3,
	parameter DAC_SPI_WAIT_CYCLES = 3,
	parameter STROBE_ZERO_HOLD_CYCLES = 3,
   	parameter STROBE_GEN_CNT_WIDTH = 32,
	parameter DEFAULT_DELAY_CODE_DELTA = 10'h1,
	parameter DEFAULT_THRESHOLD_DELTA = 16'h1
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
	localparam CH_CTL_DELTA_REG = 0;


	localparam DAC_DATA_WIDTH = 24;
	localparam DAC_CODE_WIDTH = 16;

	logic [DAC_CODE_WIDTH-1 : 0] ctl1_dac_code, ctl2_dac_code;
	logic ctl1_dac_wre, ctl2_dac_wre;
	logic ctl1_dac_rdy, ctl2_dac_rdy;
	logic internal_stb;

	logic [25:0] ch_ctl_delta_reg;

    logic [15:0] ctl_threshold_delta;
    logic [9:0] ctl_d_code_delta;

	assign ctl_threshold_delta = ch_ctl_delta_reg[15:0];
	assign ctl_d_code_delta = ch_ctl_delta_reg[25:16];

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
    	.d_code_delta_i			(ctl_d_code_delta),
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
    	.d_code_delta_i			(ctl_d_code_delta),
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
///////////////////////////////////////////////////////////////////////////////////////
//Wishbone logic	
	logic [31:0] w_data;
	logic [31:0] byte_mask;

	assign byte_mask = {(wb_sel_i[3] ? 8'hFF : 8'h0), (wb_sel_i[2] ? 8'hFF : 8'h0), (wb_sel_i[1] ? 8'hFF : 8'h0) ,(wb_sel_i[0] ? 8'hFF : 8'h0)};	

	always_comb begin
		logic [31:0] w_reg;
		case (wb_adr_i)
			CH_CTL_DELTA_REG: w_reg = ch_ctl_delta_reg;
		endcase
		w_data = w_reg & byte_mask;
	end

	always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin
		if (wb_rst_i) begin
			ch_ctl_delta_reg = {DEFAULT_DELAY_CODE_DELTA, DEFAULT_THRESHOLD_DELTA};
		end else begin
			wb_ack_o <= 0;
			if (wb_cyc_i && wb_stb_i) begin
				wb_ack_o <= 1;
				case (wb_adr_i)
					CH_CTL_DELTA_REG: begin
						if (wb_we_i) begin
							ch_ctl_delta_reg <= w_data;
						end else begin
							wb_dat_o <= ch_ctl_delta_reg;
						end
					end
				endcase
			end
		end
	end

endmodule