"""Temporal figures (SAT-only) in Elsevier-like style.

Style: Points + connecting line (blue) with LOESS trend zone (orange ribbon)
for (a), and multi-line plot per algorithm family for (b).
Matches the original R ggplot2 figures (05a/05b).

Inputs:
- mca_dados_categorizados_sat.csv (SAT-only categorical dataset)

Outputs (overwrite):
- ../../2-FIGURAS/2-EN/temporal_publicacoes.png
- ../../2-FIGURAS/2-EN/temporal_algoritmos.png

Run:
  python plot_temporal_sat_elsevier.py
"""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.interpolate import make_interp_spline
from scipy.stats import norm

# ── Colours ──────────────────────────────────────────────────────────────────
COLOR_LINE = "#2E86AB"       # Blue line + points (publications)
COLOR_TREND = "#FC4E07"      # Orange LOESS trend + ribbon

# Viridis-plasma subset for algorithm families (matches ggplot2 viridis plasma)
ALGO_COLORS = [
    "#0D0887",  # deep purple
    "#7E03A8",  # purple
    "#CC4678",  # pink-red
    "#F0F921",  # yellow
    "#F89441",  # orange
    "#3CBB75",  # green
    "#21918C",  # teal
]


def _style() -> None:
    plt.rcParams.update(
        {
            "figure.dpi": 300,
            "savefig.dpi": 300,
            "font.family": "serif",
            "font.size": 11,
            "axes.facecolor": "white",
            "figure.facecolor": "white",
            "axes.spines.top": False,
            "axes.spines.right": False,
        }
    )


