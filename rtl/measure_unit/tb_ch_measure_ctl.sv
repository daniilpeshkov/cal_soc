`timescale 1ns/1ps

`include "ch_measure_ctl.sv"
`include "stb_gen.sv"
`include "sync_ff.sv"
`include "two_cycle_32_adder.sv"

module tb_ch_measure_ctl();

// initial #900000 $finish;

`define DUMPVARS
// `undef DUMPVARS    

	parameter int SIG_MAX = 'hFF;
	parameter int SIG_FREQ = 1000000; //Hz
	parameter real PI_2 = 3.14159265359 * 2;
	parameter  CLK_T =  40; // clk period
	parameter HCLK_T = 8;

	parameter DAC_RDY_DELAY = 200;

	real sig;
	logic clk_i = 0;
	logic hclk = 0;
	logic arst_i = 0;

	always begin
		#0.01 sig = (SIG_MAX * $sin(($realtime % 10000) / 1000000000.0 * PI_2 * SIG_FREQ) + SIG_MAX) / 2 + 10;
		// #0.01 sig = ($realtime % 1000);
	end

	logic stb_gen_sig_i;
	logic stb_gen_rdy_o;
	logic stb_gen_err_o;
	logic stb_gen_stb_o;
	logic stb_gen_stb_req;
	logic stb_gen_stb_valid;

	assign stb_gen_sig_i = sig >= 11;

	stb_gen stb_gen_inst (
		.clk_i		(hclk),
		.arst_i		(~arst_i),
		.sig_i		(stb_gen_sig_i),
		.err_o		(stb_gen_err_o),
		.rdy_o		(stb_gen_rdy_o),
   		.stb_o		(stb_gen_stb_o),
		.stb_req_i	(stb_gen_stb_req),
		.stb_valid_o(stb_gen_stb_valid)
	);
		
	logic threshold_rdy = 0;
	logic threshold_wre;

	logic cmp_out = 0;
	logic [15:0] threshold_delta_i = 1;
	logic [9:0] d_code_delta_i = 1;
	logic [9:0] d_code_o;
	logic run_i = 0;
    logic point_rdy_o;
    logic [15:0] point_v_o;
    logic [9:0] point_t_o;

	logic [15:0] dut_threshold_o;
	ch_measure_ctl dut (
		.clk_i				(clk_i),
		.arst_i				(~arst_i),
		.threshold_o		(dut_threshold_o),
		.threshold_wre_o	(threshold_wre),
		.threshold_rdy_i	(threshold_rdy),
		.cmp_out_i			(cmp_out),
		.stb_req_o			(stb_gen_stb_req),
		.stb_valid_i		(stb_gen_stb_valid),
		.*
	);

//////////////////////////////////////////////////////////////
// DAC, CMP and delay line logic 
//////////////////////////////////////////////////////////////

	logic [15:0] threshold = 0;

	logic stb_delayed = 0;

	always @(stb_gen_stb_o) begin
		stb_delayed <= #(d_code_o * 0.01) stb_gen_stb_o;
	end
	
	always @(threshold, sig) begin
		// stb_delayed signal is a latch for comparator
		if (stb_delayed == 0) begin 
			cmp_out = sig >= threshold;
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
	int f;
	initial f = $fopen("points.csv", "w");

	always @(posedge point_rdy_o) begin
		$display( "%d", dut_threshold_o);
		$fwrite(f, "%d,%d\n",d_code_o, dut_threshold_o);
		if (point_t_o == 1023) $finish;
	end

	initial begin 
`ifdef DUMPVARS
		$dumpfile("dump.vcd");
		$dumpvars(0, tb_ch_measure_ctl);
`endif
	end

	initial begin
		#1 arst_i = 1; //global reset
		#1 arst_i = 0;
		@(posedge stb_gen_rdy_o);
		run_i = 1;
		//run strobe generator
	end

	always #(CLK_T/2) clk_i = ~clk_i;
	always #(HCLK_T/2) hclk = ~hclk;

endmodule