`timescale 1ns/1ns


`include "pipelined_adder_32.sv"
`include "pipelined_equal_32.sv"
`include "stb_gen.sv"
`include "sync_ff.sv"

`define DUMPVARS
// `undef DUMPVARS    

module tb_stb_gen();

    localparam CLK_T = 8; // clk period
    localparam SIG_WIDTH = 20;
    localparam T_CNT_WIDTH = 32;

    int freqs[] = { 13, 13};

    logic clk_i = 0;
    logic comp_out = 0;
    logic arstn_i = 0;
    logic stb_o;
    logic err_o;
    logic rdy_o;
    logic [T_CNT_WIDTH-1:0] stb_period_o;
	logic stb_req_i = 1;
	logic stb_valid_o;
	logic debug_stb_o;

    stb_gen dut (
        .sig_i (comp_out),
        .arstn_i(~arstn_i),
        .*
    );

    int cur_sig_width = 10;

    initial forever begin
        comp_out <= 1;
        @(posedge clk_i)
        comp_out <= 0;
        repeat (cur_sig_width - 1) @(posedge clk_i);

        // #(SIG_WIDTH) comp_out = 0;
        // #(cur_sig_width - SIG_WIDTH);
    end

    initial begin 
        int t;
        time start;
        foreach (freqs[i]) begin
            cur_sig_width = freqs[i];
            #100
            @(posedge clk_i) arstn_i <= 1;
            repeat(5) @(posedge clk_i) ;
            arstn_i <= 0;

            repeat (10) @(posedge debug_stb_o);
            start = $time;
            @(posedge debug_stb_o);
            t = $time - start;
            $display("measured signal  T= %d ns", freqs[i] * CLK_T);
            $display("generated strobe T= %d ns", t);
            $display("err=%d ns\tclk T= %3d ns", t - freqs[i]*CLK_T, CLK_T);
            $display("counted period=%d", stb_period_o * CLK_T);
            $display("");
            if ($max(t, freqs[i] * CLK_T) - $min(t, freqs[i] * CLK_T) >= CLK_T) begin
                #100
                $fatal(1, "error is more than clk T");
            end
        end
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