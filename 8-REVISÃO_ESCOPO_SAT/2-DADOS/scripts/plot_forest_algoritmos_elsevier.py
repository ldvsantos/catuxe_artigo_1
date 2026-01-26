"""Forest plot (estilo manuscrito) — meta-análise por algoritmo.

Objetivo: reproduzir o layout do script R `plot_forest_algoritmos.R` (metafor):
- Tabela manual à esquerda (Estudo, n, % acurácia, IC 95%, Peso)
- Forest no miolo em escala logit, com ticks mostrados em proporção
- Coluna à direita com "Estimativa [IC 95%]"
- Linha vertical no efeito combinado e diamante do modelo

Entrada:
- 8-REVISÃO_ESCOPO_SAT/2-DADOS/1-ESTATISTICA/1-RSTUDIO/9-META_ANALISE/meta_analise_por_algoritmo_sat.csv

Saída:
- 8-REVISÃO_ESCOPO_SAT/2-FIGURAS/2-EN/meta_analise_algoritmos.png
"""

from __future__ import annotations

import math
import os

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


def _clamp01(x: np.ndarray | float, eps: float = 1e-4):
    return np.clip(x, eps, 1.0 - eps)


def _logit(p: np.ndarray | float):
    p = _clamp01(np.asarray(p, dtype=float))
    return np.log(p / (1.0 - p))


def _ilogit(x: np.ndarray | float):
    x = np.asarray(x, dtype=float)
    return 1.0 / (1.0 + np.exp(-x))


def _apply_elsevier_style():
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


def _reml_tau2(yi: np.ndarray, vi: np.ndarray) -> float:
    """Estima tau^2 por REML via busca 1D (sem SciPy)."""

    yi = np.asarray(yi, dtype=float)
    vi = np.asarray(vi, dtype=float)

    def nll(tau2: float) -> float:
        tau2 = float(max(0.0, tau2))
        wi = 1.0 / (vi + tau2)
        sw = float(np.sum(wi))
        if not np.isfinite(sw) or sw <= 0:
            return float("inf")
        mu = float(np.sum(wi * yi) / sw)
        q = float(np.sum(wi * (yi - mu) ** 2))
        # -l_R (constantes removidas)
        return 0.5 * (float(np.sum(np.log(vi + tau2))) + math.log(sw) + q)

    # Intervalo inicial (0..hi)
    hi = float(max(1e-6, np.var(yi)))
    # garante hi razoável
    hi = max(hi, float(np.nanmax(vi)) * 5.0)

    # se a função ainda está diminuindo, aumenta hi
    f0 = nll(0.0)
    fhi = nll(hi)
    expand = 0
    while np.isfinite(fhi) and fhi < f0 and expand < 12:
        hi *= 2.0
        fhi = nll(hi)
        expand += 1

    # Golden-section search em [0, hi]
    lo = 0.0
    gr = (math.sqrt(5) - 1) / 2  # ~0.618
    x1 = hi - gr * (hi - lo)
    x2 = lo + gr * (hi - lo)
    f1 = nll(x1)
    f2 = nll(x2)
    for _ in range(180):
        if abs(hi - lo) < 1e-10:
            break
        if f1 > f2:
            lo = x1
            x1 = x2
            f1 = f2
            x2 = lo + gr * (hi - lo)
            f2 = nll(x2)
        else:
            hi = x2
            x2 = x1
            f2 = f1
            x1 = hi - gr * (hi - lo)
            f1 = nll(x1)
    return float(max(0.0, (lo + hi) / 2.0))