def _loess_like(x: np.ndarray, y: np.ndarray, frac: float = 0.75,
                n_out: int = 200) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Compute LOWESS smoothing with standard-error ribbon.

    Uses statsmodels lowess for the trend and a simple local residual
    estimate for the SE band (90 % CI), mimicking R's loess(span=0.75).
    """
    try:
        from statsmodels.nonparametric.smoothers_lowess import lowess as sm_lowess
    except ImportError:
        # Fallback: numpy polyfit
        coeffs = np.polyfit(x, y, 3)
        x_smooth = np.linspace(x.min(), x.max(), n_out)
        y_smooth = np.polyval(coeffs, x_smooth)
        residual_se = np.std(y - np.polyval(coeffs, x))
        z90 = norm.ppf(0.95)
        return x_smooth, y_smooth, np.full_like(y_smooth, residual_se * z90)

    raw = sm_lowess(y, x, frac=frac, return_sorted=True)
    x_lo, y_lo = raw[:, 0], raw[:, 1]

    # Interpolate to a fine grid for smooth ribbon
    x_smooth = np.linspace(x.min(), x.max(), n_out)
    if len(x_lo) >= 4:
        spl = make_interp_spline(x_lo, y_lo, k=3)
        y_smooth = spl(x_smooth)
    else:
        y_smooth = np.interp(x_smooth, x_lo, y_lo)

    # Approximate local SE: residual std within sliding window
    fitted_at_data = np.interp(x, x_lo, y_lo)
    residuals = y - fitted_at_data
    global_se = np.std(residuals)

    z90 = norm.ppf(0.95)  # 90 % bilateral
    half_width = z90 * global_se

    return x_smooth, y_smooth, np.full_like(y_smooth, half_width)


def main() -> None:
    _style()

    here = Path(__file__).resolve().parent
    df = pd.read_csv(here / "mca_dados_categorizados_sat.csv")

    df = df.dropna(subset=["Ano"]).copy()
    df["Ano"] = df["Ano"].astype(int)

    # Manuscript scope
    df = df[(df["Ano"] >= 2010) & (df["Ano"] <= 2025)].copy()

    out_dir = (here / "../../2-FIGURAS/2-EN").resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    years = np.arange(2010, 2026)

    # ── (a) Publications over time: points + line + LOESS ribbon ─────────
    counts = df.groupby("Ano").size().reindex(years, fill_value=0)
    x_data = years.astype(float)
    y_data = counts.values.astype(float)

    x_sm, y_sm, hw = _loess_like(x_data, y_data)

    fig, ax = plt.subplots(figsize=(10, 6))

    # Orange LOESS ribbon (90 % CI)
    lwr = np.maximum(0, y_sm - hw)
    upr = y_sm + hw
    ax.fill_between(x_sm, lwr, upr, color=COLOR_TREND, alpha=0.18, zorder=1)
    ax.plot(x_sm, upr, color=COLOR_TREND, linewidth=0.6, alpha=0.9, zorder=2)
    ax.plot(x_sm, lwr, color=COLOR_TREND, linewidth=0.6, alpha=0.9, zorder=2)

    # Orange dashed trend line
    ax.plot(x_sm, y_sm, color=COLOR_TREND, linewidth=0.9, linestyle="--", zorder=3)

    # Blue data line + points
    ax.plot(x_data, y_data, color=COLOR_LINE, linewidth=1.0, zorder=4)
    ax.scatter(x_data, y_data, color=COLOR_LINE, s=30, alpha=0.85, zorder=5,
               edgecolors="white", linewidths=0.4)

    ax.set_xlabel("Publication year")
    ax.set_ylabel("Number of studies")
    ax.set_xticks(np.arange(2010, 2026, 2))
    ax.grid(axis="y", linestyle=(0, (5, 5)), color="0.85")
    ax.set_axisbelow(True)

    # print key numbers used in text
    y0 = int(counts.loc[2010])
    y_last2 = int(counts.loc[2024] + counts.loc[2025])
    print(f"TEMPORAL (SAT-only from MCA table): 2010={y0} and 2024-2025={y_last2}")

    fig.tight_layout()
    fig.savefig(out_dir / "temporal_publicacoes.png", facecolor="white", bbox_inches="tight")
    plt.close(fig)

    # ── (b) Algorithm trajectory: multi-line plot per family ─────────────
    algo = df["Algoritmo"].fillna("Other").astype(str)
    df_algo = df.assign(Algoritmo=algo)

    top = (
        df_algo[df_algo["Ano"] >= 2010]
        .groupby("Algoritmo")
        .size()
        .sort_values(ascending=False)
        .head(6)
        .index.tolist()
    )

    # ensure stable ordering (Other last if present)
    if "Other" in top:
        top = [x for x in top if x != "Other"] + ["Other"]

    pivot = (
        df_algo[df_algo["Algoritmo"].isin(top)]
        .groupby(["Ano", "Algoritmo"])
        .size()
        .unstack(fill_value=0)
        .reindex(index=years, fill_value=0)
        .reindex(columns=top)
    )

    colors = ALGO_COLORS[: len(top)]

    fig, ax = plt.subplots(figsize=(10, 6))

    for i, alg in enumerate(top):
        vals = pivot[alg].values
        ax.plot(years, vals, color=colors[i], linewidth=0.9, alpha=0.85,
                label=alg, zorder=3)
        ax.scatter(years, vals, color=colors[i], s=22, alpha=0.85,
                   edgecolors="white", linewidths=0.3, zorder=4)

    ax.set_xlabel("Publication year")
    ax.set_ylabel("Frequency")
    ax.set_xticks(np.arange(2010, 2026, 2))
    ax.grid(axis="y", linestyle=(0, (5, 5)), color="0.85")
    ax.set_axisbelow(True)

    ax.legend(loc="upper left", frameon=True, fontsize=9, title="Algorithm family",
              title_fontsize=10)

    fig.tight_layout()
    fig.savefig(out_dir / "temporal_algoritmos.png", facecolor="white", bbox_inches="tight")
    plt.close(fig)

    print("OK: temporal figures generated")


if __name__ == "__main__":
    main()
