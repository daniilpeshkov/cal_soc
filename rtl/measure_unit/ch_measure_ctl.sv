
module ch_measure_ctl #(
	parameter DEFAULT_THRESHOLD_DELTA = 1,
	parameter DEFAULT_D_CODE_DELTA = 1    
) (
	input logic clk_i,
	input logic arst_i,

	//stb request interface
	output logic stb_req_o,
	input  logic stb_valid_i,

	//CMP input
	input logic cmp_out_i,

	//control threshold and delay delta
	input logic [15:0] threshold_delta_i,
	input logic [9:0] d_code_delta_i,

	//dac (threshold) output
	output logic [15:0] threshold_o,
	output logic threshold_wre_o,
	input logic threshold_rdy_i,

	//delay line
	output logic [9:0] d_code_o,

	//ctl
	input logic run_i,

	//TODO output measured value
	output logic point_rdy_o,
	output logic [15:0] point_v_o,
	output logic [9:0] point_t_o
);

	enum logic[8:0] { 
		IDLE 		        ,//= 9'b000000001,
		SET_THRESHOLD 		,//= 9'b000000010,
		WAIT_THRESHOLD 		,//= 9'b000000100,
		REQ_STROBE 			,//= 9'b000001000,
		WAIT_STROBE			,//= 9'b000010000,
		SAVE_CMP_RES		,//= 9'b000100000
		PROCESS_RES			,
		UPDATE_CONF						
	} ctl_state, next_ctl_state;

	enum logic [1:0] {
		DIR_UP		= 2'b01,
		DIR_DOWN	= 2'b10
	} threshold_dir;

	enum logic [1:0] {
		FIND_DIR	= 2'b01,
		FIND_POINT	= 2'b10
	} point_state, next_point_state;

	logic cur_cmp_out, prev_cmp_out;

	always_comb begin : next_ctl_state_comb
		if (~run_i) begin
			next_ctl_state = IDLE;
		end else begin
			case (ctl_state)
				IDLE:   			next_ctl_state = SET_THRESHOLD;
				SET_THRESHOLD:		next_ctl_state = WAIT_THRESHOLD;
				WAIT_THRESHOLD:		if (threshold_rdy_i) next_ctl_state = REQ_STROBE;
									else next_ctl_state = ctl_state;
				REQ_STROBE:			next_ctl_state = WAIT_STROBE;	
				WAIT_STROBE:		if (stb_valid_i) next_ctl_state = SAVE_CMP_RES;
									else next_ctl_state = ctl_state;

				SAVE_CMP_RES:		next_ctl_state = PROCESS_RES;
				PROCESS_RES:		next_ctl_state = UPDATE_CONF;
				UPDATE_CONF:		next_ctl_state = SET_THRESHOLD;

			endcase
		end
	end

	always_comb begin : next_point_state_comb
		if (ctl_state == PROCESS_RES) begin
			case (point_state) /* synthesis full_case */
				FIND_POINT: if (cur_cmp_out != prev_cmp_out) next_point_state = FIND_DIR;
							else next_point_state = point_state;
				FIND_DIR:	next_point_state = FIND_POINT;
			endcase
		end else begin
			next_point_state = point_state;
		end
	end

	always_ff @(posedge clk_i, negedge arst_i) begin
		if (~arst_i) begin
			cur_cmp_out = 1;
		end else if (ctl_state == SAVE_CMP_RES) begin
			cur_cmp_out <= cmp_out_i;
			prev_cmp_out <= cur_cmp_out;
		end
	end

	always_ff @(posedge clk_i, negedge arst_i) begin : ctl_state_ff
		if (~arst_i) begin
			ctl_state = IDLE;
		end else begin
			ctl_state <= next_ctl_state;
		end
	end

	logic [15:0] next_threshold;
	logic [9:0]	 next_d_code;

	always_comb begin : next_threshold_comb
		case (ctl_state)
			IDLE:			next_threshold = 0;
			UPDATE_CONF:	if (point_state == FIND_POINT) begin
								case (threshold_dir) /* synthesis full_case */
									DIR_UP: 	next_threshold = threshold_o + threshold_delta_i;
									DIR_DOWN:	next_threshold = threshold_o - threshold_delta_i;	
								endcase
							end else begin
								next_threshold = threshold_o;
							end
			default:		next_threshold = threshold_o;
		endcase
	end

	always_comb begin : next_d_code_comb
		case (ctl_state)
			IDLE:			next_d_code = 0;
			UPDATE_CONF:	if (point_state == FIND_DIR) begin
				   				next_d_code = d_code_o + d_code_delta_i;
							end else begin
								next_d_code = d_code_o;
							end
			default:		next_d_code = d_code_o;
		endcase
	end

	always_ff @(posedge clk_i, negedge arst_i) begin : threshold_ff
		if (~arst_i) begin
			threshold_o = 0;
		end else begin
			threshold_o <= next_threshold;
		end
	end

	always_ff @(posedge clk_i, negedge arst_i) begin : threshold_wre_ff
		if (~arst_i) begin
			threshold_wre_o = 0;
		end else begin
			case (ctl_state)
				SET_THRESHOLD:  threshold_wre_o <= 1;
				default:        threshold_wre_o <= 0; 
			endcase
		end
	end

	always_ff @(posedge clk_i, negedge arst_i) begin : stb_req_ff
		if (~arst_i) begin
			stb_req_o = 0;
		end else begin
			case (ctl_state)
				REQ_STROBE: stb_req_o <= 1;
				default:	stb_req_o <= 0;
			endcase
		end
	end

	always_ff @(posedge clk_i, negedge arst_i) begin : threshold_dir_ff
		if (~arst_i) begin
			threshold_dir = DIR_UP;
		end else begin
			if (ctl_state == PROCESS_RES & point_state == FIND_DIR) begin
				case ({cur_cmp_out, prev_cmp_out})
					2'b10:		threshold_dir <= DIR_DOWN;	
					2'b01:		threshold_dir <= DIR_UP;	
					default: 	threshold_dir <= (threshold_dir == DIR_DOWN ? DIR_UP : DIR_DOWN);
				endcase
			end
		end
	end

	always_ff @(posedge clk_i, negedge arst_i) begin : point_state_ff
		if (~arst_i) begin
			point_state = FIND_POINT;
		end else begin
			point_state <= next_point_state;
		end
	end

	always_ff @(posedge clk_i, negedge arst_i) begin : d_code_ff
		if (~arst_i) begin
			d_code_o = 0;
		end else begin
			d_code_o <= next_d_code;
		end
	end

	always_ff @(posedge clk_i, negedge arst_i) begin : point_rdy_ff
		if (~arst_i) begin
			point_rdy_o = 0;
		end else begin
			if (ctl_state == PROCESS_RES & cur_cmp_out != prev_cmp_out) point_rdy_o <= 1;
			else point_rdy_o <= 0;
		end
	end

endmodule