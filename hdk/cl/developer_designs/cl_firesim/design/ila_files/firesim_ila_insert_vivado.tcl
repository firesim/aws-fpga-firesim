create_project managed_ip_project $CL_DIR/ip/firesim_ila_ip/managed_ip_project -part xcvu9p-flgb2104-2-i -ip
set_property simulator_language Verilog [current_project]
set_property target_simulator XSim [current_project]
create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_firesim_0 -dir $CL_DIR/ip/firesim_ila_ip
set_property -dict [list CONFIG.C_PROBE0_WIDTH {1} CONFIG.C_PROBE0_MU_CNT {3} CONFIG.C_NUM_OF_PROBES {1} CONFIG.C_TRIGOUT_EN {false} CONFIG.C_EN_STRG_QUAL {1} CONFIG.C_ADV_TRIGGER {true} CONFIG.C_TRIGIN_EN {false} CONFIG.ALL_PROBE_SAME_MU_CNT {3} ] [get_ips ila_firesim_0]
generate_target {instantiation_template} [get_files $CL_DIR/ip/firesim_ila_ip/ila_firesim_0/ila_firesim_0.xci]
generate_target all [get_files  $CL_DIR/ip/firesim_ila_ip/ila_firesim_0/ila_firesim_0.xci]
export_ip_user_files -of_objects [get_files $CL_DIR/ip/firesim_ila_ip/ila_0/ila_firesim_0.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $CL_DIR/ip/firesim_ila_ip/ila_firesim_0/ila_firesim_0.xci]
launch_runs -jobs 8 ila_firesim_0_synth_1
wait_on_run ila_firesim_0_synth_1
export_simulation -of_objects [get_files $CL_DIR/ip/firesim_ila_ip/ila_firesim_0/ila_firesim_0.xci] -directory $CL_DIR/ip/firesim_ila_ip/ip_user_files/sim_scripts -ip_user_files_dir $CL_DIR/ip/firesim_ila_ip/ip_user_files -ipstatic_source_dir $CL_DIR/ip/firesim_ila_ip/ip_user_files/ipstatic -lib_map_path [list {modelsim=$CL_DIR/ip/firesim_ila_ip/managed_ip_project/managed_ip_project.cache/compile_simlib/modelsim} {questa=$CL_DIR/ip/firesim_ila_ip/managed_ip_project/managed_ip_project.cache/compile_simlib/questa} {ies=$CL_DIR/ip/firesim_ila_ip/managed_ip_project/managed_ip_project.cache/compile_simlib/ies} {vcs=$CL_DIR/ip/firesim_ila_ip/managed_ip_project/managed_ip_project.cache/compile_simlib/vcs} {riviera=$CL_DIR/ip/firesim_ila_ip/managed_ip_project/managed_ip_project.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet
