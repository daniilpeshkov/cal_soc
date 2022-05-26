//------------------------------------------------------
//	Module for frequency measurement and strobe generation
//------------------------------------------------------
//	author:  	Peshkov Daniil
//	email:  	daniil.peshkov@spbpu.com
//------------------------------------------------------

module stb_gen #(
	parameter ZERO_HOLD_CYCLES = 10,
	parameter T_CNT_WIDTH = 32,
	parameter OFFSET = 20
) (
	input wire clk_i,
	input wire arst_i,

	input wire sig_i,
	input wire run_det_i,
	input wire oe_i,

	output logic err_o,
	output logic rdy_o,
	output logic stb_o,
	output logic [T_CNT_WIDTH-1:0] stb_period_o
);
	
	logic int_stb = 0;
	// assign stb_o = (int_stb & oe_i & ~err_o);
	assign stb_o = int_stb;

	logic sig_synced;

	sync_ff #(
		.WIDTH (1),
		.STAGES(2)
	) sig_i_sync_ff_inst (
		.clk_i (clk_i),
		.data_i(sig_i),
		.data_o(sig_synced)
	);

	logic run_det;

	sync_ff #(
		.WIDTH (1),
		.STAGES(2)
	) run_det_sync_ff_inst (
		.clk_i (clk_i),
		.data_i(run_det_i),
		.data_o(run_det)
	);

	logic prev_sig; //edge detect

	always_ff @(posedge clk_i) begin
		prev_sig <= sig_synced;
	end

	logic sig_posedge;
	assign sig_posedge = sig_synced & ~prev_sig;

	logic prev_run_det; //edge detect

	always_ff @(posedge clk_i) begin
		prev_run_det <= run_det;
	end

	logic run_det_posedge;
	assign run_det_posedge = run_det & ~prev_run_det;

	// assign rdy_o = state == IDLE;

	typedef enum logic[3:0] { 
		IDLE, FIND_EDGE_1, FIND_EDGE_2, WRITE_START,
		FIND_EDGE_3, WRITE_END, COUNT_PERIOD,
		WAIT_STB_START, COUNT_STB_ZERO_HOLD,
		WAIT_ZERO_HOLD, COUNT_STB_END 
	} stb_gen_state;

	stb_gen_state state = IDLE;

	logic [T_CNT_WIDTH-1 : 0] t_cnt;
	logic [T_CNT_WIDTH-1 : 0] t_start;
	logic [T_CNT_WIDTH-1 : 0] t_end;
	stb_gen_state next_state;

	logic cnt_eq;
	logic [T_CNT_WIDTH-1:0] period_minus_zero_hold;
	// assign period_minus_zero_hold = stb_period_o - ZERO_HOLD_CYCLES;

	always_ff @(posedge clk_i) period_minus_zero_hold <= stb_period_o - (ZERO_HOLD_CYCLES + 1);

	logic cnt_eq_latched;
	assign cnt_eq = t_cnt == t_start;

	always_ff @(posedge clk_i) begin
		cnt_eq_latched <= cnt_eq;
	end

	logic count_zero_hold_begin, zero_hold_begin_valid;
	logic count_stb_end, stb_end_valid;

	always_ff @(posedge clk_i, posedge arst_i) begin
		if (arst_i) rdy_o = 0;
		else if (state == WAIT_STB_START) rdy_o <= 1;
		else rdy_o <= rdy_o;
	end

	always_comb begin
		next_state = state;
		count_zero_hold_begin = 0;
		count_stb_end = 0;
		case (state)
			IDLE:					if (run_det_posedge) next_state = FIND_EDGE_1;
			FIND_EDGE_1:			if (sig_posedge) next_state = FIND_EDGE_2;
			FIND_EDGE_2:			if (sig_posedge) next_state = WRITE_START;
			WRITE_START:			next_state = FIND_EDGE_3;
			FIND_EDGE_3:			if (sig_posedge) next_state = WRITE_END;
			WRITE_END:				next_state = COUNT_PERIOD;
			COUNT_PERIOD:			next_state = WAIT_STB_START;
			WAIT_STB_START:			if (cnt_eq_latched) begin
										next_state = COUNT_STB_ZERO_HOLD;
										count_zero_hold_begin = 1;
									end
			COUNT_STB_ZERO_HOLD: 	if (zero_hold_begin_valid) next_state = WAIT_ZERO_HOLD;
			WAIT_ZERO_HOLD: 		if (cnt_eq_latched) begin
										next_state = COUNT_STB_END;
										count_stb_end = 1;
									end
			COUNT_STB_END: 			if (stb_end_valid) next_state = WAIT_STB_START;
		endcase
	end

	always_ff @(posedge clk_i, posedge arst_i) begin
		if (arst_i) begin
			state = IDLE;
		end else begin
			state <= next_state;
		end
	end

	always_ff @(posedge clk_i) begin
		err_o <= (state == FIND_EDGE_1 ? 0 : err_o);
	end

	always_ff @(posedge clk_i) begin
		t_end <= (state == WRITE_END ? t_cnt : t_end);
	end

	logic [31:0] adder_zero_hold_res;
	logic [31:0] adder_stb_end_res;

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
		.b_i	(ZERO_HOLD_CYCLES-1),
		.valid_i(count_stb_end),
		.valid_o(stb_end_valid),
		.res_o	(adder_stb_end_res)
	);

	always_ff @(posedge clk_i) begin
		case (state) 
			WRITE_START: 			t_start <= t_cnt;
			COUNT_STB_ZERO_HOLD: 	if (zero_hold_begin_valid) t_start <= adder_zero_hold_res; //t_cnt + period_minus_zero_hold;
									else t_start <= t_start;
			COUNT_STB_END: 			if (stb_end_valid) t_start <= adder_stb_end_res;//t_cnt + ZERO_HOLD_CYCLES;
									else t_start <= t_start;
			default: 				t_start <= t_start;
		endcase
	end

	always_ff @(posedge clk_i) begin
		stb_period_o <= (state == COUNT_PERIOD ? t_end - t_start : stb_period_o);
	end

	always_ff @(posedge clk_i, posedge arst_i) begin
		if (arst_i) begin
			int_stb = 0;
		end else begin
			if (state == COUNT_STB_ZERO_HOLD) int_stb <= 1;
			else if (state == COUNT_STB_END) int_stb <= 0;
			else int_stb <= int_stb;
		end
	end

	logic [15:0] low_bytes = 0;
	logic [15:0] high_bytes = 0;
	logic [15:0] latched_low_bytes = 0;
	logic latched_carry = 0;
	logic carry;

	logic [15:0] low_bytes_plus_1;
	assign {carry, low_bytes_plus_1} = low_bytes + 1;
  
	always @(posedge clk_i) begin
		t_cnt <= {high_bytes, latched_low_bytes};
		low_bytes <= low_bytes_plus_1;
		latched_low_bytes <= low_bytes[15:0];
		
		latched_carry <= carry;
		high_bytes <= high_bytes + latched_carry;
	end

endmodule