def main() -> None:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sat_root = os.path.abspath(os.path.join(script_dir, "..", ".."))
    meta_dir = os.path.join(sat_root, "2-DADOS", "1-ESTATISTICA", "1-RSTUDIO", "9-META_ANALISE")
    fig_dir_en = os.path.join(sat_root, "2-FIGURAS", "2-EN")

    # SAT-only source (built from BibTeX): build_sat_meta_analysis_dataset.py
    input_csv = os.path.join(meta_dir, "meta_analise_por_algoritmo_sat.csv")
    out_png = os.path.join(fig_dir_en, "meta_analise_algoritmos.png")

    if not os.path.exists(input_csv):
        raise FileNotFoundError(
            f"Arquivo não encontrado: {input_csv}. Rode primeiro build_sat_meta_analysis_dataset.py"
        )

    df = pd.read_csv(input_csv)
    required = {"algoritmo", "acuracia_pooled", "ic_inferior", "ic_superior", "n_estudos"}
    missing = sorted(required - set(df.columns))
    if missing:
        raise ValueError(f"Colunas ausentes no CSV: {', '.join(missing)}")

    df = df.copy()
    df["algoritmo"] = df["algoritmo"].astype(str).str.strip()
    df = df.sort_values("acuracia_pooled", ascending=False).reset_index(drop=True)

    # Preparar dados (proporção)
    p = _clamp01(df["acuracia_pooled"].to_numpy(dtype=float) / 100.0)
    p_low = _clamp01(df["ic_inferior"].to_numpy(dtype=float) / 100.0)
    p_high = _clamp01(df["ic_superior"].to_numpy(dtype=float) / 100.0)

    yi = _logit(p)
    # SE a partir do IC (mesma aproximação do R)
    sei = (_logit(p_high) - _logit(p_low)) / (2.0 * 1.96)
    vi = sei**2

    # REML (para efeito combinado e pesos)
    tau2 = _reml_tau2(yi, vi)
    wi = 1.0 / (vi + tau2)
    wsum = float(np.sum(wi))
    mu = float(np.sum(wi * yi) / wsum)
    se_mu = float(math.sqrt(1.0 / wsum))
    ci_mu = (mu - 1.96 * se_mu, mu + 1.96 * se_mu)

    # Tamanho dos quadrados proporcional ao peso
    psize_vec = 0.95 + 2.15 * np.sqrt(wi / float(np.max(wi)))

    # Layout (espelha o R)
    k = len(df)
    rows_studies = np.arange(k, 0, -1)  # k..1
    row_model = 0
    ylim = (-1.2, k + 2.2)

    # ticks em proporção, mas coordenadas em logit
    # Observação: no manuscrito a figura é reduzida (minipage 0.49\textwidth),
    # então muitos ticks acabam sobrepondo. Mantemos uma régua mais “limpa”.
    x_ticks_p = np.array([0.75, 0.85, 0.90, 0.95], dtype=float)
    at_logit = _logit(x_ticks_p)
    alim_logit = _logit(np.array([0.73, 0.99], dtype=float))

    xlim_logit = (-9.2, 9.4)
    xr = xlim_logit[1] - xlim_logit[0]

    forest_left = float(alim_logit[0])
    forest_right = float(alim_logit[1])

    table_left = xlim_logit[0] + 0.02 * xr
    gap_table_forest = 0.35
    table_right = forest_left - gap_table_forest
    table_width = table_right - table_left

    x_estudo = table_left
    x_n = table_left + 0.40 * table_width
    x_acc = table_left + 0.58 * table_width
    x_ic = table_left + 0.80 * table_width
    x_peso = table_left + 0.96 * table_width

    gap_forest_est = 0.25
    x_est_txt = forest_right + gap_forest_est

    peso_pct = (df["n_estudos"].to_numpy(dtype=float) / float(df["n_estudos"].sum())) * 100.0

    _apply_elsevier_style()
    # Figura mais larga para dar folga aos ticks do eixo X (evita rótulos “empilhados”)
    fig, ax = plt.subplots(figsize=(14.5, max(6.0, 0.55 * k + 3.0)))

    ax.set_xlim(xlim_logit)
    ax.set_ylim(ylim)

    # Eixo X com ticks em logit mas rótulos em proporção
    ax.set_xticks(at_logit)
    ax.set_xticklabels([f"{t:.2f}" for t in x_ticks_p])
    ax.set_xlabel("Acurácia consolidada (proporção)")
    ax.tick_params(axis="x", labelsize=9, pad=8)

    # Sem y-axis (tabela é manual)
    ax.set_yticks([])

    # Remove frame
    for spine in ["top", "right", "left"]:
        ax.spines[spine].set_visible(False)

    # Forest: linha de referência no efeito combinado
    ax.axvline(mu, linestyle=(0, (2, 2)), linewidth=1.2, color="0.45")

    # Forest: linhas de IC e quadrados
    ci_color = "0.35"
    box_edge = "0.2"
    box_face = "#B3CDE3"  # Pastel Blue (do script de referência)
    
    for i in range(k):
        y = float(rows_studies[i])
        lo = float(_logit(p_low[i]))
        hi = float(_logit(p_high[i]))
        ax.plot([lo, hi], [y, y], color=ci_color, lw=1.0, zorder=2)

    ax.scatter(
        yi,
        rows_studies,
        marker="s",
        s=(psize_vec**2) * 14.0,
        facecolor=box_face,
        edgecolor=box_edge,
        linewidth=0.8,
        hatch="//////",
        zorder=3,
    )

    # Header estilo APA (texto entre duas linhas)
    y_header = k + 1.10
    y_rule_top = y_header + 0.24
    y_rule_bottom = y_header - 0.24
    ax.hlines([y_rule_top, y_rule_bottom], xlim_logit[0], xlim_logit[1], colors="black", linewidth=1.0)

    ax.text(x_estudo, y_header, "Estudo", ha="left", va="center", fontweight="bold", fontsize=10)
    ax.text(x_n, y_header, "n", ha="right", va="center", fontweight="bold", fontsize=9)
    ax.text(x_acc, y_header, "% acurácia", ha="right", va="center", fontweight="bold", fontsize=9)
    ax.text(x_ic, y_header, "IC 95%", ha="right", va="center", fontweight="bold", fontsize=9)
    ax.text(x_peso, y_header, "Peso (%)", ha="right", va="center", fontweight="bold", fontsize=9)
    ax.text(x_est_txt, y_header, "Estimativa [IC 95%]", ha="left", va="center", fontweight="bold", fontsize=10)

    # Linhas da tabela (manual)
    for i in range(k):
        y = float(rows_studies[i])
        ax.text(x_estudo, y, df.loc[i, "algoritmo"], ha="left", va="center", fontsize=10)
        ax.text(x_n, y, f"{int(df.loc[i, 'n_estudos'])}", ha="right", va="center", fontsize=9)
        ax.text(x_acc, y, f"{float(df.loc[i, 'acuracia_pooled']):.1f}", ha="right", va="center", fontsize=9)
        ax.text(
            x_ic,
            y,
            f"[{float(df.loc[i, 'ic_inferior']):.1f}; {float(df.loc[i, 'ic_superior']):.1f}]",
            ha="right",
            va="center",
            fontsize=9,
        )
        ax.text(x_peso, y, f"{peso_pct[i]:.1f}", ha="right", va="center", fontsize=9)

        ax.text(
            x_est_txt,
            y,
            f"{p[i]:.3f} [{p_low[i]:.3f}, {p_high[i]:.3f}]",
            ha="left",
            va="center",
            fontsize=9,
        )

    # Separador + modelo
    y_sep_model = (float(np.min(rows_studies)) + float(row_model)) / 2.0
    ax.hlines(y_sep_model, xlim_logit[0], xlim_logit[1], colors="0.75", linewidth=1.0)
    ax.text(x_estudo, row_model, "Modelo de efeitos aleatórios (REML)", ha="left", va="center", fontsize=10)

    # Diamond do modelo
    diamond_y = float(row_model)
    diamond_h = 0.26
    x0, x1 = ci_mu
    xm = mu
    diamond = np.array(
        [
            [x0, diamond_y],
            [xm, diamond_y + diamond_h],
            [x1, diamond_y],
            [xm, diamond_y - diamond_h],
        ]
    )
    # Diamond com cor diferente (destaque) e sem hachura
    ax.fill(diamond[:, 0], diamond[:, 1], color="#FBB4AE", edgecolor=box_edge, linewidth=1.0, zorder=2)

    ax.text(
        x_est_txt,
        row_model,
        f"{float(_ilogit(mu)):.3f} [{float(_ilogit(ci_mu[0])):.3f}, {float(_ilogit(ci_mu[1])):.3f}]",
        ha="left",
        va="center",
        fontsize=9,
    )

    os.makedirs(fig_dir_en, exist_ok=True)
    # Um pouco mais de respiro na base ajuda o xlab e os ticks
    fig.subplots_adjust(bottom=0.10)
    fig.savefig(out_png, dpi=300, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print(f"✓ Figura salva em: {out_png}")


if __name__ == "__main__":
    main()
