# Run from Vivado Tcl Console after opening a fresh RTL project.
set root [file normalize [file join [file dirname [info script]] ..]]
add_files -fileset sources_1 [list \
    [file join $root lab02_scan_atpg rtl scan_dff.v] \
    [file join $root lab02_scan_atpg rtl scan_logic8.v]]
add_files -fileset sim_1 [file join $root lab02_scan_atpg tb tb_scan_logic8.v]
set_property top scan_logic8 [get_filesets sources_1]
set_property top tb_scan_logic8 [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
launch_simulation
run all
