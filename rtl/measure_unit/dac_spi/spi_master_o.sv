//tested with AD5300
//write only
module spi_master_o #(
	parameter DATA_WIDTH = 8,
	parameter CLK_DIV = 3,
	parameter WAIT_CYCLES = 3
) (
	input   clk_i,
	input   arst_i,

	input   [DATA_WIDTH-1:0] data_i,
	input        wre_i,

	output       rdy_o,

	output logic sdi_o,
	output logic sclk_o,
	output logic sync_o
);
////////////////////////////////////////////////////////////////////////////
	logic sclk_pos, sclk_neg;

	clk_divider #(CLK_DIV) spi_clk_div (
		.arst_i(arst_i),
		.clk_i(clk_i),
		.clk_o(sclk_o),
		.posedge_o(sclk_pos),
		.negedge_o(sclk_neg)
	);
////////////////////////////////////////////////////////////////////////////
	typedef enum  logic [1:0] {IDLE, SEND, WAIT} spi_master_state;

	spi_master_state state;
	logic [DATA_WIDTH:0] shift_reg;
	logic [$clog2(DATA_WIDTH) : 0] bit_cnt;

	assign rdy = (state == IDLE);
	assign sdi_o = shift_reg[DATA_WIDTH];

	always_ff @(posedge clk_i, posedge arst_i) begin
		if (arst_i) begin
			state = IDLE;
			sync_o = 1;
		end else begin
			case (state)
				IDLE: begin 
					if (wre_i) begin
						shift_reg <= {'0, data_i};						
						state <= SEND;
						bit_cnt <= DATA_WIDTH+1;
						sync_o <= 0;
					end
				end
				SEND: begin
					if (sclk_neg) begin
						sync_o <= 0;
					end
					if (sclk_pos) begin
						shift_reg <= shift_reg << 1;
						bit_cnt <= bit_cnt - 1;
						if (bit_cnt == 0) begin
							sync_o <= 1;
							state = WAIT;
							bit_cnt <= WAIT_CYCLES - 1;
						end
					end
				end
				WAIT: begin 
					bit_cnt <= bit_cnt - 1;
					if (bit_cnt == 0) begin 
						state <= IDLE;
					end		
				end
			endcase	
		end
	end
////////////////////////////////////////////////////////////////////////////
endmodule
