

module wb_diff_inv #(
    parameter OUT_WIDTH = 8,
    parameter IN_WIDTH = 8
) (
	input   logic        wb_clk_i,
	input   logic        wb_rst_i,			
	input   logic [31:0] wb_dat_i,   
	output  logic [31:0] wb_dat_o,
	input   logic [31:0] wb_adr_i,
	input   logic	 	 wb_we_i,
	input   logic [3:0]  wb_sel_i,
	input   logic	 	 wb_cyc_i,
	input   logic	 	 wb_stb_i,
	output  logic 		 wb_ack_o,

    input   logic  [OUT_WIDTH-1:0] sig_out_i,
    output  logic  [OUT_WIDTH-1:0] sig_out_p_o
    output  logic  [OUT_WIDTH-1:0] sig_out_n_o
    
    output logic  [OUT_WIDTH-1:0] sig_in_o,
    input  logic  [OUT_WIDTH-1:0] sig_in_p_i,
    input  logic  [OUT_WIDTH-1:0] sig_in_n_i
);

    logic [IN_WIDTH-1:0] in_mux_reg;
    logic [IN_WIDTH-1:0] out_mux_reg;

    genvar i;

    generate
        for (i = 0; i < IN_WIDTH; i = i + 1) begin
            TLVDS_IBUF lvds_IBUF_inst (
                .I	(in_mux_reg[i] ? sig_in_p_i[i] : sig_in_n_i[i]),
                .IB	(in_mux_reg[i] ? sig_in_n_i[i] : sig_in_p_i[i]),
                .O	(sig_in_o)
            );
        end

        for (i = 0; i < OUT_WIDTH; i = i + 1) begin
            TLVDS_OBUF lvds_OBUF_inst (
                .I	(sig_out_i),
                .O	(out_mux_reg[i] ? sig_out_p_o[i] : sig_out_n_o)
                .OB	(out_mux_reg[i] ? sig_out_n_o[i] : sig_out_p_o),
            );
        end


    endgenerate



endmodule