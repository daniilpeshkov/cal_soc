//Copyright (C)2014-2022 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8 
//Created Time: 2022-07-29 12:07:22
create_clock -name hclk -period 8 -waveform {0 4} [get_nets {hclk}]
create_clock -name ext_hclk -period 8 -waveform {0 4} [get_ports {node_clk_i}]
create_generated_clock -name core_clk -source [get_nets {hclk}] -master_clock hclk -divide_by 5 [get_nets {wb_clk_i}]
set_clock_groups -asynchronous -group [get_clocks {hclk ext_hclk}] -group [get_clocks {core_clk}]
set_input_delay -clock hclk 0 -add_delay [get_ports {delay1_stb_p_o delay2_stb_p_o delay1_stb_n_o delay2_stb_n_o}]
report_timing -setup -from_clock [get_clocks {hclk}] -to [get_ports {delay1_stb_p_o}] -max_paths 25 -max_common_paths 1
report_max_frequency -mod_ins {pico}
