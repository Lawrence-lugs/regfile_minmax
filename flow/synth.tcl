# =============================================================================
# synth.tcl — Yosys synthesis script targeting IHP SG13G2 standard cells.
#
# Invocation: yosys -c wrapper.tcl
#   where wrapper.tcl sets the variables below, then sources this file.
#   run_sweep.py generates the wrapper automatically.
#
# Required Tcl variables (set by wrapper before sourcing):
#   TOP        — top module name
#   RTL_FILES  — Tcl list of RTL .sv files to read
#   LIBERTY    — path to the liberty (.lib) file
#   REPORT_DIR — output directory for reports (will be created if absent)
#
# Optional parameter overrides (omit to keep module defaults):
#   P_NUM_RD_PORTS, P_NUM_WR_PORTS, P_BITWIDTH, P_NUM_REGS, P_NUM_BANKS
# =============================================================================

# --- Defaults (fallback when sourced without a wrapper) ----------------------
if {![info exists TOP]}        { set TOP        "regfile"            }
if {![info exists LIBERTY]}    { set LIBERTY    $::env(LIBERTY_FILE) }
if {![info exists REPORT_DIR]} { set REPORT_DIR "results"            }

# --- Read Design -------------------------------------------------------------
# In yosys -c (Tcl) mode every yosys pass is invoked as: yosys <pass> <args>
foreach f $RTL_FILES {
    yosys read_verilog -sv $f
}

# --- Parameter Overrides (must come before hierarchy) ------------------------
if {[info exists P_NUM_RD_PORTS]} { yosys chparam -set NUM_RD_PORTS $P_NUM_RD_PORTS $TOP }
if {[info exists P_NUM_WR_PORTS]} { yosys chparam -set NUM_WR_PORTS $P_NUM_WR_PORTS $TOP }
if {[info exists P_BITWIDTH]}     { yosys chparam -set BITWIDTH     $P_BITWIDTH     $TOP }
if {[info exists P_NUM_REGS]}     { yosys chparam -set NUM_REGS     $P_NUM_REGS     $TOP }
if {[info exists P_NUM_BANKS]}    { yosys chparam -set NUM_BANKS    $P_NUM_BANKS    $TOP }

# --- Elaboration & Generic Synthesis -----------------------------------------
yosys hierarchy -check -top $TOP
yosys proc
yosys flatten
yosys opt -full
yosys memory -nomap
yosys opt -full

# --- Technology Mapping ------------------------------------------------------
yosys techmap
yosys opt -full
yosys dfflibmap -liberty $LIBERTY
yosys abc       -liberty $LIBERTY
yosys opt_clean -purge

# --- Reports -----------------------------------------------------------------
file mkdir $REPORT_DIR
yosys tee -o ${REPORT_DIR}/stat.rpt  stat -liberty $LIBERTY
yosys write_verilog -noattr ${REPORT_DIR}/netlist.v
