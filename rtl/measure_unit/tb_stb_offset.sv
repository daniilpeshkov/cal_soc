
`timescale 1ns/10ps


`include "stb_gen.sv"
`include "sync_ff.sv"
`include "two_cycle_32_adder.sv"

`define DUMPVARS
// `undef DUMPVARS    

module tb_stb_gen();

    localparam CLK_T = 8; // clk period
    localparam T_CNT_WIDTH = 32;

    logic clk_i = 0;
    logic cmp_out = 0;
    logic arstn_i = 0;
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
        .sig_i (cmp_out),
        .arstn_i(~arstn_i),
        .*
    );

    //generate master signal
    localparam SIG_PERIOD = 20; 
    int cnt = 0;

    always @(posedge clk_i) begin
        case (cnt)
            0: cmp_out <= 1;
            default: cmp_out <= 0;
        endcase
        case (cnt)
            SIG_PERIOD: cnt = 0;
            default: cnt += 1;
        endcase
    end

    initial begin 
        int t;

        time start;
        #1 arstn_i = 1;
        #1 arstn_i = 0;

        repeat (10)@(posedge debug_stb_o);
        start = $time;
        @(posedge debug_stb_o);
        t = $time - start;
        $display("generated strobe T= %d ns", t);
        $display("counted period=%d", stb_period_o * CLK_T);
        $display("");
        $display("OK!");
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