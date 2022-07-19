
module measure_unit #(
	parameter DAC_SPI_CLK_DIV = 3,
	parameter DAC_SPI_WAIT_CYCLES = 3
) (
//Clock for measure part
	input	logic		hclk_i,
	output	logic 		clk_sel_o, // selects clock for hclk_i
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
	localparam STB_GEN_CTL 			= 0;
//
//	    +-----------------+---------+-----+-----+
//	 r	|        x        | clk_sel | mux | rdy |
//	    +-----------------+---------+-----+-----+

//      30             3       2       1     0
//	    +-----------------+---------+-----+-----+
//	 w	|        x        | clk_sel | mux | run |
//	    +-----------------+---------+-----+-----+
//
//		err		- (DEPRECATED) strobe generator overflow (input signal has frequency < 1 PPS)
//		mux		- changes the sync channel (0 - ch 1, 1 - ch 2)
//		rdy		- indicates that strobes are generating with ``period`` (if not 0)
//		run		- writing 1 starts input frequency measurement
//		clk_sel - selects source of clk signal
//
///////////////////////////////////////////////////////////////////////////////////////
	localparam W_THRESHOLD_REG		= 1;
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
	localparam STB_GEN_PERIOD 			= 2;
//
//      31                                 0
//	    +-----------------------------------+
//	 r	|               period              |
//	    +-----------------------------------+
//
//		period 	- count of 125 Mhz cycles per input signal period	
//
///////////////////////////////////////////////////////////////////////////////////////
	localparam MU_SKEW_MES_CTL 			= 3;
// TODO update register description
//      31                            1     0
//	    +-----------------------------+-----+
//	r/w	|               x             | run |
//	    +-----------------------------+-----+
//
//		run 	- while set to 1 runs measurement
//
///////////////////////////////////////////////////////////////////////////////////////

	logic [STB_GEN_CNT_WIDTH-1:0] stb_period; 	// measured period of signal
	logic stb_gen_cmp_sel = 0;					// selects channel to sync strobes
	logic stb_gen_hclk_sel;
	logic stb_gen_run = 0;					
	logic stb_gen_err;							// not used for now
	logic stb_gen_rdy;							// indicates that stb_gen is ready to generate strobes
	logic stb_valid;

	logic [DAC_CODE_WIDTH-1 : 0] wb_dac_code; // write from wb bus
	logic wb_dac_wre;
	logic ctl1_dac_wre, ctl2_dac_wre;
	logic dac1_rdy, dac2_rdy;

	logic skew_mes_ctl_run;
	logic skew_mes_ctl_master_ch_sel;
	logic skew_mes_ctl_cmp_out;
	logic skew_mes_ctl_stb_req;
	logic skew_mes_cmp_out;
	logic [9:0] skew_mes_delay_code;
	logic skew_mes_ctl_err;
	logic skew_mes_ctl_rdy;

	assign clk_sel_o = stb_gen_hclk_sel;

	spi_master_o #(
		.DATA_WIDTH	(DAC_DATA_WIDTH),
		.CLK_DIV 	(DAC_SPI_CLK_DIV),
		.WAIT_CYCLES(DAC_SPI_WAIT_CYCLES)
	) dac1_spi_inst (
		.clk_i 	(wb_clk_i),
		.arst_i	(wb_rst_i),
		.data_i	({8'h00, (wb_dac_wre ? wb_dac_code : '0)}),
		.wre_i	(wb_dac_wre),
		.rdy_o	(dac1_rdy),
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
		.data_i	({8'h00, (wb_dac_wre ? wb_dac_code : '0)}),
		.wre_i	(wb_dac_wre),
		.rdy_o	(dac2_rdy),
		.sdi_o	(dac2_sdi_o),
		.sclk_o	(dac2_sclk_o),
		.sync_o	(dac2_sync_o)
	);

	stb_gen stb_gen_inst (
		.clk_i 			(hclk_i),
		.arstn_i		(~stb_gen_run),
		.sig_i			(stb_gen_cmp_sel ? cmp2_out_i : cmp1_out_i),
   		.err_o			(stb_gen_err),
   		.rdy_o			(stb_gen_rdy),
		.stb_o			(stb_o),
		.stb_req_i		(skew_mes_ctl_stb_req),
		.stb_valid_o	(stb_valid),
		.stb_period_o	(stb_period),
		.debug_stb_o	(debug_stb_o)
	);

	skew_mes_ctl skew_mes_ctl_inst (
		.clk_i			(wb_clk_i),
		.arstn_i		(~wb_rst_i),
		.delay_code_o	(skew_mes_delay_code),
		.cmp_out_i		(skew_mes_cmp_out),
		.run_i			(skew_mes_ctl_run),
		.err_o			(skew_mes_ctl_err),
		.rdy_o			(skew_mes_ctl_rdy),
		.stb_req_o		(skew_mes_ctl_stb_req),
		.stb_valid_i	(stb_valid)
	);

	assign delay1_code_o = (!skew_mes_ctl_master_ch_sel ? 0 : skew_mes_delay_code);
	assign delay2_code_o = (skew_mes_ctl_master_ch_sel ? 0 : skew_mes_delay_code);

	assign skew_mes_cmp_out = (skew_mes_ctl_master_ch_sel ? cmp1_out_i : cmp2_out_i);

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
			STB_GEN_CTL:		w_reg =	{clk_sel_o, stb_gen_run};
			W_THRESHOLD_REG:	w_reg = wb_dac_code;
			MU_SKEW_MES_CTL:	w_reg = {skew_mes_ctl_master_ch_sel, skew_mes_ctl_run};
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
			stb_gen_run = 0;
			stb_gen_cmp_sel = 0;
			stb_gen_hclk_sel = 0;
		end else begin
			if (wb_we_i & wb_req & (addr == STB_GEN_CTL)) begin
				stb_gen_run <= w_data[0];
				stb_gen_cmp_sel <= w_data[1];
				stb_gen_hclk_sel <= w_data[2];
			end else begin
				stb_gen_run <= 0;
			// 	stb_gen_cmp_sel <= stb_gen_cmp_sel;
			// 	clk_sel_o <= clk_sel_o;
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
			end //else begin
			// 	wb_dac_code <= 0;
			// 	wb_dac_wre <= 0;
			// end
		end
	end

	always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin : mu_skew_mes_ctl_ff
		if (wb_rst_i) begin
			skew_mes_ctl_run = 0;
			skew_mes_ctl_master_ch_sel = 0;
		end else begin
			if (wb_we_i & wb_req & (addr == MU_SKEW_MES_CTL)) begin
				skew_mes_ctl_run <= w_data[0];
				skew_mes_ctl_master_ch_sel <= w_data[1];
			end
		end
	end

	always_ff @(posedge wb_clk_i) begin : wb_dat_o_comb
		case (addr)
			STB_GEN_CTL:		wb_dat_o <= {stb_gen_hclk_sel, stb_gen_cmp_sel, stb_gen_rdy};
			W_THRESHOLD_REG:	wb_dat_o <= {dac2_rdy, dac1_rdy};
			STB_GEN_PERIOD:		wb_dat_o <= stb_period;
			MU_SKEW_MES_CTL:	wb_dat_o <= {skew_mes_delay_code, skew_mes_ctl_err, skew_mes_ctl_rdy, skew_mes_ctl_master_ch_sel, skew_mes_ctl_run};
			default: 			wb_dat_o <= 0;
		endcase
	end

	always_ff @(posedge wb_clk_i, posedge wb_rst_i)
		if (wb_rst_i) wb_ack_o = 0;
		else wb_ack_o <= (wb_cyc_i & wb_stb_i ? 1 : 0);

endmodule