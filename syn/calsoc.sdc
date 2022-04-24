//Copyright (C)2014-2022 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8 
//Created Time: 2022-04-24 17:01:28
create_clock -name clk -period 83.333 -waveform {0 41.666} [get_ports {clk_i}]
report_max_frequency -mod_ins {pico}
