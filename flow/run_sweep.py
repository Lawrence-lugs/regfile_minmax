#!/usr/bin/env python3
"""
run_sweep.py — Sweep register-file parameters through Yosys synthesis
               targeting IHP SG13G2 and collect area results.

Usage (from the repo root inside the Docker container):
    python flow/run_sweep.py [--sweep all|port|bitwidth|regcount|banking]
                             [--jobs N]

Outputs:
    results/summary.csv        — all runs, one row per configuration
    results/<run_id>/stat.rpt  — per-run Yosys stat report
    results/<run_id>/netlist.v — synthesized netlist
"""

from __future__ import annotations

import argparse
import itertools
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pandas as pd
from tqdm import tqdm

sys.path.insert(0, str(Path(__file__).parent))
from parse_reports import parse_report_file

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

YOSYS_CMD   = os.environ.get("YOSYS_CMD", "yosys")
TCL_SCRIPT  = Path(__file__).parent / "synth.tcl"
LIBERTY     = os.environ.get(
    "LIBERTY_FILE",
    "/foss/pdks/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/"
    "sg13g2_stdcell_typ_1p20V_25C.lib",
)
RESULTS_DIR = Path("results")
RTL_DIR     = Path("rtl")

# ---------------------------------------------------------------------------
# Sweep definitions
# ---------------------------------------------------------------------------
# Each sweep is a dict with:
#   rtl_files : list of RTL files to read (relative to repo root)
#   top       : top module name
#   params    : dict of param_name -> list of values to sweep
#               All combinations are enumerated (grid search).
#   filter    : optional callable(cfg) -> bool to skip invalid combos

SWEEPS: dict[str, dict] = {

    # ---- 1. Port sweep (area vs read/write ports) --------------------------
    # Core claim from the paper: area ~ O(N · P²) where P = Nr + Nw
    "port": {
        "rtl_files": [RTL_DIR / "regfile.sv"],
        "top":       "regfile",
        "params": {
            "NUM_RD_PORTS": [1, 2, 3, 4, 6, 8],
            "NUM_WR_PORTS": [1, 2, 3],
            "BITWIDTH":     [32],
            "NUM_REGS":     [32],
        },
    },

    # ---- 2. Bit-width sweep ------------------------------------------------
    # Area should scale linearly with BITWIDTH (each extra bit = one extra FF).
    "bitwidth": {
        "rtl_files": [RTL_DIR / "regfile.sv"],
        "top":       "regfile",
        "params": {
            "NUM_RD_PORTS": [2],
            "NUM_WR_PORTS": [1],
            "BITWIDTH":     [4, 8, 16, 32, 64],
            "NUM_REGS":     [32],
        },
    },

    # ---- 3. Register count sweep ------------------------------------------
    # Area should grow as O(N · log N) from mux depth, or near-linear.
    "regcount": {
        "rtl_files": [RTL_DIR / "regfile.sv"],
        "top":       "regfile",
        "params": {
            "NUM_RD_PORTS": [2],
            "NUM_WR_PORTS": [1],
            "BITWIDTH":     [32],
            "NUM_REGS":     [8, 16, 32, 64],
        },
    },

    # ---- 4. Banking sweep --------------------------------------------------
    # Split read ports across NUM_BANKS to reduce per-bank mux size.
    # Constraint: NUM_RD_PORTS % NUM_BANKS == 0.
    "banking": {
        "rtl_files": [RTL_DIR / "regfile.sv", RTL_DIR / "regfile_banked.sv"],
        "top":       "regfile_banked",
        "params": {
            "NUM_RD_PORTS": [4, 8],
            "NUM_WR_PORTS": [1, 2],
            "BITWIDTH":     [32],
            "NUM_REGS":     [32],
            "NUM_BANKS":    [1, 2, 4],
        },
        "filter": lambda cfg: cfg["NUM_RD_PORTS"] % cfg["NUM_BANKS"] == 0,
    },
}

# ---------------------------------------------------------------------------
# Core synthesis runner
# ---------------------------------------------------------------------------

PARAM_MAP = {
    "NUM_RD_PORTS": "P_NUM_RD_PORTS",
    "NUM_WR_PORTS": "P_NUM_WR_PORTS",
    "BITWIDTH":     "P_BITWIDTH",
    "NUM_REGS":     "P_NUM_REGS",
    "NUM_BANKS":    "P_NUM_BANKS",
}


