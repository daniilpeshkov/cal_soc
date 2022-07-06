
module skew_mes_ctl (
	input logic clk_i,
	input logic arstn_i,

	input 	logic 		cmp_out_i,
	output 	logic [9:0] delay_code_o,

	input 	logic 		run_i,

	output 	logic 		stb_req_o,
	input 	logic 		stb_valid_i
);

	assign stb_req_o = 0;

	enum logic[9:0] {
		IDLE,
		ERR
	} state = IDLE, next_state;

	always_comb begin : next_state_comb
		if (~run) begin
			next_state = IDLE;
		end else begin
			case (state)



			endcase
		end
	end


endmodule