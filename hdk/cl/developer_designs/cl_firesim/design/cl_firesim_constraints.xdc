
create_generated_clock -name target_clock0 -source [get_pins WRAPPER_INST/CL/firesim_clocking/inst/mmcme4_adv_inst/CLKOUT0]  [get_pins [get_cells -hierarchical *_clocks_0_buffer]/O] -divide_by 1
set_multicycle_path 2 -setup -from [get_clocks target_clock0] -to [get_clocks target_clock0]
set_multicycle_path 1 -hold  -from [get_clocks target_clock0] -to [get_clocks target_clock0]

create_generated_clock -name target_clock1 -source [get_pins WRAPPER_INST/CL/firesim_clocking/inst/mmcme4_adv_inst/CLKOUT0]  [get_pins [get_cells -hierarchical *_clocks_1_buffer]/O] -divide_by 1
#set_multicycle_path 2 -setup -from [get_clocks target_clock1] -to [get_clocks target_clock1]
#set_multicycle_path 1 -hold  -from [get_clocks target_clock1] -to [get_clocks target_clock1]

create_generated_clock -name target_clock2 -source [get_pins WRAPPER_INST/CL/firesim_clocking/inst/mmcme4_adv_inst/CLKOUT0]  [get_pins [get_cells -hierarchical *_clocks_2_buffer]/O] -divide_by 1
set_multicycle_path 2 -setup -from [get_clocks target_clock2] -to [get_clocks target_clock2]
set_multicycle_path 1 -hold  -from [get_clocks target_clock2] -to [get_clocks target_clock2]
