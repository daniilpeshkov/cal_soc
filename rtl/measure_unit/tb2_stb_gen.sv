`timescale 1ns/1ns

module tb_stb_gen();

    localparam CLK_T = 8; // clk period
    localparam SIG_WIDTH = 20;

    localparam T_CNT_WIDTH = 32;

`define DUMPVARS
// `undef DUMPVARS    

    int sig_T = 20000;

    logic clk_i = 0;
    logic comp_out = 0;
    logic arst_i = 0;
    logic stb_o;
    logic run_det_i = 0;
    logic err_o;
    logic oe_i = 1;
    logic rdy_o;
    logic [T_CNT_WIDTH-1:0] stb_period_o;
	logic stb_req_i = 0;
	logic stb_valid_o;
	logic debug_stb_o;

    stb_gen dut (
        .sig_i (comp_out),
        .arst_i(~arst_i),
        .*
    );

    initial forever begin
        comp_out = 1;
        #(SIG_WIDTH) comp_out = 0;
        #(sig_T - SIG_WIDTH);
    end


    initial begin 

        #1 arst_i = 1;
        #1 arst_i = 0;

        repeat (5)@(posedge debug_stb_o);
        stb_req_i = 1;
        @(posedge stb_valid_o);
        stb_req_i = 0;
        #50000
        stb_req_i = 1;

        repeat (5)@(posedge debug_stb_o);
        $finish;
    end

    initial begin 
`ifdef DUMPVARS
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_stb_gen);
`endif
    end

    always #(CLK_T/2) clk_i = ~clk_i;

endmodule