`define DEFINE_WB_SLAVE_WIRE(prefix)\
logic [31:0]	``prefix``_wb_adr_i;\
logic [31:0]	``prefix``_wb_dat_i;\
logic [31:0]	``prefix``_wb_dat_o;\
logic			``prefix``_wb_we_i;\
logic [3:0] 	``prefix``_wb_sel_i;\
logic 			``prefix``_wb_stb_i;\
logic 			``prefix``_wb_ack_o;\
logic 			``prefix``_wb_cyc_i;\
logic			``prefix``_wb_err_o;\
logic			``prefix``_wb_stall_o;

`define bootloader_path "../bootloader/bootloader.hex"
`define RAM_WB_MEM_SIZE 'h100

module calsoc_top (
	input 	logic			clk_p_i,
	input	logic 			clk_n_i,
	input	logic			rst_i,
	input 	logic			node_clk_i,

	input 	logic 			uart1_rx,
	output 	logic 			uart1_tx,

	output	logic			debug_uart_tx,
//DAC
	output 	logic			dac1_sync_o, dac2_sync_o,
	output	logic			dac1_sclk_o, dac2_sclk_o,
	output	logic			dac1_sdi_o, dac2_sdi_o,
//Delay Line
	output logic [9:0] delay1_code_o, delay2_code_p_o,
	output logic 	   delay1_stb_p_o, delay2_stb_p_o,
	output logic 	   delay1_stb_n_o, delay2_stb_n_o,
//CMP
	input logic cmp1_out_p_i,
	input logic cmp1_out_n_i,

	input logic cmp2_out_p_1,
	input logic cmp2_out_n_1,
	output logic debug_led
);
////////////////////////////
// CLOCK
////////////////////////////
	logic wb_rst_i;
	logic wb_clk_i;
	logic hclk;

	assign wb_rst_i = rst_i;
	assign debug_led = 0;

	TLVDS_IBUF hclk_lvds_IBUF_inst (
		.I	(clk_p_i),
		.IB	(clk_n_i),
		.O	(hclk)
	);

	// assign hclk = node_clk_i;

	Gowin_rPLL hclk_rPLL_inst (
		.clkout(wb_clk_i), //output clkout
		.clkin(hclk) //input clkin
	);

////////////////////////////
	logic cmp1_out;
	logic cmp2_out;

	TLVDS_IBUF cmp1_out_lvds_IBUF_inst (
		.I	(cmp1_out_p_i),
		.IB	(cmp1_out_n_i),
		.O	(cmp1_out)
	);

	// TLVDS_IBUF cmp2_out_lvds_IBUF_inst (
	// 	.I	(cmp2_out_p_i),
	// 	.IB	(cmp2_out_n_i),
	// 	.O	(cmp2_out)
	// );


////////////////////////////
// DELAY LINE
////////////////////////////

	logic delay1_stb, delay2_stb;

	TLVDS_OBUF delay1_stb_lvds_OBUF_inst (
		.O	(delay1_stb_p_o),
		.OB	(delay1_stb_n_o),
		.I	(delay1_stb)
	);

	// TLVDS_OBUF delay2_stb_lvds_OBUF_inst (
	// 	.O	(delay2_stb_p_o),
	// 	.OB	(delay2_stb_n_o),
	// 	.I	(delay2_stb)
	// );


////////////////////////////////////////
	//picorv32_wb wb
	logic [31:0] 	wbm_adr_o;
	logic [31:0] 	wbm_dat_o;
	logic [31:0] 	wbm_dat_i;
	logic 			wbm_we_o;
	logic [3:0]		wbm_sel_o;
	logic			wbm_stb_o;
	logic			wbm_ack_i;
	logic			wbm_cyc_o;
	logic			wbm_stall_i, wbm_err_i;

	// ram inputs/outputs
	`DEFINE_WB_SLAVE_WIRE(ram)
	// GPIOA wb
	`DEFINE_WB_SLAVE_WIRE(gpioa)
	// uart1 wb
	`DEFINE_WB_SLAVE_WIRE(uart1)
	// bootloader ROM
	`DEFINE_WB_SLAVE_WIRE(bootrom)
	// temporary program memory (in RAM)
	`DEFINE_WB_SLAVE_WIRE(prg_ram)
	// measure unit wb
	`DEFINE_WB_SLAVE_WIRE(mu)
		
	wbxbar #(
		.NM			(1),
		.NS			(6),
		.SLAVE_ADDR	({32'h01000000, 32'h00000000, 32'h02000000, 32'h03000000, 32'h04000000, 32'h05000000}), 
		.SLAVE_MASK	({32'hff000000, 32'hff000000, 32'hffffffC0, 32'hfffffff0, 32'hff000000, 32'hff000000})
	) wbbus (
		.i_clk		(wb_clk_i),
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

		.o_scyc		({bootrom_wb_cyc_i,   ram_wb_cyc_i,   gpioa_wb_cyc_i,   uart1_wb_cyc_i,   prg_ram_wb_cyc_i,   mu_wb_cyc_i}),
		.o_sstb		({bootrom_wb_stb_i,   ram_wb_stb_i,   gpioa_wb_stb_i,   uart1_wb_stb_i,   prg_ram_wb_stb_i,   mu_wb_stb_i}),
		.o_swe		({bootrom_wb_we_i,    ram_wb_we_i,    gpioa_wb_we_i,    uart1_wb_we_i,    prg_ram_wb_we_i,    mu_wb_we_i}),
		.o_saddr	({bootrom_wb_adr_i,   ram_wb_adr_i,   gpioa_wb_adr_i,   uart1_wb_adr_i,   prg_ram_wb_adr_i,   mu_wb_adr_i}),
		.o_sdata	({bootrom_wb_dat_i,   ram_wb_dat_i,   gpioa_wb_dat_i,   uart1_wb_dat_i,   prg_ram_wb_dat_i,   mu_wb_dat_i}),
		.o_ssel		({bootrom_wb_sel_i,   ram_wb_sel_i,   gpioa_wb_sel_i,   uart1_wb_sel_i,   prg_ram_wb_sel_i,   mu_wb_sel_i}),
		.i_sack		({bootrom_wb_ack_o,   ram_wb_ack_o,   gpioa_wb_ack_o,   uart1_wb_ack_o,   prg_ram_wb_ack_o,   mu_wb_ack_o}),
		.i_sdata	({bootrom_wb_dat_o,   ram_wb_dat_o,   gpioa_wb_dat_o,   uart1_wb_dat_o,   prg_ram_wb_dat_o,   mu_wb_dat_o}),
		.i_serr		({bootrom_wb_err_o,   ram_wb_err_o,   gpioa_wb_err_o,   uart1_wb_err_o,   prg_ram_wb_err_o,   mu_wb_err_o}),
		.i_sstall	({bootrom_wb_stall_o, ram_wb_stall_o, gpioa_wb_stall_o, uart1_wb_stall_o, prg_ram_wb_stall_o, mu_wb_stall_o})
	);

	measure_unit #(
		.DAC_SPI_CLK_DIV(10),
		.DAC_SPI_WAIT_CYCLES(3),
		.STROBE_ZERO_HOLD_CYCLES(3),
		.DEFAULT_DELAY_CODE_DELTA(10'h1),
		.DEFAULT_THRESHOLD_DELTA(16'h1)
	) measure_unit_inst (
		.hclk_i			(hclk),
		.wb_clk_i 		(wb_clk_i),
		.wb_rst_i		(wb_rst_i),			
		.wb_dat_i		(mu_wb_dat_i),
		.wb_dat_o		(mu_wb_dat_o),
	 	.wb_adr_i		(mu_wb_adr_i),
		.wb_we_i		(mu_wb_we_i),
		.wb_sel_i		(mu_wb_sel_i),
		.wb_cyc_i		(mu_wb_cyc_i),
		.wb_stb_i		(mu_wb_stb_i),
		.wb_ack_o		(mu_wb_ack_o),
		.dac1_sync_o	(dac1_sync_o),
		.dac2_sync_o	(dac2_sync_o),
		.dac1_sclk_o	(dac1_sclk_o),
		.dac2_sclk_o	(dac2_sclk_o),
		.dac1_sdi_o		(dac1_sdi_o),
		.dac2_sdi_o		(dac2_sdi_o),
		.delay1_code_o	(delay1_code_o),
		.delay2_code_o	(delay2_code_o),
		.delay1_stb_o	(delay1_stb),
		.delay2_stb_o	(delay2_stb),
		.cmp1_out_i		(cmp1_out), //(cmp1_out_i),
		.cmp2_out_i		(cmp2_out_i)
	);
	
	gpio_top gpioa (
		.wb_clk_i	(wb_clk_i),
		.wb_rst_i	(wb_rst_i),
		.wb_cyc_i	(gpioa_wb_cyc_i),
		.wb_adr_i	(gpioa_wb_adr_i[5:0]),
		.wb_dat_i	(gpioa_wb_dat_i),
		.wb_sel_i	(gpioa_wb_sel_i), 
		.wb_we_i	(gpioa_wb_we_i),
		.wb_stb_i	(gpioa_wb_stb_i),
		.wb_dat_o	(gpioa_wb_dat_o), 
		.wb_ack_o	(gpioa_wb_ack_o),
		.ext_pad_o	()
	);
	
	wb_ram #(
		.WORD_COUNT(`RAM_WB_MEM_SIZE)
	) ram (
		.clk_i		(wb_clk_i),
		.rst_i		(wb_rst_i),
		.wb_cyc_i	(ram_wb_cyc_i),
		.wb_adr_i	(ram_wb_adr_i),
		.wb_dat_i	(ram_wb_dat_i),
		.wb_sel_i	(ram_wb_sel_i), 
		.wb_we_i	(ram_wb_we_i),
		.wb_stb_i	(ram_wb_stb_i),
		.wb_dat_o	(ram_wb_dat_o), 
		.wb_ack_o	(ram_wb_ack_o)
	);

	wb_ram #(
		.WORD_COUNT('h1000)
	) prg_ram (
		.clk_i		(wb_clk_i),
		.rst_i		(wb_rst_i),
		.wb_cyc_i	(prg_ram_wb_cyc_i),
		.wb_adr_i	(prg_ram_wb_adr_i),
		.wb_dat_i	(prg_ram_wb_dat_i),
		.wb_sel_i	(prg_ram_wb_sel_i), 
		.wb_we_i	(prg_ram_wb_we_i),
		.wb_stb_i	(prg_ram_wb_stb_i),
		.wb_dat_o	(prg_ram_wb_dat_o), 
		.wb_ack_o	(prg_ram_wb_ack_o)
	);

	logic tmp_uart;

	assign debug_uart_tx = tmp_uart;
	assign uart1_tx = tmp_uart;

	wbuart #(
		.LGFLEN('ha)
	) uart1 (
		.i_clk		(wb_clk_i),
		.i_rst		(wb_rst_i),
		.i_wb_cyc	(uart1_wb_cyc_i),
		.i_wb_addr	(uart1_wb_adr_i[5:2]), // костыль из-за того, что у юарта адреса не выровнены по 4 байтам
		.i_wb_data	(uart1_wb_dat_i),
		.i_wb_we	(uart1_wb_we_i),
		.i_wb_stb	(uart1_wb_stb_i),
		.o_wb_data	(uart1_wb_dat_o), 
		.o_wb_ack	(uart1_wb_ack_o),
		.i_uart_rx	(uart1_rx),
		.o_uart_tx	(tmp_uart),
		.o_wb_stall	(uart1_wb_stall_o)
	);

	wb_rom #(
		.mem_init_file(`bootloader_path),
		.word_count('h400)
	) bootloader_rom (
		.clk_i		(wb_clk_i),
		.rst_i		(wb_rst_i),
		.wb_cyc_i	(bootrom_wb_cyc_i),
		.wb_adr_i	(bootrom_wb_adr_i),
		.wb_dat_i	(bootrom_wb_dat_i),
		.wb_sel_i	(bootrom_wb_sel_i), 
		.wb_we_i	(bootrom_wb_we_i),
		.wb_stb_i	(bootrom_wb_stb_i),
		.wb_dat_o	(bootrom_wb_dat_o), 
		.wb_ack_o	(bootrom_wb_ack_o)
	);


	logic        	pcpi_valid;
	logic [31:0] 	pcpi_insn;
	logic [31:0] 	pcpi_rs1;
	logic [31:0] 	pcpi_rs2;
	logic         	pcpi_wr;
	logic [31:0] 	pcpi_rd;
	logic        	pcpi_wait;
	logic         	pcpi_ready;
	logic [31:0] 	irq;
	logic [31:0]  	eoi;
	logic 			trap;
	logic        	trace_valid;
	logic [35:0] 	trace_data;
	logic 			mem_instr;

	
	picorv32_wb #(
		.PROGADDR_RESET	('h01000000),
		.STACKADDR		(`RAM_WB_MEM_SIZE*4),
		.ENABLE_MUL		(1),
		.ENABLE_DIV 	(1)
	) pico (
		.*
	);
	 
endmodule
