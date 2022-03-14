module gw_gao(
    \wbm_adr_o[31] ,
    \wbm_adr_o[30] ,
    \wbm_adr_o[29] ,
    \wbm_adr_o[28] ,
    \wbm_adr_o[27] ,
    \wbm_adr_o[26] ,
    \wbm_adr_o[25] ,
    \wbm_adr_o[24] ,
    \wbm_adr_o[23] ,
    \wbm_adr_o[22] ,
    \wbm_adr_o[21] ,
    \wbm_adr_o[20] ,
    \wbm_adr_o[19] ,
    \wbm_adr_o[18] ,
    \wbm_adr_o[17] ,
    \wbm_adr_o[16] ,
    \wbm_adr_o[15] ,
    \wbm_adr_o[14] ,
    \wbm_adr_o[13] ,
    \wbm_adr_o[12] ,
    \wbm_adr_o[11] ,
    \wbm_adr_o[10] ,
    \wbm_adr_o[9] ,
    \wbm_adr_o[8] ,
    \wbm_adr_o[7] ,
    \wbm_adr_o[6] ,
    \wbm_adr_o[5] ,
    \wbm_adr_o[4] ,
    \wbm_adr_o[3] ,
    \wbm_adr_o[2] ,
    \wbm_adr_o[1] ,
    \wbm_adr_o[0] ,
    wbm_stb_o,
    wbm_ack_i,
    wbm_cyc_o,
    \wbm_sel_o[3] ,
    \wbm_sel_o[2] ,
    \wbm_sel_o[1] ,
    \wbm_sel_o[0] ,
    wbm_we_o,
    wbm_stall_i,
    wbm_err_i,
    ram_wb_ack_o,
    clk,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \wbm_adr_o[31] ;
input \wbm_adr_o[30] ;
input \wbm_adr_o[29] ;
input \wbm_adr_o[28] ;
input \wbm_adr_o[27] ;
input \wbm_adr_o[26] ;
input \wbm_adr_o[25] ;
input \wbm_adr_o[24] ;
input \wbm_adr_o[23] ;
input \wbm_adr_o[22] ;
input \wbm_adr_o[21] ;
input \wbm_adr_o[20] ;
input \wbm_adr_o[19] ;
input \wbm_adr_o[18] ;
input \wbm_adr_o[17] ;
input \wbm_adr_o[16] ;
input \wbm_adr_o[15] ;
input \wbm_adr_o[14] ;
input \wbm_adr_o[13] ;
input \wbm_adr_o[12] ;
input \wbm_adr_o[11] ;
input \wbm_adr_o[10] ;
input \wbm_adr_o[9] ;
input \wbm_adr_o[8] ;
input \wbm_adr_o[7] ;
input \wbm_adr_o[6] ;
input \wbm_adr_o[5] ;
input \wbm_adr_o[4] ;
input \wbm_adr_o[3] ;
input \wbm_adr_o[2] ;
input \wbm_adr_o[1] ;
input \wbm_adr_o[0] ;
input wbm_stb_o;
input wbm_ack_i;
input wbm_cyc_o;
input \wbm_sel_o[3] ;
input \wbm_sel_o[2] ;
input \wbm_sel_o[1] ;
input \wbm_sel_o[0] ;
input wbm_we_o;
input wbm_stall_i;
input wbm_err_i;
input ram_wb_ack_o;
input clk;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \wbm_adr_o[31] ;
wire \wbm_adr_o[30] ;
wire \wbm_adr_o[29] ;
wire \wbm_adr_o[28] ;
wire \wbm_adr_o[27] ;
wire \wbm_adr_o[26] ;
wire \wbm_adr_o[25] ;
wire \wbm_adr_o[24] ;
wire \wbm_adr_o[23] ;
wire \wbm_adr_o[22] ;
wire \wbm_adr_o[21] ;
wire \wbm_adr_o[20] ;
wire \wbm_adr_o[19] ;
wire \wbm_adr_o[18] ;
wire \wbm_adr_o[17] ;
wire \wbm_adr_o[16] ;
wire \wbm_adr_o[15] ;
wire \wbm_adr_o[14] ;
wire \wbm_adr_o[13] ;
wire \wbm_adr_o[12] ;
wire \wbm_adr_o[11] ;
wire \wbm_adr_o[10] ;
wire \wbm_adr_o[9] ;
wire \wbm_adr_o[8] ;
wire \wbm_adr_o[7] ;
wire \wbm_adr_o[6] ;
wire \wbm_adr_o[5] ;
wire \wbm_adr_o[4] ;
wire \wbm_adr_o[3] ;
wire \wbm_adr_o[2] ;
wire \wbm_adr_o[1] ;
wire \wbm_adr_o[0] ;
wire wbm_stb_o;
wire wbm_ack_i;
wire wbm_cyc_o;
wire \wbm_sel_o[3] ;
wire \wbm_sel_o[2] ;
wire \wbm_sel_o[1] ;
wire \wbm_sel_o[0] ;
wire wbm_we_o;
wire wbm_stall_i;
wire wbm_err_i;
wire ram_wb_ack_o;
wire clk;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top_0  u_la0_top(
    .control(control0[9:0]),
    .trig0_i(ram_wb_ack_o),
    .trig1_i(wbm_stb_o),
    .data_i({\wbm_adr_o[31] ,\wbm_adr_o[30] ,\wbm_adr_o[29] ,\wbm_adr_o[28] ,\wbm_adr_o[27] ,\wbm_adr_o[26] ,\wbm_adr_o[25] ,\wbm_adr_o[24] ,\wbm_adr_o[23] ,\wbm_adr_o[22] ,\wbm_adr_o[21] ,\wbm_adr_o[20] ,\wbm_adr_o[19] ,\wbm_adr_o[18] ,\wbm_adr_o[17] ,\wbm_adr_o[16] ,\wbm_adr_o[15] ,\wbm_adr_o[14] ,\wbm_adr_o[13] ,\wbm_adr_o[12] ,\wbm_adr_o[11] ,\wbm_adr_o[10] ,\wbm_adr_o[9] ,\wbm_adr_o[8] ,\wbm_adr_o[7] ,\wbm_adr_o[6] ,\wbm_adr_o[5] ,\wbm_adr_o[4] ,\wbm_adr_o[3] ,\wbm_adr_o[2] ,\wbm_adr_o[1] ,\wbm_adr_o[0] ,wbm_stb_o,wbm_ack_i,wbm_cyc_o,\wbm_sel_o[3] ,\wbm_sel_o[2] ,\wbm_sel_o[1] ,\wbm_sel_o[0] ,wbm_we_o,wbm_stall_i,wbm_err_i}),
    .clk_i(clk)
);

endmodule
