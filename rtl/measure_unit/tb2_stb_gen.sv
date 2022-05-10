
`timescale 1ns/1ns

module tb_stb_gen();

`define DUMPVARS
`undef DUMPVARS    

    localparam T_CNT_WIDTH = 32;
    localparam  CLK_T = 8; // clk period
    localparam SIG_PERIOD = 133333;
    localparam SIG_WIDTH = 300;

    logic clk_i = 0;
    logic sig_i = 0;
    logic arst_i = 0;
    logic stb_o;
    logic run_det_i = 1;
    logic err_o;
    logic oe_i = 1;
    logic rdy_o;
    logic [T_CNT_WIDTH-1:0] stb_period_o;

    stb_gen #(
        .T_CNT_WIDTH (T_CNT_WIDTH)
    ) dut (.*);

    initial begin
        run_det_i = 1;
        #2 arst_i = 1;
        #2 arst_i = 0;
        repeat (10) begin
            @(posedge rdy_o);
            $display("%d", stb_period_o * CLK_T);
            run_det_i = 0;
            #(CLK_T*2)
            run_det_i = 1;
        end
        $finish;
    end

    initial begin
        #3
        forever begin
            #(SIG_PERIOD-SIG_WIDTH) sig_i = 1;
            #(SIG_WIDTH) sig_i = 0;
        end
    end

    initial begin 
`ifdef DUMPVARS
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_stb_gen);
`endif
    end

    always #(CLK_T/2) clk_i = ~clk_i;

endmodule