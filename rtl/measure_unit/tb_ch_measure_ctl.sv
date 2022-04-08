`timescale 1ns/1ns

module tb_ch_measure_ctl();
`define DUMPVARS
// `undef DUMPVARS    

	parameter int SIG_MAX = 255;
	parameter int SIG_FREQ = 100000; //Hz
	parameter real PI_2 = 3.14159265359 * 2;
	parameter  CLK_T =  8; // clk period

	int sig;
	logic clk_i = 0;
	logic arst_i;

	always begin
		#1 sig = SIG_MAX * $sin($time/1000000000.0 * PI_2 * SIG_FREQ);
	end

	logic stb_gen_sig_i;
	logic stb_gen_run_det_i = 0;
	logic stb_gen_rdy_o;
	logic stb_gen_oe_i = 1;    
	logic stb_gen_err_o;
	logic stb_gen_stb_o;
	assign stb_gen_sig_i = sig >= SIG_MAX/2;

	stb_gen stb_gen_inst(
		.clk_i		(clk_i),
		.arst_i		(arst_i),
		.sig_i		(stb_gen_sig_i),
		.run_det_i 	(stb_gen_run_det_i),
		.oe_i		(stb_gen_oe_i),
		.err_o		(stb_gen_err_o),
		.rdy_o		(stb_gen_rdy_o),
   		.stb_o		(stb_gen_stb_o)
	);

	initial begin
		#1 arst_i = 1; //global reset
		#1 arst_i = 0;
		stb_gen_run_det_i = 1;
		#(CLK_T) stb_gen_run_det_i = 0;
	end



	logic stb_i;
	logic [15:0] threshold_delta_i;
	logic threshold_delta_wr_i;
	logic [9:0] d_code_delta_i;
	logic d_code_delta_wr_i;
	logic mosi_o;
	logic sclk_o;
	logic sync_o;
	logic [9:0] d_code_o;

	ch_measure_ctl dut (.*);


	initial begin 
`ifdef DUMPVARS
		$dumpfile("dump.vcd");
		$dumpvars(0, tb_ch_measure_ctl);
`endif
	end

	initial #100000 $finish;

	always #(CLK_T/2) clk_i = ~clk_i;

endmodule