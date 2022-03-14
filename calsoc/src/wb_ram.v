


module wb_ram #(
	parameter DATA_WIDTH = 32,
	parameter WORD_COUNT = 32
) (
	input clk_i,
	input rst_i,			
//wb signals
	input  wire	[31:0]	wb_dat_i,   
	output wire	[31:0]	wb_dat_o,
	input  wire	[31:0] 	wb_adr_i,
	input  wire	 		wb_we_i,
	input  wire	[3:0] 	wb_sel_i,
	input  wire	 		wb_cyc_i,
	input  wire	 		wb_stb_i,
	output reg 		 	wb_ack_o,
	output wire			wb_stall_o,
	input  wire			wb_cti_i
);

	localparam ADDR_WIDTH = $clog2(WORD_COUNT);
   
	wire [31:0] wr_data;
   
   // mux for data to ram
   assign wr_data[31:24] = wb_sel_i[3] ? wb_dat_i[31:24] : wb_dat_o[31:24];
   assign wr_data[23:16] = wb_sel_i[2] ? wb_dat_i[23:16] : wb_dat_o[23:16];
   assign wr_data[15: 8] = wb_sel_i[1] ? wb_dat_i[15: 8] : wb_dat_o[15: 8];
   assign wr_data[ 7: 0] = wb_sel_i[0] ? wb_dat_i[ 7: 0] : wb_dat_o[ 7: 0];
   
   ram #(
		.dat_width(DATA_WIDTH),
		.adr_width(ADDR_WIDTH),
		.mem_size(WORD_COUNT)
	) ram0 (
		.dat_i(wr_data),
		.dat_o(wb_dat_o),
		.adr_i(wb_adr_i>>2), 
		.we_i(wb_we_i & wb_ack_o),
		.clk(clk_i)
	);
 
   // ack_o
	always @ (posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
			wb_ack_o <= 1'b0;
		end else begin
			if (!wb_ack_o) begin
				if (wb_cyc_i & wb_stb_i) wb_ack_o <= 1'b1; 
			end else if ((wb_sel_i != 4'b1111) | (wb_cti_i == 3'b000) | (wb_cti_i == 3'b111))
				wb_ack_o <= 1'b0;
		end
	end 
endmodule
 
	      