
`timescale 1ns/1ns

`include "sc_fifo.sv"

module tb_sc_fifo();

    localparam WIDTH = 8;

    logic     clk_i = 0;
    logic     arstn_i = 1;

    logic [WIDTH-1:0] data_i = 0;
    logic             wre_i = 0;

    logic [WIDTH-1:0] data_o;
    logic             re_i = 0;
    logic             n_empty_o;

    sc_fifo #(
        .LGFLEN (3),
        .WIDTH  (WIDTH)
    ) dut ( .* );

    initial #100 $finish;

    always #2 clk_i = ~clk_i;
    

    initial begin
        #1 arstn_i = 0;
        #1 arstn_i = 1;
    end

    initial begin
        repeat (2) @(posedge clk_i);
        wre_i <= 1;
        repeat (4) begin
            @(posedge clk_i);
            data_i <= data_i + 1;
        end
        @(posedge clk_i);
        wre_i <= 0;
        data_i <= 0;
        @(posedge clk_i);
        re_i <= 1;
    end

    initial begin 
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_sc_fifo);
    end

endmodule