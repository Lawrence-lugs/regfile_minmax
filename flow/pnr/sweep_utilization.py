#!/usr/bin/env python3
"""
sweep_utilization.py — Sweep core utilization through OpenROAD placement.

Calls estimate_placement_area.tcl once per utilization value, starting
from the highest and stopping on the first success.  Each iteration is
a fresh OpenROAD process.

Usage (from repo root):
    python flow/pnr/sweep_utilization.py \
        --top regfile --netlist results/smoke/netlist.v \
        --report-dir reports
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

OPENROAD_CMD = os.environ.get("OPENROAD_CMD", "openroad")
PNR_SCRIPT = Path(__file__).resolve().parent / "estimate_placement_area.tcl"


def try_utilization(
    top: str,
    netlist: Path,
    report_dir: Path,
    util: int,
) -> tuple[bool, str]:
    """Run one OpenROAD placement attempt.  Returns (success, log)."""
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".tcl", delete=False, prefix="regfile_pnr_"
    ) as tf:
        tf.write(f"set TOP        {top}\n")
        tf.write(f"set NETLIST_V  {{{netlist}}}\n")
        tf.write(f"set REPORT_DIR {{{report_dir}}}\n")
        tf.write(f"set UTIL       {util}\n")
        tf.write(f"source {PNR_SCRIPT}\n")
        tmp_tcl = tf.name

    try:
        proc = subprocess.Popen(
            [OPENROAD_CMD, tmp_tcl, "-exit"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        lines: list[str] = []
        assert proc.stdout is not None
        for line in proc.stdout:
            sys.stdout.write(line)
            sys.stdout.flush()
            lines.append(line)
        proc.wait()
    finally:
        os.unlink(tmp_tcl)

    log = "".join(lines)
    return proc.returncode == 0, log


def sweep(
    top: str,
    netlist: Path,
    report_dir: Path,
    util_max: int = 95,
    util_min: int = 5,
    step: int = 5,
) -> int | None:
    """Sweep utilization high→low, return the first passing value (or None)."""
    report_dir = Path(report_dir)
    report_dir.mkdir(parents=True, exist_ok=True)

    for u in range(util_max, util_min - 1, -step):
        ok, log = try_utilization(top, netlist, report_dir, u)
        (report_dir / "openroad.log").write_text(log)

        if ok:
            print(f"Utilization {u}% passed.")
            return u
        else:
            print(f"Utilization {u}% failed.")

    return None


def main():
    parser = argparse.ArgumentParser(
        description="Sweep OpenROAD core utilization"
    )
    parser.add_argument("--top", default="regfile")
    parser.add_argument("--netlist", required=True, type=Path)
    parser.add_argument("--report-dir", required=True, type=Path)
    parser.add_argument("--util-max", type=int, default=95)
    parser.add_argument("--util-min", type=int, default=5)
    parser.add_argument("--step", type=int, default=5)
    args = parser.parse_args()

    best = sweep(
        args.top,
        args.netlist,
        args.report_dir,
        args.util_max,
        args.util_min,
        args.step,
    )
    if best is None:
        print("No utilization value succeeded.", file=sys.stderr)
        sys.exit(1)
    print(f"Best utilization: {best}%")


if __name__ == "__main__":
    main()
