
module gpo #(
	parameter WIDTH = 8
) (
// WISHBONE Interface
	input wire wb_clk_i, 
	input wire wb_rst_i, 
	input wire wb_cyc_i, 
	input wire [31:0] wb_adr_i,
	input wire [31:0] wb_dat_i, 
	input wire [3:0] wb_sel_i, 
	input wire wb_we_i, 
	input wire wb_stb_i,
	output wire [31:0] wb_dat_o, 
	output wire wb_ack_o, 
	output wire wb_err_o,
// output
	output reg [W-1:0] gpo_o
);
	localparam W = (WIDTH <= 32 ? WIDTH : 32);


endmodule