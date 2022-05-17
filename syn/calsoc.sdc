//Copyright (C)2014-2022 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8 
//Created Time: 2022-05-17 18:03:37
create_clock -name h_clk -period 8 -waveform {0 4} [get_nets {hclk}]
report_max_frequency -mod_ins {pico}
