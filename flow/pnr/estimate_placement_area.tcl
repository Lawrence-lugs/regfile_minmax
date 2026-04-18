
# Lawrence Quizon <lawrence.quizon@eee.upd.edu.ph>
# Parameterized PnR placement area estimation — single utilization attempt.
#
# Required Tcl variables (set by wrapper before sourcing):
#   TOP         — top module name
#   NETLIST_V   — path to the synthesised netlist .v
#   REPORT_DIR  — output directory for reports
#   UTIL        — core utilization percentage (e.g. 60)
#
# Optional:
#   PNR_DENSITY — global placement density (default 0.60)
#
# Exits 0 on success, 1 on placement/routing failure.
# Use sweep_utilization.py to sweep utilization values.

if {![info exists TOP]}         { set TOP         ""     }
if {![info exists NETLIST_V]}   { set NETLIST_V   "" }
if {![info exists REPORT_DIR]}  { set REPORT_DIR  "reports"     }
if {![info exists UTIL]}        { set UTIL         60           }
if {![info exists PNR_DENSITY]} { set PNR_DENSITY  0.60         }

source flow/pnr/init_tech.tcl
read_verilog $NETLIST_V

link_design $TOP

read_sdc flow/pnr/constraints.sdc

# Set power net names
source flow/pnr/power_connect.tcl

puts "=================================================="
puts "Testing Core Utilization: $UTIL%"
puts "=================================================="

# 1. Initialize Floorplan
initialize_floorplan -utilization $UTIL -aspect_ratio 1.0 -core_space 0.0 -site "CoreSite"

make_tracks

# Place pins (required before placement)
place_pins -hor_layer Metal3 -ver_layer Metal4

# 2. Global Placement with Routability Driven active
if {[catch {global_placement -routability_driven} gp_err]} {
    puts "Utilization $UTIL% failed during global placement density convergence."
    puts "Error: $gp_err"
    exit 1
}

# 3. Fast Global Routing
if {[catch {global_route -congestion_iterations 5} gr_err]} {
    puts "Utilization $UTIL% failed during global routing congestion."
    puts "Error: $gr_err"
    exit 1
}

# 4. Reports
set report_dir $REPORT_DIR
file mkdir $report_dir
source flow/pnr/reports.tcl
report_metrics "gpl-pnr"

exit