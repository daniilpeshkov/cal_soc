
module measure_unit #(
	parameter DAC_SPI_CLK_DIV = 3,
	parameter DAC_SPI_WAIT_CYCLES = 3,
	parameter DEFAULT_DELAY_CODE_DELTA = 10'h1,
	parameter DEFAULT_THRESHOLD_DELTA = 16'h1
) (
//Clock for measure part
	input	logic		hclk_i,
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
	output logic 	   stb_o,

	output logic 	   debug_stb_o,
//CMP
	input logic cmp1_out_i, cmp2_out_i
);
	localparam DAC_DATA_WIDTH = 24;
	localparam DAC_CODE_WIDTH = 16;
	localparam STB_GEN_CNT_WIDTH = 32;
///////////////////////////////////////////////////////////////////////////////////////
// Wishbone registers
///////////////////////////////////////////////////////////////////////////////////////
	localparam CH_CTL_DELTA_REG 	= 0;
//
//      25          16 15              0
//      +-------------+-----------------+
//	r/w	| delay delta | threshold delta |
//	    +-------------+-----------------+
//
//		delay delta 		- delay code change step
//		threshold delta		- threshold dac code change step
///////////////////////////////////////////////////////////////////////////////////////
	localparam STB_GEN_CTL 			= 1;
//
//      30             3    2     1     0
//	    +-----------------+-----+-----+-----+
//	 r	|        x        | err | mux | rdy |
//	    +-----------------+-----+-----+-----+
//       30             3    2     1     0
//	    +-----------------+-----+-----+-----+
//	 w	|        x        |  x  | mux | run |
//	    +-----------------+-----+-----+-----+
//
//		err		- (DEPRECATED) strobe generator overflow (input signal has frequency < 1 PPS)
//		mux		- changes the sync channel (0 - ch 1, 1 - ch 2)
//		rdy		- indicates that strobes are generating with ``period`` (if not 0)
//		run		- writing 1 starts input frequency measurement
///////////////////////////////////////////////////////////////////////////////////////
	localparam W_THRESHOLD_REG		= 2;
	
//		     1           0 
//		+----------+----------+
//	 r	| dac2 rdy | dac1 rdy |
//		+----------+----------+
//       15                              0
//		+-----------------------------------+
//	 w	|             threshold             |
//		+-----------------------------------+
//
//		dac2 rdy	- indicates that threshold at dac2 is set
//		dac1 rdy	- indicates that threshold at dac2 is set
//		threshold	- writing to this register cause setting threshold on dac1 and dac2
//
///////////////////////////////////////////////////////////////////////////////////////
	localparam STB_GEN_PERIOD 			= 3;
//
//      31                                 0
//	    +-----------------------------------+
//	 r	|               period              |
//	    +-----------------------------------+
//
//		period 	- count of 125 Mhz cycles per input signal period	
///////////////////////////////////////////////////////////////////////////////////////

	logic [25:0] ch_ctl_delta_reg;
	logic [15:0] ctl_threshold_delta, default_ctl_threshold_delta;
	logic [9:0] ctl_d_code_delta, default_ctl_d_code_delta;
	assign default_ctl_d_code_delta = DEFAULT_DELAY_CODE_DELTA;
	assign default_ctl_threshold_delta = DEFAULT_THRESHOLD_DELTA;
	assign ctl_threshold_delta = ch_ctl_delta_reg[15:0];
	assign ctl_d_code_delta = ch_ctl_delta_reg[25:16];

	logic [STB_GEN_CNT_WIDTH-1:0] stb_period; 	// measured period of signal
	logic stb_gen_cmp_sel = 0;					// selects channel to sync strobes
	logic stb_gen_run = 0;					
	logic stb_gen_oe;							// not used for now
	assign stb_gen_oe = 1;
	logic stb_gen_err;							// not used for now
	logic stb_gen_rdy;							// indicates that stb_gen is ready to generate strobes

	logic [DAC_CODE_WIDTH-1 : 0] ctl1_dac_code, ctl2_dac_code;
	logic [DAC_CODE_WIDTH-1 : 0] wb_dac_code; // write from wb bus
	logic wb_dac_wre;
	logic dac_src_sel;
	logic ctl1_dac_wre, ctl2_dac_wre;
	logic dac1_rdy, dac2_rdy;
	logic ctl_run;

	spi_master_o #(
		.DATA_WIDTH	(DAC_DATA_WIDTH),
		.CLK_DIV 	(DAC_SPI_CLK_DIV),
		.WAIT_CYCLES(DAC_SPI_WAIT_CYCLES)
	) dac1_spi_inst (
		.clk_i 	(wb_clk_i),
		.arst_i	(wb_rst_i),
		.data_i	({8'h00, (wb_dac_wre ? wb_dac_code : ctl1_dac_code)}),
		.wre_i	(ctl1_dac_wre | wb_dac_wre),
		.rdy_o	(dac1_rdy),
		.sdi_o	(dac1_sdi_o),
		.sclk_o	(dac1_sclk_o),
		.sync_o	(dac1_sync_o)
	);

	// spi_master_o #(
	// 	.DATA_WIDTH	(DAC_DATA_WIDTH),
	// 	.CLK_DIV 	(DAC_SPI_CLK_DIV),
	// 	.WAIT_CYCLES(DAC_SPI_WAIT_CYCLES)
	// ) dac2_spi_inst (
	// 	.clk_i 	(hclk_i),
	// 	.arst_i	(wb_rst_i),
	// 	.data_i	({8'h00, (wb_dac_wre ? wb_dac_code : ctl2_dac_code)}),
	// 	.wre_i	(ctl2_dac_wre),
	// 	.rdy_o	(dac2_rdy),
	// 	.sdi_o	(dac2_sdi_o),
	// 	.sclk_o	(dac2_sclk_o),
	// 	.sync_o	(dac2_sync_o)
	// );

	// ch_measure_ctl ch_ctl1_inst(
	// 	.clk_i 					(),//(hclk_i),
	// 	.arst_i					(wb_rst_i),
	// 	.stb_i					(internal_stb),
	// 	.cmp_out_i				(cmp1_out_i),
	// 	.threshold_delta_i 		(ctl_threshold_delta),
	// 	.d_code_delta_i			(ctl_d_code_delta),
	// 	.threshold_o			(ctl1_dac_code),
	// 	.threshold_wre_o		(ctl1_dac_wre),
	// 	.threshold_rdy_i		(dac1_rdy),
	// 	.d_code_o				(delay1_code_o),
	// 	.run_i					(ctl_run),
	// 	.point_rdy_o			(),
	// 	.point_v_o				(),
	// 	.point_t_o				()
	// );

	// ch_measure_ctl ch_ctl2_inst(
	// 	.clk_i 					(),//(hclk_i),
	// 	.arst_i					(wb_rst_i),
	// 	.stb_i					(internal_stb),
	// 	.cmp_out_i				(cmp2_out_i),
	// 	.threshold_delta_i 		(ctl_threshold_delta),
	// 	.d_code_delta_i			(ctl_d_code_delta),
	// 	.threshold_o			(ctl2_dac_code),
	// 	.threshold_wre_o		(ctl2_dac_wre),
	// 	.threshold_rdy_i		(dac2_rdy),
	// 	.d_code_o				(delay2_code_o),
	// 	.run_i					(ctl_run),
	// 	.point_rdy_o			(),
	// 	.point_v_o				(),
	// 	.point_t_o				()
	// );

	stb_gen stb_gen_inst (
		.clk_i 			(hclk_i),
		.arst_i			(~stb_gen_run),//(wb_rst_i),
		.sig_i			(stb_gen_cmp_sel ? cmp2_out_i : cmp1_out_i),
   		.err_o			(stb_gen_err),
   		.rdy_o			(stb_gen_rdy),
		.stb_o			(stb_o),
		.stb_period_o	(stb_period),
		.debug_stb_o	(debug_stb_o)
	);

///////////////////////////////////////////////////////////////////////////////////////
// Wishbone logic	
///////////////////////////////////////////////////////////////////////////////////////

	logic [31:0] w_data;
	logic [2:0] addr;
	logic [31:0] byte_mask;

	assign addr = wb_adr_i[4:2];

	always_comb begin
		logic [31:0] w_reg;
		case (addr)
			CH_CTL_DELTA_REG: 	w_reg = ch_ctl_delta_reg;
			STB_GEN_CTL:		w_reg =	{stb_gen_cmp_sel, stb_gen_run};
			W_THRESHOLD_REG:	w_reg = wb_dac_code;
			default: w_reg = 0;
		endcase
		w_data[7:0] = (wb_sel_i[0] ? wb_dat_i[7:0] : w_reg[7:0]);
		w_data[15:8] = (wb_sel_i[1] ? wb_dat_i[15:8] : w_reg[15:8]);
		w_data[23:16] = (wb_sel_i[2] ? wb_dat_i[23:16] : w_reg[23:16]);
		w_data[31:24] = (wb_sel_i[3] ? wb_dat_i[31:24] : w_reg[31:24]);
	end

	logic wb_req;
	assign wb_req = wb_cyc_i & wb_stb_i;

	always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin
		if (wb_rst_i) begin
			ch_ctl_delta_reg = {default_ctl_d_code_delta, default_ctl_threshold_delta};
		end else begin
			if (wb_we_i & wb_req & (addr == CH_CTL_DELTA_REG)) begin
				ch_ctl_delta_reg <= wb_dat_i;
			end else begin
				ch_ctl_delta_reg <= ch_ctl_delta_reg;
			end
		end
	end

	always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin
		if (wb_rst_i) begin
			stb_gen_run = 0;
			stb_gen_cmp_sel = 0;
		end else begin
			if (wb_we_i & wb_req & (addr == STB_GEN_CTL)) begin
				stb_gen_run <= w_data[0];
				stb_gen_cmp_sel <= w_data[1];
			end else begin
				stb_gen_run <= 0;
				stb_gen_cmp_sel <= stb_gen_cmp_sel;
			end
		end
	end

	always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin
		if (wb_rst_i) begin
			wb_dac_code = 0;
			wb_dac_wre = 0;
		end else begin
			if (wb_we_i & wb_req & (addr == W_THRESHOLD_REG)) begin
				wb_dac_code <= w_data;
				wb_dac_wre <= 1;
			end else begin
				wb_dac_code <= 0;
				wb_dac_wre <= 0;
			end
		end
	end

	always_ff @(posedge wb_clk_i) begin : wb_dat_o_comb
		case (addr)
			CH_CTL_DELTA_REG:	wb_dat_o <= ch_ctl_delta_reg;
			STB_GEN_CTL:		wb_dat_o <= {stb_gen_err, stb_gen_cmp_sel, stb_gen_rdy};
			W_THRESHOLD_REG:	wb_dat_o <= {dac2_rdy, dac1_rdy};
			STB_GEN_PERIOD:		wb_dat_o <= stb_period;
			default: 			wb_dat_o <= 0;
		endcase
	end

	always_ff @(posedge wb_clk_i, posedge wb_rst_i)
		if (wb_rst_i) wb_ack_o = 0;
		else wb_ack_o <= (wb_cyc_i & wb_stb_i ? 1 : 0);

endmodule