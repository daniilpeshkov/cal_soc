//------------------------------------------------------
//	Module for frequency measurement and strobe generation
//------------------------------------------------------
//	author:  	Peshkov Daniil
//	email:  	daniil.peshkov@spbpu.com
//------------------------------------------------------

module stb_gen #(
	parameter OFFSET = 20,
	parameter T_CNT_WIDTH = 32
) (
	input wire clk_i,
	input wire arst_i,

	input wire sig_i,

	output logic err_o,
	output logic rdy_o,
	output logic stb_o,
	output logic [T_CNT_WIDTH-1:0] stb_period_o,

	input  logic stb_req_i,
	output logic stb_valid_o,
	output logic debug_stb_o
);
	// localparam T_CNT_WIDTH 			= 32;
	localparam ZERO_HOLD_CYCLES 	= 2;

	logic int_stb = 0;
	assign debug_stb_o = int_stb;

	logic sig_synced;

	//stb req interface

	logic stb_oe; // stb_oe == 1 blocks strobe generation

	assign stb_o = (rdy_o ? int_stb | stb_oe : int_stb);	

	assign stb_valid_o = stb_oe & rdy_o;

	logic prev_stb_req;

	always_ff @(posedge clk_i) prev_stb_req <= stb_req_i;

	logic req_posedge;
	assign req_posedge = ~prev_stb_req & stb_req_i;

	logic is_zero_hold_start;
	logic is_stb_end;

	always_ff @(posedge clk_i, negedge arst_i) begin
		if (~arst_i) begin
			stb_oe = 0;
		end else begin
			casex ({req_posedge, is_stb_end})			
				2'bx1:  stb_oe <= 1;
				2'b1x:	stb_oe <= 0;
			endcase
		end
	end

	sync_ff #(
		.WIDTH (1),
		.STAGES(2)
	) sig_i_sync_ff_inst (
		.clk_i (clk_i),
		.data_i(sig_i),
		.data_o(sig_synced)
	);

	logic prev_sig; //edge detect

	always_ff @(posedge clk_i) begin
		prev_sig <= sig_synced;
	end

	logic sig_posedge;
	assign sig_posedge = sig_synced & ~prev_sig;

	typedef enum logic[8:0] { 
		FIND_EDGE_1 		= 9'b000000001, 
		FIND_EDGE_2 		= 9'b000000010,
		WRITE_START 		= 9'b000000100,
		FIND_EDGE_3 		= 9'b000001000, 
		WRITE_END			= 9'b000010000,
		COUNT_PERIOD 		= 9'b000100000, 
		WAIT_COUNT_PERIOD 	= 9'b001000000,
		COUNT_STROBE 		= 9'b010000000,
		WAIT_STB_END 		= 9'b100000000
	} stb_gen_state;

	stb_gen_state state = FIND_EDGE_1;

	logic [T_CNT_WIDTH-1 : 0] t_cnt /* synthesis syn_keep=1 syn_preserve=1 syn_ramstyle="registers" */;
	logic [T_CNT_WIDTH-1 : 0] t_start;
	logic [T_CNT_WIDTH-1 : 0] t_end;
	stb_gen_state next_state;


	logic count_zero_hold_begin, zero_hold_begin_valid;
	logic count_stb_end, stb_end_valid;

	assign count_zero_hold_begin = (state == COUNT_STROBE ? 1 : 0);
	assign count_stb_end = (state == COUNT_STROBE ? 1 : 0);

	always_comb begin
		unique case (state) /* sythesis parallel_case*/
			FIND_EDGE_1:			if (sig_posedge) next_state = FIND_EDGE_2;
									else next_state = state;
			FIND_EDGE_2:			if (sig_posedge) next_state = WRITE_START;
									else next_state = state;
			WRITE_START:			next_state = FIND_EDGE_3;
			FIND_EDGE_3:			if (sig_posedge) next_state = WRITE_END;
									else next_state = state;
			WRITE_END:				next_state = COUNT_PERIOD;
			COUNT_PERIOD:			next_state = WAIT_COUNT_PERIOD;
			WAIT_COUNT_PERIOD:		next_state = COUNT_STROBE;
			COUNT_STROBE:			next_state = WAIT_STB_END;
			WAIT_STB_END:			if (is_stb_end) next_state = COUNT_PERIOD;
									else next_state = state;
			default:				next_state = state;
		endcase
	end

	always_ff @(posedge clk_i, negedge arst_i) begin
		if (~arst_i) begin
			state = FIND_EDGE_1;
		end else begin
			state <= next_state;
		end
	end

	logic [T_CNT_WIDTH-1:0] adder_zero_hold_res;
	logic [T_CNT_WIDTH-1:0] adder_stb_end_res;

	always_ff @(posedge clk_i) begin
		stb_period_o <= (state == COUNT_PERIOD ? t_end - t_start : stb_period_o);
	end

	logic [T_CNT_WIDTH-1:0] period_minus_zero_hold;
	always_ff @(posedge clk_i) period_minus_zero_hold <= stb_period_o - (ZERO_HOLD_CYCLES+5); //magic constat due to computation pipeline

	two_cycle_32_adder adder_zero_hold_begin (
		.clk_i 	(clk_i),
		.a_i	(t_cnt),
		.b_i	(period_minus_zero_hold),
		.valid_i(count_zero_hold_begin),
		.valid_o(zero_hold_begin_valid),
		.res_o	(adder_zero_hold_res)
	);

	two_cycle_32_adder adder_stb_end (
		.clk_i 	(clk_i),
		.a_i	(t_cnt),
		.b_i	(stb_period_o - 5), //magic constat due to computation pipeline
		.valid_i(count_stb_end),
		.valid_o(stb_end_valid),
		.res_o	(adder_stb_end_res)
	);

	logic [T_CNT_WIDTH-1:0] latched_zero_hold_res;
	logic [T_CNT_WIDTH-1:0] latched_stb_end_res;

	always_ff @(posedge clk_i) latched_zero_hold_res <= (zero_hold_begin_valid ? adder_zero_hold_res : latched_zero_hold_res);
	always_ff @(posedge clk_i) latched_stb_end_res <= (stb_end_valid ? adder_stb_end_res : latched_stb_end_res);

 
	logic is_zero_hold_start_lo;
	logic is_zero_hold_start_hi;
	logic is_stb_end_lo;
	logic is_stb_end_hi;

	always_ff @(posedge clk_i) is_zero_hold_start_lo <=  ~|(t_cnt[15:0] ^ latched_zero_hold_res[15:0]);  //t_cnt == latched_zero_hold_res;
	always_ff @(posedge clk_i) is_zero_hold_start_hi <=  ~|(t_cnt[31:16] ^ latched_zero_hold_res[31:16]);  //t_cnt == latched_zero_hold_res;
	always_ff @(posedge clk_i) is_zero_hold_start <= is_zero_hold_start_lo & is_zero_hold_start_hi; 

	// always_ff @(posedge clk_i) is_zero_hold_start <=  ~|(t_cnt ^ latched_zero_hold_res);  //t_cnt == latched_zero_hold_res;

	always_ff @(posedge clk_i) is_stb_end_lo <=  ~|(t_cnt[15:0] ^ latched_stb_end_res[15:0]);  //t_cnt == latched_zero_hold_res;
	always_ff @(posedge clk_i) is_stb_end_hi <=  ~|(t_cnt[31:16] ^ latched_stb_end_res[31:16]);  //t_cnt == latched_zero_hold_res;
	always_ff @(posedge clk_i) is_stb_end <= is_stb_end_hi & is_stb_end_lo; 
	// always_ff @(posedge clk_i) is_stb_end <= ~|(t_cnt ^ latched_stb_end_res); //t_cnt == latched_stb_end_res;

	always_ff @(posedge clk_i, negedge arst_i) begin
		if (~arst_i) begin
			int_stb = 0;
		end else begin
			case (1) 
				is_zero_hold_start: int_stb <= 0;
				is_stb_end:			int_stb <= 1;
				default:			int_stb <= int_stb;
			endcase
		end
	end

	always_ff @(posedge clk_i, negedge arst_i) begin
		if (~arst_i) rdy_o = 0;
		else rdy_o <= (state == COUNT_STROBE ? 1 : rdy_o);
	end

	always_ff @(posedge clk_i) begin
		err_o <= (state == FIND_EDGE_1 ? 0 : err_o);
	end

	always_ff @(posedge clk_i) t_end <= (state == WRITE_END ? t_cnt : t_end);

	always_ff @(posedge clk_i) t_start <= (state == WRITE_START ? t_cnt : t_start);

	// pipelined counter

	logic [T_CNT_WIDTH/2-1 : 0] high_bytes = 0 			/* synthesis syn_keep=1 syn_preserve=1 syn_ramstyle="registers" */;
	logic [T_CNT_WIDTH/2-1 : 0] latched_low_bytes = 0 	/* synthesis syn_keep=1 syn_preserve=1 syn_ramstyle="registers" */;
	logic [T_CNT_WIDTH/2-1 : 0] low_bytes = 0 			/* synthesis syn_keep=1 syn_preserve=1 syn_ramstyle="registers" */;
	logic [T_CNT_WIDTH/2-1 : 0] low_bytes_plus_1;
	logic carry;

	assign {carry, low_bytes_plus_1} = low_bytes + 1;

	//incrementing low bytes
	always_ff @(posedge clk_i, negedge arst_i) 
		if (~arst_i) low_bytes = 0;
		else low_bytes <= low_bytes_plus_1;

	//latching low bytes for 1 cycle
	always_ff @(posedge clk_i, negedge arst_i) 
		if (~arst_i) latched_low_bytes = 0;
		else latched_low_bytes <= low_bytes;

	logic latched_carry = 0;

	//latching carry
	always_ff @(posedge clk_i, negedge arst_i) 
		if (~arst_i) latched_carry = 0;
		else latched_carry <= carry;

	//adding latched carry to high bytes
	always_ff @(posedge clk_i, negedge arst_i)
		if (~arst_i) high_bytes = 0;
		else high_bytes <= high_bytes + latched_carry;

	//seting t_cnt
	always_ff @(posedge clk_i, negedge arst_i) 
		if (~arst_i) t_cnt = 0;
		else t_cnt <= {high_bytes, latched_low_bytes};

endmodule