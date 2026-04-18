
# Lawrence Quizon <lawrence.quizon@eee.upd.edu.ph>

set top_design "regfile_banked"


source flow/pnr/init_tech.tcl
read_verilog results/banking/NUM_RD_PORTS4_NUM_WR_PORTS1_BITWIDTH32_NUM_REGS32_NUM_BANKS4/netlist.v

link_design $top_design

read_sdc flow/pnr/constraints.sdc

# Set power net names
source flow/pnr/power_connect.tcl

# Global size
initialize_floorplan -utilization 80 -core_space 10 -site "CoreSite"

# Tracks
make_tracks
set siteHeight        [ord::dbu_to_microns [[dpl::get_row_site] getHeight]]

# No Macro placement for now

# Place pins (in lieu of a padring for now)
place_pins -hor_layers Metal1 -ver_layers Metal2


# Clock nets
# If repair_timing inserts buffers, it will be troublesome if they add it to the clock nets due to CTS doing the same thing.
set_dont_use $dont_use_cells
set clock_nets [get_nets -of_objects [get_pins -of_objects "*_reg" -filter "name == CLK"]]
set_dont_touch $clock_nets

remove_buffers
repair_design -verbose

# Global placement frfr
set_thread_count 8
global_placement -density 0.60