`timescale 1ns/100ps

module tb_stb_gen();

    logic clk_i = 0;
    logic comp_out = 0;
    logic arst_i = 0;
    logic stb_o;
    logic freq_det_i = 1;
    logic err_o;
    logic oe_i = 1;

    stb_gen dut(
        .sig_i (comp_out),
        .*
    );

    initial begin 
        $dumpfile("dump.lx2");
        $dumpvars(0, tb_stb_gen);
    end

    always begin 
        #3336 comp_out = 1;
        #121 comp_out = 0;
    end

    always #5 clk_i = ~clk_i;

    initial #50000 $finish;
    initial begin
        #2 arst_i = 1;
        #2 arst_i = 0;
        #10 freq_det_i = 0;
        #30000 oe_i = 0;
        #10000 oe_i = 1;
    end

endmodule