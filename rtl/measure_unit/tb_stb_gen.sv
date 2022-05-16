`timescale 1ns/1ns


module tb_stb_gen();

`define CLK_T 8 // clk period
`define SIG_WIDTH 300

    localparam T_CNT_WIDTH = 32;

`define DUMPVARS
// `undef DUMPVARS    

    int freqs[] = {10000, 20000, 1000000, 2000000, 1333333};

    logic clk_i = 0;
    logic comp_out = 0;
    logic arst_i = 0;
    logic stb_o;
    logic run_det_i = 1;
    logic err_o;
    logic oe_i = 1;
    logic rdy_o;
    logic [T_CNT_WIDTH-1:0] stb_period_o;

    stb_gen #(
        .T_CNT_WIDTH (T_CNT_WIDTH)
    ) dut (
        .sig_i (comp_out),
        .*
    );

    initial begin 
        int t;
        foreach (freqs[i]) begin
            run_det_i = 1;
            #2 arst_i = 1;
            #2 arst_i = 0;
            #(`CLK_T*2) run_det_i = 0;
            fork
                begin
                    repeat (4) begin
                        #($urandom_range(1, 7));
                        comp_out = 1;
                        #(`SIG_WIDTH) comp_out = 0;
                        #(freqs[i] - `SIG_WIDTH);
                    end
                end

                begin
                    time start;
                    @(posedge stb_o);
                    start = $time;
                    @(posedge stb_o);
                    t = $time - start;
                end
            join

            $display("stb T = %d ns \tsig T = %d ns \t\t with clk period %3d ns", t, freqs[i], `CLK_T);
        end
        $finish;
    end

    initial begin 
`ifdef DUMPVARS
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_stb_gen);
`endif
    end

    always #(`CLK_T/2) clk_i = ~clk_i;

endmodule