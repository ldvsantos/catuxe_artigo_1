"""Temporal figures (SAT-only) in Elsevier-like style.

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


PASTEL = {
    "blue": "#8CB7D9",
    "green": "#9FD1AE",
    "orange": "#F2C38F",
    "pink": "#E7A6B8",
    "purple": "#B8A7D9",
    "teal": "#8FD3D1",
    "gray": "#9AA0A6",
}


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

    # (a) Publications over time
    counts = df.groupby("Ano").size().reindex(years, fill_value=0)

    fig, ax = plt.subplots(figsize=(10, 6))
    ax.bar(years, counts.values, color=PASTEL["blue"], edgecolor="#333333", linewidth=0.6, alpha=0.9)
    ax.plot(years, counts.values, color="#333333", linewidth=1.8)

    ax.set_xlabel("Publication year")
    ax.set_ylabel("Number of studies")
    ax.set_title("Temporal evolution of SAT studies")
    ax.grid(axis="y", linestyle=(0, (5, 5)), color="0.85")
    ax.set_axisbelow(True)

    # print key numbers used in text
    y0 = int(counts.loc[2010])
    y_last2 = int(counts.loc[2024] + counts.loc[2025])
    print(f"TEMPORAL (SAT-only from MCA table): 2010={y0} and 2024-2025={y_last2}")

    fig.tight_layout()
    fig.savefig(out_dir / "temporal_publicacoes.png", facecolor="white", bbox_inches="tight")
    plt.close(fig)

    # (b) Algorithm trajectory
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

    # normalize to proportions
    totals = pivot.sum(axis=1).replace(0, np.nan)
    props = pivot.div(totals, axis=0).fillna(0)

    colors = [PASTEL["green"], PASTEL["orange"], PASTEL["purple"], PASTEL["pink"], PASTEL["teal"], PASTEL["gray"]]
    colors = colors[: len(top)]

    fig, ax = plt.subplots(figsize=(10, 6))
    ax.stackplot(years, [props[c].values for c in top], labels=top, colors=colors, alpha=0.95, edgecolor="white", linewidth=0.4)

    ax.set_xlabel("Publication year")
    ax.set_ylabel("Share of algorithms")
    ax.set_title("Algorithm composition over time")
    ax.set_ylim(0, 1)
    ax.set_yticks([0, 0.25, 0.5, 0.75, 1.0])
    ax.set_yticklabels(["0%", "25%", "50%", "75%", "100%"])
    ax.grid(axis="y", linestyle=(0, (5, 5)), color="0.85")
    ax.set_axisbelow(True)

    ax.legend(loc="upper left", frameon=True, fontsize=9)

    fig.tight_layout()
    fig.savefig(out_dir / "temporal_algoritmos.png", facecolor="white", bbox_inches="tight")
    plt.close(fig)

    print("OK: temporal figures generated")


if __name__ == "__main__":
    main()
