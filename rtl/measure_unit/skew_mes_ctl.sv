
module skew_mes_ctl (
	input logic clk_i,
	input logic arstn_i,

	input 	logic 		cmp_out_i,
	output 	logic [9:0] delay_code_o,

	input 	logic 		run_i,
	output	logic 		err_o,
	output	logic		rdy_o,

	output 	logic 		stb_req_o,
	input 	logic 		stb_valid_i
);

	enum logic[9:0] {
		IDLE,
		REQ_STB,
		WAIT_STB,
		PROCESS_RES,
		ERR,
		READY,
		INC_DELAY
	} state = IDLE, next_state;

	assign err_o = (state == ERR);
	assign rdy_o = (state == READY);
	
	always_comb begin : next_state_comb
		if (~run_i) begin
			next_state = IDLE;
		end else begin
			case (state)
				IDLE:			next_state = REQ_STB;
				REQ_STB:		next_state = WAIT_STB;
				WAIT_STB:		if (stb_valid_i) next_state = PROCESS_RES;
								else next_state = state;
				PROCESS_RES:	if (cmp_out_i) 
									if (~|delay_code_o) next_state = ERR; 
									else next_state = READY;
								else next_state = INC_DELAY;
				INC_DELAY:		if (&delay_code_o) next_state = ERR;
								else next_state = REQ_STB;

				default: 	next_state = state;
			endcase
		end
	end

	always_ff @(posedge clk_i, negedge arstn_i) begin : state_ff
		if (~arstn_i) state = IDLE;
		else state <= next_state;
	end

	always_ff @(posedge clk_i, negedge arstn_i) begin : delay_code_ff
		if (~arstn_i) delay_code_o = 0;
		else if (state == INC_DELAY) delay_code_o <= delay_code_o + 1;
		else if (state == IDLE) delay_code_o <= 0;
	end

	always_ff @(posedge clk_i, negedge arstn_i) begin : stb_req_ff
		if (~arstn_i) stb_req_o = 0;
		else if (state == REQ_STB) stb_req_o <= 1;
		else stb_req_o <= 0;
		// else if (state == PROCESS_RES) stb_req_o <= 0;
	end

endmodule