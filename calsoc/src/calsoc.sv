`include "ram_wb_defines.v"

`define DEFINE_WB_SLAVE_WIRE(prefix)\
wire [31:0]		``prefix``_wb_adr_i;\
wire [31:0]		``prefix``_wb_dat_i;\
wire [31:0]		``prefix``_wb_dat_o;\
wire			``prefix``_wb_we_i;\
wire [3:0] 		``prefix``_wb_sel_i;\
wire 			``prefix``_wb_stb_i;\
wire 			``prefix``_wb_ack_o;\
wire 			``prefix``_wb_cyc_i;\
wire			``prefix``_wb_err_o;\
wire			``prefix``_wb_stall_o;


module calsoc #(
	parameter PROG_PATH = "../../firmware/test.hex"
) (
    input 	wire			clk,
    input	wire			rst,
	output	wire [31:0]  	gpioa_o,

	input 	wire 			uart1_rx,
	output 	wire 			uart1_tx
);
	wire wb_rst_i;
	assign wb_rst_i = ~rst;
	
	reg [31:0] data [0:'h2000];
	
	//progmem inputs/outputs
	wire [31:0]		flash_wb_adr_i;
	wire [31:0]		flash_wb_dat_i;
	reg  [31:0]		flash_wb_dat_o;
	wire 			flash_wb_we_i;
	wire [3:0] 		flash_wb_sel_i;
	wire 			flash_wb_stb_i;
	reg 			flash_wb_ack_o;
	wire 			flash_wb_cyc_i;
	wire			flash_wb_err_o;
	wire			flash_wb_stall_o;
	
	//picorv32_wb wb
	wire [31:0] 	wbm_adr_o;
	wire [31:0] 	wbm_dat_o;
	wire [31:0] 	wbm_dat_i;
	wire 			wbm_we_o;
	wire [3:0]		wbm_sel_o;
	wire			wbm_stb_o;
	wire			wbm_ack_i;
	wire			wbm_cyc_o;
	wire			wbm_stall_i, wbm_err_i;

	//ram inputs/outputs
	`DEFINE_WB_SLAVE_WIRE(ram)
	//GPIOA	wb
	`DEFINE_WB_SLAVE_WIRE(gpioa)
	//uart1	wb
	`DEFINE_WB_SLAVE_WIRE(uart1)
	
		
	wbxbar #(
		.NM			(1),
		.NS			(4),
		.SLAVE_ADDR	({32'h01000000, 32'h00000000, 32'h02000000, 32'h03000000}), 
		.SLAVE_MASK	({32'hff000000, 32'hff000000, 32'hffffffC0, 32'hfffffff0})
	) wbbus (
		.i_clk		(clk),
		.i_reset	(wb_rst_i),
		.i_mcyc		(wbm_cyc_o),
		.i_mstb		(wbm_stb_o),
		.i_mwe		(wbm_we_o),
		.i_maddr	(wbm_adr_o),
		.i_mdata	(wbm_dat_o),
		.i_msel		(wbm_sel_o),
		.o_mack		(wbm_ack_i),
		.o_mdata	(wbm_dat_i),
		.o_mstall	(wbm_stall_i),

		.o_scyc		({flash_wb_cyc_i, ram_wb_cyc_i, gpioa_wb_cyc_i, uart1_wb_cyc_i}),
		.o_sstb		({flash_wb_stb_i, ram_wb_stb_i, gpioa_wb_stb_i, uart1_wb_stb_i}),
		.o_swe		({flash_wb_we_i,  ram_wb_we_i,  gpioa_wb_we_i,	uart1_wb_we_i}),
		.o_saddr	({flash_wb_adr_i, ram_wb_adr_i, gpioa_wb_adr_i, uart1_wb_adr_i}),
		.o_sdata	({flash_wb_dat_i, ram_wb_dat_i, gpioa_wb_dat_i, uart1_wb_dat_i}),
		.o_ssel		({flash_wb_sel_i, ram_wb_sel_i, gpioa_wb_sel_i, uart1_wb_sel_i}),
		.i_sack		({flash_wb_ack_o, ram_wb_ack_o, gpioa_wb_ack_o, uart1_wb_ack_o}),
		.i_sdata	({flash_wb_dat_o, ram_wb_dat_o, gpioa_wb_dat_o, uart1_wb_dat_o}),
		.i_serr		({flash_wb_err_o, ram_wb_err_o, gpioa_wb_err_o, uart1_wb_err_o}),
		.i_sstall	({flash_wb_stall_o, ram_wb_stall_o, gpioa_wb_stall_o, uart1_wb_stall_o})
	);
	
	
	gpio_top gpioa (
		.wb_clk_i	(clk),
		.wb_rst_i	(wb_rst_i),
		.wb_cyc_i	(gpioa_wb_cyc_i),
		.wb_adr_i	(gpioa_wb_adr_i[5:0]),
		.wb_dat_i	(gpioa_wb_dat_i),
		.wb_sel_i	(gpioa_wb_sel_i), 
		.wb_we_i	(gpioa_wb_we_i),
		.wb_stb_i	(gpioa_wb_stb_i),
		.wb_dat_o	(gpioa_wb_dat_o), 
		.wb_ack_o	(gpioa_wb_ack_o),
		.ext_pad_o	(gpioa_o)
	);
	
	ram_wb ram (
		.clk_i	(clk),
		.rst_i	(wb_rst_i),
		.cyc_i	(ram_wb_cyc_i),
		.adr_i	(ram_wb_adr_i),
		.dat_i	(ram_wb_dat_i),
		.sel_i	(ram_wb_sel_i), 
		.we_i	(ram_wb_we_i),
		.stb_i	(ram_wb_stb_i),
		.dat_o	(ram_wb_dat_o), 
		.ack_o	(ram_wb_ack_o)
	);

	wbuart uart1 (
		.i_clk		(clk),
		.i_rst		(wb_rst_i),
		.i_wb_cyc	(uart1_wb_cyc_i),
		.i_wb_addr	(uart1_wb_adr_i[5:2]), // костыль из-за того, что у юарта адреса не выровнены по 4 байтам
		.i_wb_data	(uart1_wb_dat_i),
		.i_wb_we	(uart1_wb_we_i),
		.i_wb_stb	(uart1_wb_stb_i),
		.o_wb_data	(uart1_wb_dat_o), 
		.o_wb_ack	(uart1_wb_ack_o),
		.i_uart_rx	(uart1_rx),
		.o_uart_tx	(uart1_tx),
		.o_wb_stall	(uart1_wb_stall_o)
	);
	defparam uart1.LGFLEN = 'ha;
//********************************************
//					will be moved to external flash
	initial
		$readmemh(PROG_PATH, data);
	
	wire [31:0]	addr;
	assign addr = {8'h0, flash_wb_adr_i[23:0]};
	
	always @(posedge clk) begin
		if (flash_wb_stb_i == 1 && flash_wb_we_i== 0) begin
			flash_wb_dat_o <= data[addr>>2];
			flash_wb_ack_o <= 1;
		end else if (flash_wb_cyc_i == 0) begin 
			flash_wb_dat_o  <= 0;
			flash_wb_ack_o  <= 0;
		end
	end

//********************************************
	reg        		pcpi_valid;
	reg [31:0] 		pcpi_insn;
	reg [31:0] 		pcpi_rs1;
	reg [31:0] 		pcpi_rs2;
	reg         	pcpi_wr;
	reg [31:0] 		pcpi_rd;
	reg        		pcpi_wait;
	reg         	pcpi_ready;
	reg [31:0] 		irq;
	reg [31:0]  	eoi;
	reg 			trap;
	reg        		trace_valid;
	reg [35:0] 		trace_data;
	reg 			mem_instr;

	wire wb_clk_i;
	assign wb_clk_i = clk;	
	
	picorv32_wb #(
		.PROGADDR_RESET	('h01000000),
		.STACKADDR		(`RAM_WB_MEM_SIZE),
		.ENABLE_MUL		(1),
		.ENABLE_DIV 	(1)
	) pico (.*);
	 
	 
endmodule