def run_one(
    run_id: str,
    rtl_files: list[Path],
    top: str,
    params: dict[str, int],
) -> dict:
    """Run one Yosys synthesis (or load cached result) and return a metrics dict."""
    out_dir = RESULTS_DIR / run_id
    out_dir.mkdir(parents=True, exist_ok=True)

    stat_rpt = out_dir / "stat.rpt"

    # Skip synthesis if a valid report already exists from a previous run
    if stat_rpt.exists() and stat_rpt.stat().st_size > 0:
        metrics = parse_report_file(stat_rpt)
        return {
            "run_id": run_id, "top": top, "status": "OK",
            **params, **metrics,
        }

    rtl_list = " ".join(str(f) for f in rtl_files)

    # Write a per-run Tcl wrapper that sets variables then sources synth.tcl.
    # Use yosys -c (Tcl mode) so that `set`, `foreach`, `if` etc. are valid Tcl,
    # and all yosys passes (read_verilog, hierarchy, abc, …) are Tcl procs.
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".tcl", delete=False, prefix="regfile_run_"
    ) as tf:
        tf.write(f"set TOP        {top}\n")
        tf.write(f"set RTL_FILES  {{{rtl_list}}}\n")
        tf.write(f"set LIBERTY    {{{LIBERTY}}}\n")
        tf.write(f"set REPORT_DIR {{{out_dir}}}\n")
        for py_key, tcl_key in PARAM_MAP.items():
            if py_key in params:
                tf.write(f"set {tcl_key} {params[py_key]}\n")
        tf.write(f"source {TCL_SCRIPT}\n")
        tmp_tcl = tf.name

    try:
        result = subprocess.run(
            [YOSYS_CMD, "-c", tmp_tcl],
            capture_output=True,
            text=True,
        )
    finally:
        os.unlink(tmp_tcl)

    (out_dir / "yosys.log").write_text(result.stdout + result.stderr)

    if result.returncode != 0:
        print(f"\n[FAIL] {run_id}\n{result.stderr[-2000:]}", file=sys.stderr)
        return {**params, "run_id": run_id, "top": top, "status": "FAIL",
                "chip_area_um2": None, "ff_count": None}

    stat_rpt = out_dir / "stat.rpt"
    metrics = parse_report_file(stat_rpt) if stat_rpt.exists() else {}

    return {
        "run_id":  run_id,
        "top":     top,
        "status":  "OK",
        **params,
        **metrics,
    }


# ---------------------------------------------------------------------------
# Sweep runner
# ---------------------------------------------------------------------------

def run_sweep(sweep_name: str, sweep_def: dict) -> list[dict]:
    """Enumerate all parameter combinations for one sweep and synthesize."""
    param_names  = list(sweep_def["params"].keys())
    param_values = list(sweep_def["params"].values())
    filter_fn    = sweep_def.get("filter", lambda _: True)

    configs = [
        dict(zip(param_names, combo))
        for combo in itertools.product(*param_values)
        if filter_fn(dict(zip(param_names, combo)))
    ]

    rows = []
    for cfg in tqdm(configs, desc=sweep_name, unit="run"):
        parts = "_".join(f"{k}{v}" for k, v in cfg.items())
        run_id = f"{sweep_name}/{parts}"
        row = run_one(
            run_id     = run_id,
            rtl_files  = sweep_def["rtl_files"],
            top        = sweep_def["top"],
            params     = cfg,
        )
        row["sweep"] = sweep_name
        rows.append(row)

    return rows


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Regfile synthesis sweep")
    parser.add_argument(
        "--sweep",
        default="all",
        choices=["all"] + list(SWEEPS.keys()),
        help="Which sweep(s) to run (default: all)",
    )
    args = parser.parse_args()

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)

    # Load any rows from a previous run so we don't lose them
    existing_csv = RESULTS_DIR / "summary.csv"
    prior_rows: list[dict] = []
    if existing_csv.exists():
        prior_df = pd.read_csv(existing_csv)
        prior_rows = prior_df.to_dict("records")
        prior_ids  = {r["run_id"] for r in prior_rows}
    else:
        prior_ids = set()

    selected = list(SWEEPS.keys()) if args.sweep == "all" else [args.sweep]

    all_rows: list[dict] = []
    for name in selected:
        print(f"\n{'='*60}")
        print(f"  Running sweep: {name}")
        print(f"{'='*60}")
        rows = run_sweep(name, SWEEPS[name])
        all_rows.extend(rows)

        # Merge with prior rows (deduplicate by run_id, new wins)
        merged = {r["run_id"]: r for r in prior_rows}
        merged.update({r["run_id"]: r for r in all_rows})
        df = pd.DataFrame(list(merged.values()))
        df.to_csv(RESULTS_DIR / "summary.csv", index=False)
        ok_new = sum(1 for r in rows if r.get("status") == "OK")
        print(f"  → {ok_new} OK this sweep; summary.csv has {len(df)} total rows")

    ok  = sum(1 for r in all_rows if r.get("status") == "OK")
    fail = sum(1 for r in all_rows if r.get("status") == "FAIL")
    print(f"\nDone: {ok} OK, {fail} FAILED — results/summary.csv")


if __name__ == "__main__":
    main()
