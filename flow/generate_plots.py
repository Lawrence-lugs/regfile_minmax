#!/usr/bin/env python3
"""
generate_plots.py — Standalone script that reads results/summary.csv and
writes all matplotlib PNG figures to results/.
Run inside the Docker container from the repo root.
"""

import sys
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")          # headless — no display needed
import matplotlib.pyplot as plt

plt.rcParams.update({"figure.dpi": 150, "font.size": 11, "axes.grid": True,
                     "grid.alpha": 0.3})

CSV = Path("results/summary.csv")
if not CSV.exists():
    print("ERROR: results/summary.csv not found. Run flow/run_sweep.py first.")
    sys.exit(1)

df = pd.read_csv(CSV)
df = df[df["status"] == "OK"].copy()
print(f"Loaded {len(df)} successful runs across sweeps: {df['sweep'].unique()}")

OUT = Path("results")

# ---------------------------------------------------------------------------
# 1. Port sweep — area vs Nr (lines) coloured by Nw
# ---------------------------------------------------------------------------
port = df[df["sweep"] == "port"].copy()
port["total_ports"] = port["NUM_RD_PORTS"] + port["NUM_WR_PORTS"]

fig, axes = plt.subplots(1, 2, figsize=(13, 5))
colors = plt.cm.viridis(np.linspace(0.2, 0.85, port["NUM_WR_PORTS"].nunique()))

for (nw, grp), c in zip(port.groupby("NUM_WR_PORTS"), colors):
    g = grp.sort_values("NUM_RD_PORTS")
    axes[0].plot(g["NUM_RD_PORTS"], g["chip_area_um2"] / 1e3,
                 marker="o", color=c, label=f"Nw={nw}")

axes[0].set_xlabel("Read ports (Nr)")
axes[0].set_ylabel("Chip area (×10³ µm²)")
axes[0].set_title("Area vs Read ports")
axes[0].legend(title="Write ports")

for (nr, grp), c in zip(port.groupby("NUM_RD_PORTS"), plt.cm.plasma(np.linspace(0.15, 0.9, port["NUM_RD_PORTS"].nunique()))):
    g = grp.sort_values("NUM_WR_PORTS")
    axes[1].plot(g["NUM_WR_PORTS"], g["chip_area_um2"] / 1e3,
                 marker="s", color=c, label=f"Nr={nr}")

axes[1].set_xlabel("Write ports (Nw)")
axes[1].set_ylabel("Chip area (×10³ µm²)")
axes[1].set_title("Area vs Write ports")
axes[1].legend(title="Read ports", ncol=2, fontsize=9)

fig.suptitle("Port Sweep — IHP SG13G2, 32 regs × 32-bit", fontsize=13, fontweight="bold")
plt.tight_layout()
fig.savefig(OUT / "port_sweep.png", bbox_inches="tight")
plt.close(fig)
print("  ✓ port_sweep.png")

# ---------------------------------------------------------------------------
# 2. Log-log power-law fit (area ~ P^α)
# ---------------------------------------------------------------------------
fit_data = port[port["chip_area_um2"].notna()].copy()
fit_data["log_P"] = np.log(fit_data["total_ports"])
fit_data["log_A"] = np.log(fit_data["chip_area_um2"])
coef = np.polyfit(fit_data["log_P"], fit_data["log_A"], 1)
alpha = coef[0]

P_range = np.linspace(fit_data["total_ports"].min(), fit_data["total_ports"].max(), 200)
A_fit   = np.exp(coef[1]) * P_range ** alpha

fig, ax = plt.subplots(figsize=(7, 5))
sc = ax.scatter(fit_data["total_ports"], fit_data["chip_area_um2"] / 1e3,
                c=fit_data["NUM_WR_PORTS"], cmap="viridis", s=70, zorder=5,
                label="Synthesis data")
plt.colorbar(sc, ax=ax, label="Write ports (Nw)")
ax.plot(P_range, A_fit / 1e3, "r--", lw=2,
        label=f"Power-law fit  α = {alpha:.2f}\n(paper predicts ≈ 2.0)")
ax.set_xlabel("Total ports  P = Nr + Nw")
ax.set_ylabel("Chip area (×10³ µm²)")
ax.set_title("Area scaling with total port count")
ax.legend()
plt.tight_layout()
fig.savefig(OUT / "port_scaling_fit.png", bbox_inches="tight")
plt.close(fig)
print(f"  ✓ port_scaling_fit.png  (α = {alpha:.3f})")

# ---------------------------------------------------------------------------
# 3. Bit-width sweep
# ---------------------------------------------------------------------------
bw = df[df["sweep"] == "bitwidth"].sort_values("BITWIDTH").copy()
ref = bw.iloc[0]

fig, ax = plt.subplots(figsize=(7, 4))
ax.plot(bw["BITWIDTH"], bw["chip_area_um2"] / 1e3, marker="o", lw=2, label="Synthesis")
ax.plot(bw["BITWIDTH"],
        ref["chip_area_um2"] / ref["BITWIDTH"] * bw["BITWIDTH"] / 1e3,
        "k--", alpha=0.5, label="Linear reference")
