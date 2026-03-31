"""
parse_reports.py — Utilities for extracting metrics from Yosys stat reports.

Yosys 0.60 stat -liberty output format:
    === <module> ===
         N        - wires
         N        - wire bits
         ...
         N  <area>   cells
         N  <area>   sg13g2_<cell>_<drive>
         ...
       Chip area for module '<module>': <float>
         of which used for sequential elements: <float> (<pct>%)
"""

from __future__ import annotations

import re
from pathlib import Path


# ---------------------------------------------------------------------------
# Area extraction
# ---------------------------------------------------------------------------

def parse_chip_area(report: str) -> float | None:
    """Return total chip area (µm²) or None."""
    m = re.search(r"Chip area for (?:top )?module[^:]*:\s*([\d.]+)", report)
    return float(m.group(1)) if m else None


def parse_seq_area(report: str) -> float | None:
    """Return sequential-element area (µm²) or None."""
    m = re.search(r"of which used for sequential elements:\s*([\d.]+)", report)
    return float(m.group(1)) if m else None


def parse_wire_port_counts(report: str) -> dict[str, int]:
    """
    Extract wire/port counts from lines like:
        3443        - wires
        4573        - wire bits
    """
    counts: dict[str, int] = {}
    for m in re.finditer(r"^\s+(\d+)\s+-\s+(.+)$", report, re.MULTILINE):
        counts[m.group(2).strip()] = int(m.group(1))
    return counts


def parse_cell_instances(report: str) -> dict[str, int]:
    """
    Extract per-cell-type instance counts from lines like:
        1024 5.02E+04   sg13g2_dfrbpq_1
    Returns {cell_name: count}.
    """
    instances: dict[str, int] = {}
    # Lines: <count> <area_or_dash> <cell_name>
    for m in re.finditer(
        r"^\s+(\d+)\s+[\d.E+\-]+\s+(sg13g2_\S+)\s*$", report, re.MULTILINE
    ):
        instances[m.group(2)] = int(m.group(1))
    return instances


def parse_total_cells(report: str) -> int | None:
    """Return total mapped cell count."""
    # Line looks like:  4523 9.83E+04 cells
    m = re.search(r"^\s+(\d+)\s+[\d.E+\-]+\s+cells\s*$", report, re.MULTILINE)
    return int(m.group(1)) if m else None


def parse_ff_count(report: str) -> int:
    """Return flip-flop count by summing DFF/DFFR cell instances."""
    instances = parse_cell_instances(report)
    return sum(v for k, v in instances.items()
               if re.search(r"df[fr]", k, re.IGNORECASE))


def load_report(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def parse_report_file(path: Path) -> dict:
    """Parse a stat.rpt file and return a flat metrics dict."""
    text = load_report(path)
    counts = parse_wire_port_counts(text)
    return {
        "chip_area_um2":  parse_chip_area(text),
        "seq_area_um2":   parse_seq_area(text),
        "total_cells":    parse_total_cells(text),
        "ff_count":       parse_ff_count(text),
        "n_wires":        counts.get("wires"),
        "n_wire_bits":    counts.get("wire bits"),
        "n_pub_wires":    counts.get("public wires"),
        "n_ports":        counts.get("ports"),
    }
