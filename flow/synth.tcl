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
if {![info exists SDC_FILE]}   { set SDC_FILE   [file join [file dirname [info script]] "abc_files" "constraints.sdc"] }
if {![info exists PERIOD_PS]}  { set PERIOD_PS  10000                }

# Process an ABC script into REPORT_DIR and patch paths for this repository.
proc processAbcScript {abc_script report_dir} {
    file mkdir $report_dir
    set abc_out_path [file join $report_dir [file tail $abc_script]]
    set raw [read -nonewline [open $abc_script r]]

    # Croc-style placeholder and local path rewrite for LMS AIG library.
    set lms_aig [file join [file dirname [info script]] "abc_files" "lazy_man_synth_library.aig"]
    set processed [string map [list "{REC_AIG}" $lms_aig "src/lazy_man_synth_library.aig" $lms_aig] $raw]

    set abc_out [open $abc_out_path w]
    puts -nonewline $abc_out $processed
    flush $abc_out
    close $abc_out
    return $abc_out_path
}

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
# Run opt after every major step
yosys flatten
yosys opt -full 
yosys memory -nomap
yosys opt -full

# --- Technology Mapping ------------------------------------------------------
yosys techmap
yosys opt -full
yosys dfflibmap -liberty $LIBERTY
yosys clean -purge
yosys opt_clean -purge


# --- ABC Mapping (optional) ------------------------------------------------------
# ABC lazy man synthesis script based off PULP/croc 
set tech_cells_args [list -liberty $LIBERTY]
set dont_use_args [list]
set abc_script_path [file join [file dirname [info script]] "abc_files" "abc-opt.script"]
set abc_comb_script [processAbcScript $abc_script_path $REPORT_DIR]
yosys abc {*}$tech_cells_args -D $PERIOD_PS -script $abc_comb_script -constr $SDC_FILE {*}$dont_use_args -showtmp
yosys clean -purge


# --- Reports -----------------------------------------------------------------
file mkdir $REPORT_DIR
yosys tee -o ${REPORT_DIR}/stat.rpt  stat -liberty $LIBERTY
yosys write_verilog -noattr ${REPORT_DIR}/netlist.v
