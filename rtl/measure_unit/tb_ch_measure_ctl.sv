`timescale 1ns/1ns

module tb_ch_measure_ctl();

`define DUMPVARS
// `undef DUMPVARS    

	parameter int SIG_MAX = 'hFF;
	parameter int SIG_FREQ = 5000000; //Hz
	parameter real PI_2 = 3.14159265359 * 2;
	parameter  CLK_T =  8; // clk period

	parameter DAC_RDY_DELAY = 20;

	int sig;
	logic clk_i = 0;
	logic arst_i = 0;

	initial begin
		// #50000 $finish;
	end

	always begin
		#1 sig = (SIG_MAX * $sin($time/1000000000.0 * PI_2 * SIG_FREQ) + SIG_MAX) / 2 + 10;
	end

	logic stb_gen_sig_i;
	logic stb_gen_run_det_i = 0;
	logic stb_gen_rdy_o;
	logic stb_gen_oe_i = 1;    
	logic stb_gen_err_o;
	logic stb_gen_stb_o;

	assign stb_gen_sig_i = sig >= 11;

	stb_gen #(
		.ZERO_HOLD_CYCLES(2)
	) stb_gen_inst(
		.clk_i		(clk_i),
		.arst_i		(arst_i),
		.sig_i		(stb_gen_sig_i),
		.run_det_i 	(stb_gen_run_det_i),
		.oe_i		(stb_gen_oe_i),
		.err_o		(stb_gen_err_o),
		.rdy_o		(stb_gen_rdy_o),
   		.stb_o		(stb_gen_stb_o)
	);


	logic threshold_rdy = 0;
	logic threshold_wre;

	logic cmp_out = 0;
	logic [15:0] threshold_delta_i = 0;
	logic threshold_delta_wr_i = 0;
	logic [9:0] d_code_delta_i = 0;
	logic d_code_delta_wr_i = 0;
	logic [9:0] d_code_o;
	logic run_i = 0;
    logic point_rdy_o;
    logic [15:0] point_v_o;
    logic [9:0] point_t_o;

	logic [15:0] dut_threshold_o;
	ch_measure_ctl dut (
		.clk_i				(clk_i),
		.arst_i				(arst_i),
		.stb_i				(stb_delayed),
		.threshold_o		(dut_threshold_o),
		.threshold_wre_o	(threshold_wre),
		.threshold_rdy_i	(threshold_rdy),
		.cmp_out_i			(cmp_out),
		.*
	);

//////////////////////////////////////////////////////////////
// DAC, CMP and delay line logic 
//////////////////////////////////////////////////////////////

	logic [15:0] threshold = 0;

	logic stb_delayed = 0;

	always @(stb_gen_stb_o) begin
		stb_delayed <= #(d_code_o) stb_gen_stb_o;
	end
	
	always @(threshold, sig) begin
		// stb_delayed signal is a latch for comparator
		if (!stb_delayed) begin 
			cmp_out = sig > threshold;
		end


	end

	always begin 
		@(posedge threshold_wre);
		threshold_rdy = 0;
		#(DAC_RDY_DELAY);
		threshold_rdy = 1;
		threshold = dut_threshold_o;
	end

//////////////////////////////////////////////////////////////

	initial begin
		#10
		@(posedge stb_gen_rdy_o);
		run_i = 1;
	end

	always @(posedge point_rdy_o)
		$display( "%d", point_v_o);

	initial begin 
`ifdef DUMPVARS
		$dumpfile("dump.vcd");
		$dumpvars(1, tb_ch_measure_ctl);
`endif
	end

	initial begin
		#1 arst_i = 1; //global reset
		#1 arst_i = 0;
		//run strobe generator
		stb_gen_run_det_i = 1;
		#(CLK_T) stb_gen_run_det_i = 0;
	end

	always #(CLK_T/2) clk_i = ~clk_i;

endmodule