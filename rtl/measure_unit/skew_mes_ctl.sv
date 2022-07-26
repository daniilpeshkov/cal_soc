
module skew_mes_ctl (
	input logic clk_i,
	input logic arstn_i,

	input 	logic 		m_cmp_out_i,
	input	logic		s_cmp_out_i,
	output 	logic [9:0] delay_code_o,

	output 	logic [9:0] res_o,

	input 	logic 		run_i,
	output	logic [2:0]	err_o,
	output	logic		rdy_o,

	output 	logic 		stb_req_o,
	input 	logic 		stb_valid_i
);

	enum logic [9:0] {
		IDLE,
		REQ_STB,
		WAIT_STB,
		PROCESS_RES,
		ERR,
		READY,
		INC_DELAY
	} state = IDLE, next_state;

	enum logic [1:0] {
		MASTER_ALIGN,
		SKEW_MEASURE
	} mes_state = MASTER_ALIGN, next_mes_state; 

	logic cmp_out;
	logic [9:0]	m_align_delay_code;

	typedef enum logic [2:0] {
		NO_ERR, 
		CAN_NOT_ALIGN_MASTER,
		CAN_NOT_MEASURE_SKEW
	} err_type_t;

	always_comb begin : err_o_comb
		if (state == ERR) begin
			if (mes_state == MASTER_ALIGN)
				err_o = CAN_NOT_ALIGN_MASTER;
			else
				err_o = CAN_NOT_MEASURE_SKEW;
		end else begin
			err_o = NO_ERR;
		end
	end

	assign rdy_o = (state == READY);

	assign cmp_out = (mes_state == MASTER_ALIGN ? m_cmp_out_i : s_cmp_out_i);


	always_comb begin : next_state_comb
		if (~run_i) begin
			next_state = IDLE;
		end else begin
			case (state)
				IDLE:			next_state = REQ_STB;
				REQ_STB:		next_state = WAIT_STB;
				WAIT_STB:		if (stb_valid_i) next_state = PROCESS_RES;
								else next_state = state;
				PROCESS_RES:	if (cmp_out) begin
									if (delay_code_o == 0) begin
										next_state = ERR; // delay_code_o == 0
									end else begin
										if (mes_state == MASTER_ALIGN)
											next_state = REQ_STB;	
										else
											next_state = READY;
									end
								end
								else next_state = INC_DELAY;
				INC_DELAY:		if (&delay_code_o) next_state = ERR;
								else next_state = REQ_STB;

				default: 	next_state = state;
			endcase
		end
	end

	logic posedge_found;
	assign posedge_found = (state == PROCESS_RES && cmp_out == 1);

	always_comb begin : next_mes_state_comb
		if (~run_i) begin
			next_mes_state = MASTER_ALIGN;
		end else begin
			case (mes_state)
				MASTER_ALIGN: 	if (posedge_found && delay_code_o != 0)
									next_mes_state = SKEW_MEASURE;
								else
									next_mes_state = mes_state;
				default: next_mes_state = mes_state;
			endcase
		end
	end

	always_ff @(posedge clk_i) begin : res_o_ff
		if (posedge_found) begin
			res_o <= delay_code_o - m_align_delay_code;
		end
	end

	always_ff @(posedge clk_i) begin : m_align_delay_code_ff
		if (posedge_found && mes_state == MASTER_ALIGN) begin
			m_align_delay_code <= delay_code_o;
		end
	end

	always_ff @(posedge clk_i, negedge arstn_i) begin : state_ff
		if (~arstn_i) state = IDLE;
		else state <= next_state;
	end

	always_ff @(posedge clk_i, negedge arstn_i) begin : mes_state_ff
		if (~arstn_i) mes_state = MASTER_ALIGN;
		else mes_state <= next_mes_state;
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
	end

endmodule