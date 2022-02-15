`timescale 1ns/100ps
module tb();

	logic clk = 0;

	logic [1:0]	uart1_wb_adr_i = 0;
	logic [31:0]	uart1_wb_dat_i = 0;
	logic [31:0]	uart1_wb_dat_o;
	logic			uart1_wb_we_i = 0;
	logic 			uart1_wb_stb_i = 0;
	logic 			uart1_wb_ack_o;
	logic 			uart1_wb_cyc_i = 0;
	logic			uart1_wb_err_o;
	logic			uart1_wb_stall_o;
	logic			wb_rst_i = 1;
	logic 			uart1_rx = 1;
	logic 			uart1_tx;
	logic			i_cts_n = 0;
	logic o_uart_rx_int, o_uart_tx_int, o_uart_rxfifo_int, o_uart_txfifo_int;

	wbuart uart1 (
		.i_clk		(clk),
		.i_rst		(wb_rst_i),
		.i_wb_cyc	(uart1_wb_cyc_i),
		.i_wb_addr	(uart1_wb_adr_i),
		.i_wb_data	(uart1_wb_dat_i),
		.i_wb_we	(uart1_wb_we_i),
		.i_wb_stb	(uart1_wb_stb_i),
		.o_wb_data	(uart1_wb_dat_o), 
		.o_wb_ack	(uart1_wb_ack_o),
		.i_uart_rx	(uart1_rx),
		.o_uart_tx	(uart1_tx),
		.o_wb_stall	(uart1_wb_stall_o),
		.i_cts_n	(i_cts_n),
		.o_uart_rx_int(o_uart_rx_int), 
		.o_uart_tx_int(o_uart_tx_int),
		.o_uart_rxfifo_int(o_uart_rxfifo_int),
		.o_uart_txfifo_int(o_uart_txfifo_int)
	);
	//defparam uart1.LGFLEN = 2;
	
	initial begin
		#40 wb_rst_i = 0;
		#10
		uart1_wb_we_i = 1;
		//write setup register
		uart1_wb_cyc_i = 1;
		uart1_wb_stb_i = 1;
		uart1_wb_adr_i = 0;
		uart1_wb_dat_i = 6;
		@(posedge uart1_wb_ack_o);
		@(posedge clk);
		uart1_wb_cyc_i = 0;
		uart1_wb_stb_i = 0;
		@(posedge clk);
		@(posedge clk);
		//uart1_wb_we_i = 0;
		//send data
		uart1_wb_cyc_i = 1;
		uart1_wb_stb_i = 1;
		uart1_wb_adr_i = 3;
		uart1_wb_dat_i = 'hAB;
		@(posedge uart1_wb_ack_o);
		@(posedge clk);
		uart1_wb_cyc_i = 0;
		uart1_wb_stb_i = 0;
	end


	always
		#10 clk = ~clk;
		


endmodule