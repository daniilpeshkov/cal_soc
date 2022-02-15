onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/clk
add wave -noupdate /tb/wb_rst_i
add wave -noupdate -radix hexadecimal /tb/uart1_wb_adr_i
add wave -noupdate -radix hexadecimal /tb/uart1_wb_dat_i
add wave -noupdate -radix hexadecimal /tb/uart1_wb_dat_o
add wave -noupdate /tb/uart1_wb_we_i
add wave -noupdate /tb/uart1_wb_stb_i
add wave -noupdate /tb/uart1_wb_ack_o
add wave -noupdate /tb/uart1_wb_cyc_i
add wave -noupdate /tb/uart1_wb_err_o
add wave -noupdate /tb/uart1_wb_stall_o
add wave -noupdate /tb/uart1_rx
add wave -noupdate /tb/uart1_tx
add wave -noupdate -divider tx
add wave -noupdate /tb/uart1/tx/o_uart_tx
add wave -noupdate /tb/uart1/tx/i_cts_n
add wave -noupdate /tb/uart1/tx/i_clk
add wave -noupdate /tb/uart1/tx/i_reset
add wave -noupdate /tb/uart1/tx/i_setup
add wave -noupdate /tb/uart1/tx/i_break
add wave -noupdate /tb/uart1/tx/i_wr
add wave -noupdate -radix hexadecimal /tb/uart1/tx/i_data
add wave -noupdate /tb/uart1/tx/o_busy
add wave -noupdate -divider txfifo
add wave -noupdate /tb/uart1/txfifo/i_clk
add wave -noupdate /tb/uart1/txfifo/i_rst
add wave -noupdate /tb/uart1/txfifo/i_wr
add wave -noupdate /tb/uart1/txfifo/i_data
add wave -noupdate /tb/uart1/txfifo/o_empty_n
add wave -noupdate /tb/uart1/txfifo/i_rd
add wave -noupdate /tb/uart1/txfifo/o_data
add wave -noupdate /tb/uart1/txfifo/o_status
add wave -noupdate /tb/uart1/txfifo/o_err
add wave -noupdate /tb/uart1/txfifo/fifo
add wave -noupdate /tb/uart1/txfifo/r_first
add wave -noupdate /tb/uart1/txfifo/r_last
add wave -noupdate /tb/uart1/txfifo/r_next
add wave -noupdate /tb/uart1/txfifo/w_first_plus_one
add wave -noupdate /tb/uart1/txfifo/w_first_plus_two
add wave -noupdate /tb/uart1/txfifo/w_last_plus_one
add wave -noupdate /tb/uart1/txfifo/will_overflow
add wave -noupdate /tb/uart1/txfifo/r_ovfl
add wave -noupdate /tb/uart1/txfifo/will_underflow
add wave -noupdate /tb/uart1/txfifo/fifo_here
add wave -noupdate /tb/uart1/txfifo/fifo_next
add wave -noupdate /tb/uart1/txfifo/r_data
add wave -noupdate /tb/uart1/txfifo/osrc
add wave -noupdate /tb/uart1/txfifo/r_empty_n
add wave -noupdate /tb/uart1/txfifo/w_full_n
add wave -noupdate /tb/uart1/txfifo/r_fill
add wave -noupdate /tb/uart1/txfifo/lglen
add wave -noupdate /tb/uart1/txfifo/w_half_full
add wave -noupdate /tb/uart1/txfifo/w_fill
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {118 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 186
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {878 ns}
