
`timescale 1ns/1ps


`include "pipelined_adder_32.sv"
`include "pipelined_equal_32.sv"
`include "stb_gen.sv"
`include "skew_mes_ctl.sv"
`include "sync_ff.sv"

`define DUMPVARS
// `undef DUMPVARS    

module tb_stb_gen();

	localparam CLK_T =  40; // clk period
	localparam HCLK_T = 8;
	localparam T_CNT_WIDTH = 32;

	localparam TEST_CASE_N = 1;

	real SKEW = 0.090;
	real SKEW_STEP = 0.010;

	logic m_sig = 0;
	logic s_sig = 0;

	logic m_cmp_out = 0;
	logic s_cmp_out = 0;



	logic clk = 0;
	logic hclk = 0;
	bit arstn = 0;
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
	logic run = 0;
	logic ctl_rdy;
	logic [2:0] ctl_err;
	logic [9:0] skew_res;

	stb_gen stb_gen_inst (
		.clk_i          (hclk),
		.sig_i			(m_cmp_out),
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
		.arstn_i        (~arstn),

		.m_cmp_out_i    (m_cmp_out),
		.s_cmp_out_i	(s_cmp_out),
		.delay_code_o   (delay_code),
		.stb_req_o		(ctl_stb_req),
		.stb_valid_i	(ctl_stb_valid),
		.run_i			(run),
		.rdy_o			(ctl_rdy),
		.err_o			(ctl_err),
		.res_o			(skew_res)
	);

////////////////////////////////////////////////////////////////
// generate master signal
////////////////////////////////////////////////////////////////
	localparam SIG_PERIOD = 20; 
	localparam CLK_OFFSET = 2.0;
	int cnt = 0;

	always @(posedge hclk) begin
		case (cnt)
			0: m_sig <= #(CLK_OFFSET) 1;
			default: m_sig <= #(CLK_OFFSET) 0;
		endcase
		case (cnt)
			SIG_PERIOD: cnt = 0;
			default: cnt += 1;
		endcase
	end
////////////////////////////////////////////////////////////////
// making offset on channel 2
////////////////////////////////////////////////////////////////
	always @(m_sig) s_sig <= #(SKEW) m_sig;
////////////////////////////////////////////////////////////////
// delaying stb with specified value
////////////////////////////////////////////////////////////////
	logic stb_delayed;
	always @(stb) stb_delayed <= #(delay_code * SKEW_STEP) stb;

////////////////////////////////////////////////////////////////
// latch logic 
////////////////////////////////////////////////////////////////
	always_latch begin
		if (!stb_delayed) s_cmp_out <= s_sig;
	end

	always_latch begin
		if (!stb_delayed) m_cmp_out <= m_sig;
	end
////////////////////////////////////////////////////////////////


	initial begin 
		real mes_skew;

		repeat (TEST_CASE_N) begin
			SKEW = 4.5;// $urandom_range(1, 9999) / 1000.0;
			@(posedge clk);
			arstn = 1;
			@(posedge clk);
			arstn = 0;

			repeat (2)@(posedge debug_stb);
			run <= 1;
			

			@(posedge ctl_rdy, posedge ctl_err);
			if (ctl_rdy) begin

				mes_skew = skew_res * 10;
				$display("measured skew = %d ps", mes_skew);
				$display("actual skew = %d ps", SKEW * 1000);
				$display("err = %d ps", SKEW * 1000 - mes_skew);

				if ($abs(int'(mes_skew - SKEW * 1000)) > int'(SKEW_STEP * 1000)) begin
					$display("err is greater than skew measure step!");
					$fatal(1);
				end else begin
					$display("OK!");
				end
			end else begin
				$display("module set err_o signal");
				$fatal(1);
			end
		end
		$display("all tests passed!");
		$finish;
	end

	initial begin 
`ifdef DUMPVARS
		$dumpfile("dump.vcd");
		$dumpvars(0, tb_stb_gen);
`endif
	end

	always #(CLK_T/2) clk <= ~clk;
	always #(HCLK_T/2) hclk <= ~hclk;

endmodule