"""Gera fair_indicadores.png (painel de barras) a partir de indicadores_fair_detalhados_sat.csv.

Entrada:
- 8-REVISÃO_ESCOPO_SAT/2-DADOS/scripts/indicadores_fair_detalhados_sat.csv

Saída:
- 8-REVISÃO_ESCOPO_SAT/2-FIGURAS/2-EN/fair_indicadores.png

Observação:
- Este script existe para atender ao LaTeX, que usa fair_radar_2.png como (a) e
  espera um PNG separado para (b).
"""

from __future__ import annotations

import os

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


COLOR_BAR_FACE = "#B3CDE3"  # Pastel Blue (consistente com outras figuras)
COLOR_BAR_EDGE = "0.2"
HATCH_PATTERN = "//////"


def _apply_style() -> None:
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
            "axes.grid": False,
        }
    )


def main() -> None:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sat_root = os.path.abspath(os.path.join(script_dir, "..", ".."))

    input_csv = os.path.join(script_dir, "indicadores_fair_detalhados_sat.csv")
    out_png = os.path.join(sat_root, "2-FIGURAS", "2-EN", "fair_indicadores.png")

    if not os.path.exists(input_csv):
        raise FileNotFoundError(
            f"CSV não encontrado: {input_csv}. Rode build_sat_fair_dataset.py primeiro."
        )

    df = pd.read_csv(input_csv)
    required = {"indicador_en", "percentual", "n_sim"}
    missing = sorted(required - set(df.columns))
    if missing:
        raise ValueError(f"Colunas ausentes no CSV: {', '.join(missing)}")

    df = df.copy()
    df["n_sim"] = df["n_sim"].fillna(0).astype(int)

    # Remove indicadores sem evidência
    df = df[df["n_sim"] > 0].copy()

    # Ordena por percentual (crescente)
    df = df.sort_values("percentual", ascending=True).reset_index(drop=True)

    names = df["indicador_en"].astype(str).tolist()
    values = df["percentual"].astype(float).tolist()
    n_sim = df["n_sim"].astype(int).tolist()

    _apply_style()

    # Altura proporcional ao número de barras
    fig_h = max(5.5, 0.38 * len(names) + 1.4)
    fig, ax = plt.subplots(figsize=(10.5, fig_h))

    y_pos = np.arange(len(names))

    rects = ax.barh(
        y_pos,
        values,
        align="center",
        height=0.7,
        color=COLOR_BAR_FACE,
        edgecolor=COLOR_BAR_EDGE,
        hatch=HATCH_PATTERN,
        linewidth=0.8,
    )

    ax.set_yticks(y_pos)
    ax.set_yticklabels(names, fontsize=10)
    ax.set_xlabel("Compliance rate (%)", fontsize=10, labelpad=8)
    ax.set_xlim(0, 115)

    ax.xaxis.grid(True, linestyle=(0, (5, 5)), color="0.85", zorder=0)
    ax.set_axisbelow(True)

    for i, rect in enumerate(rects):
        width = float(rect.get_width())
        ax.text(
            width + 2,
            rect.get_y() + rect.get_height() / 2,
            f"{values[i]:.1f}%\n(n={n_sim[i]})",
            ha="left",
            va="center",
            fontsize=9,
            color="black",
        )

    os.makedirs(os.path.dirname(out_png), exist_ok=True)
    fig.savefig(out_png, dpi=300, bbox_inches="tight", pad_inches=0.2, facecolor="white")
    print(f"✓ Figura salva em: {out_png}")


if __name__ == "__main__":
    main()
