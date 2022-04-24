
module measure_unit #(
	parameter DAC_SPI_CLK_DIV = 3,
	parameter DAC_SPI_WAIT_CYCLES = 3,
	parameter STROBE_ZERO_HOLD_CYCLES = 3,
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
///////////////////////////////////////////////////////////////////////////////////////
// Wishbone registers
///////////////////////////////////////////////////////////////////////////////////////
	localparam CH_CTL_DELTA_REG 	= 0;
	localparam STB_GEN_REG 			= 1;

///////////////////////////////////////////////////////////////////////////////////////
// CH_CTL_DELTA_REG
///////////////////////////////////////////////////////////////////////////////////////

	logic [25:0] ch_ctl_delta_reg;

	logic [15:0] ctl_threshold_delta, default_ctl_threshold_delta;

	logic [9:0] ctl_d_code_delta, default_ctl_d_code_delta;

	assign default_ctl_d_code_delta = DEFAULT_DELAY_CODE_DELTA;
	assign default_ctl_threshold_delta = DEFAULT_THRESHOLD_DELTA;

	assign ctl_threshold_delta = ch_ctl_delta_reg[15:0];
	assign ctl_d_code_delta = ch_ctl_delta_reg[25:16];
///////////////////////////////////////////////////////////////////////////////////////
// STB_GEN_REG
///////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////
	localparam DAC_DATA_WIDTH = 24;
	localparam DAC_CODE_WIDTH = 16;
	localparam STB_GEN_CNT_WIDTH = 28;

	logic [DAC_CODE_WIDTH-1 : 0] ctl1_dac_code, ctl2_dac_code;
	logic ctl1_dac_wre, ctl2_dac_wre;
	logic ctl1_dac_rdy, ctl2_dac_rdy;
	logic internal_stb;
	logic ctl_run;
	logic [STB_GEN_CNT_WIDTH-1:0] stb_period;
	logic stb_gen_cmp_sel = 0;
	logic stb_gen_run = 0;
	logic stb_gen_oe = 1;
	logic stb_gen_err;
	logic stb_gen_rdy;

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

	stb_gen #(
   		.ZERO_HOLD_CYCLES	(STROBE_ZERO_HOLD_CYCLES),
   		.T_CNT_WIDTH		(STB_GEN_CNT_WIDTH)
	) stb_gen_inst (
		.clk_i 			(wb_clk_i),
		.arst_i			(wb_rst_i),
		.sig_i			(stb_gen_cmp_sel ? cmp2_out_i : cmp1_out_i),
   		.run_det_i		(stb_gen_run),
   		.oe_i			(stb_gen_oe),
   		.err_o			(stb_gen_err),
   		.rdy_o			(stb_gen_rdy),
		.stb_o			(internal_stb),
		.stb_period_o	(stb_period)
	);

///////////////////////////////////////////////////////////////////////////////////////
//Wishbone logic	
///////////////////////////////////////////////////////////////////////////////////////

	logic [31:0] w_data;
	logic [2:0] addr;
	logic [31:0] byte_mask;

	assign addr = wb_adr_i[4:2];

	always_comb begin
		logic [31:0] w_reg;
		case (addr)
			CH_CTL_DELTA_REG: 	w_reg = ch_ctl_delta_reg;
			STB_GEN_REG:		w_reg =	{stb_gen_cmp_sel, stb_gen_run};
		endcase
		w_data[7:0] = (wb_sel_i[0] ? wb_dat_i[7:0] : w_reg[7:0]);
		w_data[15:8] = (wb_sel_i[1] ? wb_dat_i[15:8] : w_reg[15:8]);
		w_data[23:16] = (wb_sel_i[2] ? wb_dat_i[23:16] : w_reg[23:16]);
		w_data[31:24] = (wb_sel_i[3] ? wb_dat_i[31:24] : w_reg[31:24]);
	end

	always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin
		if (wb_rst_i) begin
			ch_ctl_delta_reg = {default_ctl_d_code_delta, default_ctl_threshold_delta};
		end else begin
			wb_ack_o <= 0;
			stb_gen_run <= 0;
			if (wb_cyc_i && wb_stb_i) begin
				wb_ack_o <= 1;
				case (addr)
					CH_CTL_DELTA_REG: begin
						if (wb_we_i) begin
							ch_ctl_delta_reg <= w_data; //TODO check for 0 in each delta
						end else begin
							wb_dat_o <= ch_ctl_delta_reg;
						end
					end
					STB_GEN_REG: begin
						if (wb_we_i) begin
							stb_gen_run <= w_data[0];
							stb_gen_cmp_sel <= w_data[1];
						end else begin
							wb_dat_o <= {stb_period, stb_gen_err, stb_gen_cmp_sel, stb_gen_rdy};
						end
					end
				endcase
			end
		end
	end

endmodule