module db (
    input 	wire			clk,
	output	wire [31:0]  	gpioa_o,

	input 	wire 			uart1_rx,
	output 	wire 			uart1_tx

);

	calsoc cal (.*);
	
	logic rst;
	
	issp u0 (
		.source     ({rst}),     //    sources.source
		.source_clk (clk)  // source_clk.clk
	);
	
	
	
endmodule
