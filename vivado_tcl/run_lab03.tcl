# Run from Vivado Tcl Console after opening a fresh RTL project.
set root [file normalize [file join [file dirname [info script]] ..]]
add_files -fileset sources_1 [file join $root lab03_jtag_tap rtl jtag_tap_demo.v]
add_files -fileset sim_1 [file join $root lab03_jtag_tap tb tb_jtag_tap_demo.v]
set_property top jtag_tap_demo [get_filesets sources_1]
set_property top tb_jtag_tap_demo [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
launch_simulation
run all
