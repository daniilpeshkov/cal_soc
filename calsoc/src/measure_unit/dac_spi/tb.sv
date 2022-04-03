
module tb();
    localparam DATA_WIDTH = 8;

	logic clk_i = 0;
	logic arst_i = 0;
	logic [DATA_WIDTH-1:0] data_i = 'haa;
	logic wre_i = 0;
	logic rdy;
	logic mosi;
	logic sclk;
	logic sync;

    spi_master_o #(.DATA_WIDTH(DATA_WIDTH)) dut (.*);

    initial begin 
        #1 arst_i = 1;
        #1 arst_i = 0;
        @(negedge clk_i);
        wre_i = 1;
        @(negedge clk_i);
        wre_i = 0;
    end

    always #10 clk_i = ~clk_i;

endmodule 