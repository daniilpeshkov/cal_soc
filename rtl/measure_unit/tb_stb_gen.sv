`timescale 1ns/1ns


module tb_stb_gen();

    localparam CLK_T = 8; // clk period
    localparam SIG_WIDTH = 20;

    localparam T_CNT_WIDTH = 32;

`define DUMPVARS
// `undef DUMPVARS    

    int freqs[] = { 100, 20000,200000, 1333333};

    logic clk_i = 0;
    logic comp_out = 0;
    logic arst_i = 0;
    logic stb_o;
    logic run_det_i = 0;
    logic err_o;
    logic oe_i = 1;
    logic rdy_o;
    logic [T_CNT_WIDTH-1:0] stb_period_o;
	logic stb_req_i;
	logic stb_valid_o;
	logic debug_stb_o;

    stb_gen dut (
        .sig_i (comp_out),
        .arst_i(~arst_i),
        .*
    );
    // initial #524400 $finish;
    initial begin 
        int t;

        time start;
        foreach (freqs[i]) begin
            #1 arst_i = 1;
            #1 arst_i = 0;
            #10 run_det_i = 1;
            #333 run_det_i = 0;
            #($urandom_range(1, CLK_T));
            while (!rdy_o) begin
                comp_out = 1;
                #(SIG_WIDTH) comp_out = 0;
                #(freqs[i] - SIG_WIDTH);
            end

            repeat (10)@(posedge debug_stb_o);
            start = $time;
            @(posedge debug_stb_o);
            t = $time - start;
            $display("measured signal  T= %d ns", freqs[i]);
            $display("generated strobe T= %d ns", t);
            $display("err=%d ns\tclk T= %3d ns", t - freqs[i], CLK_T);
            $display("counted period=%d", stb_period_o * CLK_T);
            $display("");
            if ($abs(t - freqs[i]) >= CLK_T) begin
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