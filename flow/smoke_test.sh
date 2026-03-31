#!/bin/bash
# Smoke test: synthesise one 2R1W 32-bit 32-register regfile using yosys -c (Tcl mode)
set -e

LIBERTY=/foss/pdks/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p20V_25C.lib
mkdir -p results/smoke

# Generate a per-run Tcl wrapper (same pattern as run_sweep.py)
cat > /tmp/smoke_run.tcl << TCLEOF
set TOP        regfile
set RTL_FILES  {rtl/regfile.sv}
set LIBERTY    $LIBERTY
set REPORT_DIR results/smoke
set P_NUM_RD_PORTS 2
set P_NUM_WR_PORTS 1
set P_BITWIDTH  32
set P_NUM_REGS  32
source flow/synth.tcl
TCLEOF

echo "=== Running yosys synthesis ==="
yosys -c /tmp/smoke_run.tcl

echo ""
echo "=== stat.rpt ==="
cat results/smoke/stat.rpt