ax.set_xlabel("Bit-width (bits)")
ax.set_ylabel("Chip area (×10³ µm²)")
ax.set_title("Area vs Bit-width (2R1W, 32 regs)")
ax.legend()
plt.tight_layout()
fig.savefig(OUT / "bitwidth_sweep.png", bbox_inches="tight")
plt.close(fig)
print("  ✓ bitwidth_sweep.png")

# ---------------------------------------------------------------------------
# 4. Register count sweep
# ---------------------------------------------------------------------------
rc = df[df["sweep"] == "regcount"].sort_values("NUM_REGS").copy()
ref_rc = rc.iloc[0]

fig, ax = plt.subplots(figsize=(7, 4))
ax.plot(rc["NUM_REGS"], rc["chip_area_um2"] / 1e3, marker="^", lw=2, label="Synthesis")
ax.plot(rc["NUM_REGS"],
        ref_rc["chip_area_um2"] / ref_rc["NUM_REGS"] * rc["NUM_REGS"] / 1e3,
        "k--", alpha=0.5, label="Linear reference")
ax.set_xlabel("Number of registers")
ax.set_ylabel("Chip area (×10³ µm²)")
ax.set_title("Area vs Register count (2R1W, 32-bit)")
ax.legend()
plt.tight_layout()
fig.savefig(OUT / "regcount_sweep.png", bbox_inches="tight")
plt.close(fig)
print("  ✓ regcount_sweep.png")

# ---------------------------------------------------------------------------
# 5. Banking sweep
# ---------------------------------------------------------------------------
bank = df[df["sweep"] == "banking"].copy()
bank["config"] = bank.apply(lambda r: f"Nr={int(r.NUM_RD_PORTS)}, Nw={int(r.NUM_WR_PORTS)}", axis=1)

def normalise(grp):
    base = grp.loc[grp["NUM_BANKS"] == grp["NUM_BANKS"].min(), "chip_area_um2"].values
    if len(base) == 0 or np.isnan(base[0]):
        return grp
    grp = grp.copy()
    grp["area_norm"] = grp["chip_area_um2"] / base[0]
    return grp

bank_norm = bank.groupby(["NUM_RD_PORTS", "NUM_WR_PORTS"], group_keys=False).apply(normalise)
configs   = sorted(bank["config"].unique())
colors_b  = plt.cm.tab10(np.linspace(0, 0.6, len(configs)))

fig, axes = plt.subplots(1, 2, figsize=(13, 5))
for cfg, c in zip(configs, colors_b):
    g = bank[bank["config"] == cfg].sort_values("NUM_BANKS")
    axes[0].plot(g["NUM_BANKS"], g["chip_area_um2"] / 1e3, marker="o", color=c, label=cfg)
    gn = bank_norm[bank_norm["config"] == cfg].sort_values("NUM_BANKS")
    axes[1].plot(gn["NUM_BANKS"], gn["area_norm"], marker="s", color=c, label=cfg)

axes[0].set_xlabel("Number of banks")
axes[0].set_ylabel("Chip area (×10³ µm²)")
axes[0].set_title("Absolute area vs Banking factor")
axes[0].legend(fontsize=9)

axes[1].axhline(1.0, color="k", lw=1, ls="--", alpha=0.4, label="No-bank baseline")
axes[1].set_xlabel("Number of banks")
axes[1].set_ylabel("Normalised area  (1-bank = 1.0)")
axes[1].set_title("Normalised area vs Banking factor")
axes[1].legend(fontsize=9)

fig.suptitle("Banking Sweep — IHP SG13G2, 32 regs × 32-bit", fontsize=13, fontweight="bold")
plt.tight_layout()
fig.savefig(OUT / "banking_sweep.png", bbox_inches="tight")
plt.close(fig)
print("  ✓ banking_sweep.png")

# ---------------------------------------------------------------------------
# 6. Area heatmap  (port sweep)
# ---------------------------------------------------------------------------
pivot = port.pivot_table(values="chip_area_um2", index="NUM_WR_PORTS", columns="NUM_RD_PORTS")

fig, ax = plt.subplots(figsize=(10, 4))
im = ax.imshow(pivot.values / 1e3, aspect="auto", cmap="viridis")
ax.set_xticks(range(len(pivot.columns))); ax.set_xticklabels(pivot.columns)
ax.set_yticks(range(len(pivot.index)));  ax.set_yticklabels(pivot.index)
ax.set_xlabel("Read ports (Nr)"); ax.set_ylabel("Write ports (Nw)")
ax.set_title("Chip area (×10³ µm²) — 32 regs × 32-bit, IHP SG13G2")
for i in range(len(pivot.index)):
    for j in range(len(pivot.columns)):
        v = pivot.values[i, j]
        if not np.isnan(v):
            ax.text(j, i, f"{v/1e3:.1f}", ha="center", va="center",
                    fontsize=8, color="white", fontweight="bold")
plt.colorbar(im, ax=ax, label="×10³ µm²")
plt.tight_layout()
fig.savefig(OUT / "area_heatmap.png", bbox_inches="tight")
plt.close(fig)
print("  ✓ area_heatmap.png")

print(f"\nAll plots saved to {OUT}/")
print(f"Power-law exponent α = {alpha:.3f}  (paper predicts ≈ 2.0 for custom VLSI)")
