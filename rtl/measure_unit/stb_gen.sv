//------------------------------------------------------
//	Module for frequency measurement and strobe generation
//------------------------------------------------------
//	author:  	Peshkov Daniil
//	email:  	daniil.peshkov@spbpu.com
//------------------------------------------------------

module stb_gen #(
	parameter T_CNT_WIDTH = 32 //do not change
) (
	input wire clk_i,
	input wire arstn_i,

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
	logic prev_sig; //edge detect

	logic req_posedge;
	assign req_posedge = ~prev_stb_req & stb_req_i;

	logic sig_posedge;
	assign sig_posedge = sig_synced & ~prev_sig;

	logic is_zero_hold_start;
	logic is_stb_end;
	logic is_gen_start;

	logic [T_CNT_WIDTH-1 : 0] t_cnt;
	logic [T_CNT_WIDTH-1 : 0] t_start;
	logic [T_CNT_WIDTH-1 : 0] t_end;

	logic count_zero_hold_begin, zero_hold_begin_valid;
	logic count_stb_end, stb_end_valid;
	logic count_gen_start, gen_start_valid;

	logic [T_CNT_WIDTH-1:0] adder_zero_hold_res;
	logic [T_CNT_WIDTH-1:0] adder_stb_end_res;
	logic [T_CNT_WIDTH-1:0] adder_gen_start_res;
	logic [T_CNT_WIDTH-1:0] adder_period_res;

	always_ff @(posedge clk_i) prev_stb_req <= stb_req_i;

	always_ff @(posedge clk_i, negedge arstn_i) begin
		if (~arstn_i) begin
			stb_oe = 0;
		end else begin
			casex ({req_posedge, is_stb_end})			
				2'b1x:	stb_oe <= 0;
				2'bx1:  stb_oe <= 1;
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

	always_ff @(posedge clk_i) begin
		prev_sig <= sig_synced;
	end

	enum logic[8:0] { 
		FIND_EDGE_1 		= 9'b000000001, 
		FIND_EDGE_2 		= 9'b000000010,
		WRITE_START 		= 9'b000000100,
		FIND_EDGE_3 		= 9'b000001000, 
		COUNT_PERIOD 		= 9'b000010000, 
		COUNT_GEN_START		= 9'b000100000,
		WAIT_GEN_START		= 9'b001000000,
		COUNT_STROBE 		= 9'b010000000,
		WAIT_STB_END 		= 9'b100000000
	} state = FIND_EDGE_1, next_state;


	assign count_zero_hold_begin = (state == COUNT_STROBE ? 1 : 0);
	assign count_stb_end = (state == COUNT_STROBE ? 1 : 0);
	assign count_gen_start = (state == COUNT_GEN_START ? 1 : 0);

	always_comb begin
		unique case (state) /* sythesis parallel_case*/
			FIND_EDGE_1:			if (sig_posedge) next_state = FIND_EDGE_2;
									else next_state = state;
			FIND_EDGE_2:			if (sig_posedge) next_state = WRITE_START;
									else next_state = state;
			WRITE_START:			next_state = FIND_EDGE_3;
			FIND_EDGE_3:			if (sig_posedge) next_state = COUNT_PERIOD;
									else next_state = state;
			COUNT_PERIOD:			next_state = COUNT_GEN_START;
			COUNT_GEN_START:		next_state = WAIT_GEN_START;
			WAIT_GEN_START:			if (is_gen_start) next_state = COUNT_STROBE;
									else next_state = state;
			COUNT_STROBE:			next_state = WAIT_STB_END;
			WAIT_STB_END:			if (is_stb_end) next_state = COUNT_STROBE;
									else next_state = state;
			default:				next_state = state;
		endcase
	end

	always_ff @(posedge clk_i, negedge arstn_i) begin
		if (~arstn_i) begin
			state = FIND_EDGE_1;
		end else begin
			state <= next_state;
		end
	end


	always_ff @(posedge clk_i, negedge arstn_i) begin
		if (~arstn_i) stb_period_o = 0;
		else if (state == COUNT_PERIOD) begin
			stb_period_o <= adder_period_res;
		end
	end

	localparam MAGIC_CONST = 0;
	// localparam OFFSET = 4;
	localparam OFFSET = 6;

	logic [T_CNT_WIDTH-1:0] period_minus_zero_hold;
	always_ff @(posedge clk_i) period_minus_zero_hold <= stb_period_o - (ZERO_HOLD_CYCLES+MAGIC_CONST); //magic constat due to computation pipeline

	pipelined_adder_32 adder_zero_hold_begin (
		.clk_i 	(clk_i),
		.a_i	(t_cnt),
		.b_i	(period_minus_zero_hold),
		.valid_i(count_zero_hold_begin),
		.valid_o(zero_hold_begin_valid),
		.res_o	(adder_zero_hold_res)
	);

	pipelined_adder_32 adder_stb_end (
		.clk_i 	(clk_i),
		.a_i	(t_cnt),
		.b_i	(stb_period_o - MAGIC_CONST), //magic constat due to computation pipeline
		.valid_i(count_stb_end),
		.valid_o(stb_end_valid),
		.res_o	(adder_stb_end_res)
	);

	pipelined_adder_32 adder_gen_start (
		.clk_i 	(clk_i),
		.a_i	(t_cnt),
		.b_i	(stb_period_o - OFFSET),
		.valid_i(count_gen_start),
		.valid_o(gen_start_valid),
		.res_o	(adder_gen_start_res)
	);

	pipelined_adder_32 adder_period (
		.clk_i 	(clk_i),
		.a_i	(t_cnt),
		.b_i	(-t_start),
		.valid_i(1'b1),
		.valid_o(),
		.res_o	(adder_period_res)
	);

	logic [T_CNT_WIDTH-1:0] latched_zero_hold_res;
	logic [T_CNT_WIDTH-1:0] latched_stb_end_res;
	logic [T_CNT_WIDTH-1:0] latched_gen_start_res;

	always_ff @(posedge clk_i, negedge arstn_i)
		if (~arstn_i) latched_zero_hold_res = 0;
		else if (zero_hold_begin_valid) latched_zero_hold_res <= adder_zero_hold_res;

	always_ff @(posedge clk_i, negedge arstn_i)
		if (~arstn_i) latched_stb_end_res = 0;
		else if (stb_end_valid) latched_stb_end_res <= adder_stb_end_res;

	always_ff @(posedge clk_i, negedge arstn_i)
		if (~arstn_i) latched_gen_start_res = 0;
		else if (gen_start_valid) latched_gen_start_res <= adder_gen_start_res;

	logic gen_start_eq_ena;

	always_ff @(posedge clk_i, negedge arstn_i) begin
		if (~arstn_i) gen_start_eq_ena = 0;
		else if (gen_start_valid) gen_start_eq_ena <= 1;
	end

	pipelined_equal_32 is_zero_hold_start_eq_inst (
		.clk_i	(clk_i),
		.a_i	(t_cnt),
		.b_i	(latched_zero_hold_res),
		.eq_o	(is_zero_hold_start),
		.ena_i	(1'b1)
	);

	pipelined_equal_32 is_stb_end_eq_inst (
		.clk_i	(clk_i),
		.a_i	(t_cnt),
		.b_i	(latched_stb_end_res),
		.eq_o	(is_stb_end),
		.ena_i	(1'b1)
	);

	pipelined_equal_32 is_gen_start_eq_inst (
		.clk_i	(clk_i),
		.a_i	(t_cnt),
		.b_i	(latched_gen_start_res),
		.eq_o	(is_gen_start),
		.ena_i	(gen_start_eq_ena)
	);

	always_ff @(posedge clk_i, negedge arstn_i) begin
		if (~arstn_i) begin
			int_stb = 0;
		end else begin
			case (1) 
				is_zero_hold_start: int_stb <= 0;
				is_stb_end:			int_stb <= 1;
				default:			int_stb <= int_stb;
			endcase
		end
	end

	always_ff @(posedge clk_i, negedge arstn_i) begin
		if (~arstn_i) rdy_o = 0;
		else if (state == COUNT_STROBE) rdy_o <= 1;
	end

	always_ff @(posedge clk_i) begin
		err_o <= (state == FIND_EDGE_1 ? 0 : err_o);
	end

	// always_ff @(posedge clk_i) t_end <= (state == WRITE_END ? t_cnt : t_end);

	always_ff @(posedge clk_i) t_start <= (state == WRITE_START ? t_cnt : t_start);

	// pipelined counter

	logic [T_CNT_WIDTH/2-1 : 0] high_bytes = 0 			/* synthesis syn_keep=1 syn_preserve=1 syn_ramstyle="registers" */;
	logic [T_CNT_WIDTH/2-1 : 0] latched_low_bytes = 0 	/* synthesis syn_keep=1 syn_preserve=1 syn_ramstyle="registers" */;
	logic [T_CNT_WIDTH/2-1 : 0] low_bytes = 0 			/* synthesis syn_keep=1 syn_preserve=1 syn_ramstyle="registers" */;
	logic [T_CNT_WIDTH/2-1 : 0] low_bytes_plus_1;
	logic carry;

	assign {carry, low_bytes_plus_1} = low_bytes + 1;

	//incrementing low bytes
	always_ff @(posedge clk_i, negedge arstn_i) 
		if (~arstn_i) low_bytes = 0;
		else low_bytes <= low_bytes_plus_1;

	//latching low bytes for 1 cycle
	always_ff @(posedge clk_i, negedge arstn_i) 
		if (~arstn_i) latched_low_bytes = 0;
		else latched_low_bytes <= low_bytes;

	logic latched_carry = 0;

	//latching carry
	always_ff @(posedge clk_i, negedge arstn_i) 
		if (~arstn_i) latched_carry = 0;
		else latched_carry <= carry;

	//adding latched carry to high bytes
	always_ff @(posedge clk_i, negedge arstn_i)
		if (~arstn_i) high_bytes = 0;
		else high_bytes <= high_bytes + latched_carry;

	//seting t_cnt
	always_ff @(posedge clk_i, negedge arstn_i) 
		if (~arstn_i) t_cnt = 0;
		else t_cnt <= {high_bytes, latched_low_bytes};

endmodule