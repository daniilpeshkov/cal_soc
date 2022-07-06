
`timescale 1ns/10ps


`include "stb_gen.sv"
`include "skew_mes_ctl.sv"
`include "sync_ff.sv"
`include "two_cycle_32_adder.sv"

`define DUMPVARS
// `undef DUMPVARS    

module tb_stb_gen();

	localparam CLK_T =  40; // clk period
	localparam HCLK_T = 8;
	localparam T_CNT_WIDTH = 32;

	logic clk = 0;
	logic hclk = 0;
	logic arstn = 0;

	logic cmp_out_1 = 0;
	logic cmp_out_2;

	logic stb;
	logic err;
	logic stb_gen_rdy;
	logic [T_CNT_WIDTH-1:0] stb_period;

	logic ctl_stb_req;
	logic ctl_stb_valid;

	logic [9:0] delay_code;

	logic stb_req_i = 0;
	logic stb_valid_o;
	logic debug_stb;

	stb_gen stb_gen_inst (
		.clk_i          (hclk),
		.sig_i			(cmp_out_1),
		.arstn_i        (~arstn),
		.err_o          (err),
		.rdy_o          (stb_gen_rdy),
		.stb_period_o   (stb_period),
		.debug_stb_o    (debug_stb),
		.stb_req_i      (ctl_stb_req),
		.stb_valid_o    (ctl_stb_valid),
		.stb_o			(stb)
	);

	skew_mes_ctl skew_mes_ctl_inst (
		.clk_i          (clk),
		.arstn_i        (arstn),

		.cmp_out_i      (cmp_out_2),
		.delay_code_o   (delay_code),
		.stb_req_o		(ctl_stb_req),
		.stb_valid_i	(ctl_stb_valid)

	);

	//generate master signal
	localparam SIG_PERIOD = 20; 
	int cnt = 0;

	always @(posedge hclk) begin
		case (cnt)
			0: cmp_out_1 <= 1;
			default: cmp_out_1 <= 0;
		endcase
		case (cnt)
			SIG_PERIOD: cnt = 0;
			default: cnt += 1;
		endcase
	end

	real SKEW = 0.100;

////////////////////////////////////////////////////////////////
// making offset on channel 2
////////////////////////////////////////////////////////////////
	logic cmp_out_1_skew;
	always @(cmp_out_1) cmp_out_1_skew <= #(SKEW) cmp_out_1;
////////////////////////////////////////////////////////////////
// delaying stb with specified value
////////////////////////////////////////////////////////////////
	logic stb_delayed;
	always @(stb) stb_delayed <= #(delay_code * 0.01) stb;

////////////////////////////////////////////////////////////////
// latch logic on channel 2
////////////////////////////////////////////////////////////////
	always_latch begin
		if (!stb_delayed) cmp_out_2 = cmp_out_1_skew;
	end
////////////////////////////////////////////////////////////////

	initial begin 
		int t;

		time start;
		#1 arstn = 1;
		#1 arstn = 0;

		repeat (10)@(posedge debug_stb);
		start = $time;
		@(posedge debug_stb);
		t = $time - start;
		$display("generated strobe T= %d ns", t);
		$display("counted period=%d", stb_period * CLK_T);
		$display("");
		$display("OK!");
		$finish;
	end

	initial begin 
`ifdef DUMPVARS
		$dumpfile("dump.vcd");
		$dumpvars(0, tb_stb_gen);
`endif
	end

	always #(CLK_T/2) clk = ~clk;
	always #(HCLK_T/2) hclk = ~hclk;

endmodule