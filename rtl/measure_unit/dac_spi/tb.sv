`timescale 1ns/100ps

module tb();
    localparam DATA_WIDTH = 8;

	logic clk_i = 0;
	logic arst_i = 0;
	logic [DATA_WIDTH-1:0] data_i = 8'haa;
	logic wre_i = 0;
	logic rdy;
	logic mosi;
	logic sclk;
	logic sync;

    spi_master_o #(.DATA_WIDTH(DATA_WIDTH), .WAIT_CYCLES(5)) dut (.*);
    initial begin 
        $dumpvars(0, tb);
        #1 arst_i = 1;
        #1 arst_i = 0;
        @(negedge clk_i);
        wre_i = 1;
        @(negedge clk_i);
        wre_i = 0;
        @(posedge rdy);
        #100
        $finish_and_return(1);
    end

    always #10 clk_i = ~clk_i;

endmodule 