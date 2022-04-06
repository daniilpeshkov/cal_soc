//------------------------------------------------------
//	Wishbone rom
//------------------------------------------------------
//	author:  	Peshkov Daniil
//	email:  	daniil.peshkov@spbpu.com
//------------------------------------------------------

module wb_rom #(
	parameter W_WIDTH = 32,
	parameter mem_init_file = "",
	parameter word_count = 0
) (
	input wire clk_i,
	input wire rst_i,			
//wb signals
	input  wire	[31:0]	wb_dat_i,   
	output reg	[31:0]	wb_dat_o,
	input  wire	[31:0] 	wb_adr_i,
	input  wire	 		wb_we_i,
	input  wire	[3:0] 	wb_sel_i,
	input  wire	 		wb_cyc_i,
	input  wire	 		wb_stb_i,
	output reg 		 	wb_ack_o,
	output wire			wb_stall_o
);

	reg [W_WIDTH-1:0] rom [0:word_count-1];

	initial
		$readmemh(mem_init_file, rom);
		
	always @(posedge clk_i) begin
		if (wb_stb_i == 1 && wb_cyc_i == 1 && wb_we_i== 0) begin
			wb_dat_o <= rom[wb_adr_i>>2];
			wb_ack_o <= 1;
		end else begin 
			wb_dat_o  <= 0;
			wb_ack_o  <= 0;
		end
	end

endmodule
   
   