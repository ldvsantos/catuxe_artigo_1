"""Forest plot (estilo Elsevier) com coeficientes REAIS do modelo multivariável + (quando possível) multinível.

- Ajusta os mesmos modelos do `modelo_multinivel.py` (log-taxa como aproximação):
  M2: log_taxa_inspecao ~ ano_c + C(porte3) + denuncias_100_estab + share_informal
  M3: log_yield        ~ ano_c + C(porte3) + denuncias_100_estab + share_informal

- Para cada modelo, calcula RR = exp(coef) e IC95% = exp(IC95% em coef).
- Gera forest plot minimalista, pronto para artigo.

Entradas
- 1-DADOS/FISCALIZAÇÃO/Tabela_Final_(BACKUP 07012023).xlsx (Sheet1)

Saídas
- 3 - FIGURAS/PREDITIVO/forestplot_multinivel_M2.png
- 3 - FIGURAS/PREDITIVO/forestplot_multinivel_M3.png
"""

from __future__ import annotations

import os
import re
import unicodedata

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import statsmodels.formula.api as smf


def _fig_lang() -> str:
    return os.environ.get("FIG_LANG", "pt").strip().lower()


def _safe_float(x) -> float | None:
    try:
        v = float(x)
    except Exception:
        return None
    if not np.isfinite(v):
        return None
    return v


def _cohen_f2_from_r2(r2: float | None) -> float | None:
    r2v = _safe_float(r2)
    if r2v is None:
        return None
    if r2v <= 0:
        return 0.0
    if r2v >= 1:
        return None
    return r2v / (1.0 - r2v)


def _mixedlm_r2_nakagawa(res) -> tuple[float | None, float | None]:
    """R2 marginal/condicional (Nakagawa) para MixedLM com intercepto aleatório.

    Fórmulas:
      R2_marg = Var(Xβ) / (Var(Xβ) + Var(u) + Var(e))
      R2_cond = (Var(Xβ) + Var(u)) / (Var(Xβ) + Var(u) + Var(e))
    """
    try:
        if not hasattr(res, "model") or not hasattr(res, "fe_params"):
            return None, None
        exog = np.asarray(res.model.exog, dtype=float)
        fe = np.asarray(res.fe_params, dtype=float)
        xb = exog @ fe
        var_fixed = float(np.var(xb, ddof=1)) if xb.size > 1 else 0.0

        var_resid = _safe_float(getattr(res, "scale", None))
        if var_resid is None:
            var_resid = 0.0

        var_random = 0.0
        cov_re = getattr(res, "cov_re", None)
        if cov_re is not None:
            try:
                var_random = float(np.asarray(cov_re)[0, 0])
                if not np.isfinite(var_random) or var_random < 0:
                    var_random = 0.0
            except Exception:
                var_random = 0.0

        denom = var_fixed + var_random + var_resid
        if denom <= 0:
            return None, None
        r2_m = var_fixed / denom
        r2_c = (var_fixed + var_random) / denom
        return float(r2_m), float(r2_c)
    except Exception:
        return None, None


def _resolver_base_repo() -> str:
    # arquivo: .../4-ANALISES/analises_estatisticas_atuais/figura_forestplot_multinivel_reais.py
    # repo:   .../ARTIGO CREF
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def _norm_col(col: str) -> str:
    col = str(col).strip().replace("\uFFFD", "")
    col = unicodedata.normalize("NFKD", col)
    col = "".join([c for c in col if not unicodedata.combining(c)])
    col = col.lower()
    col = re.sub(r"[^a-z0-9]+", "_", col).strip("_")
    return col


def _safe_log_rate(num: pd.Series, denom: pd.Series, add: float = 0.5) -> pd.Series:
    num = pd.to_numeric(num, errors="coerce").fillna(0)
    denom = pd.to_numeric(denom, errors="coerce").fillna(0)
    denom = denom.replace(0, np.nan)
    return pd.Series(np.log(num + add) - np.log(denom), index=denom.index)


def _col(df: pd.DataFrame, name: str) -> pd.Series:
    if name in df.columns:
        return df[name]
    return pd.Series([np.nan] * len(df), index=df.index)


def _fmt_num_pt(x: float, digits: int = 2) -> str:
    if x is None or (isinstance(x, float) and not np.isfinite(x)):
        return "NA"
    return f"{x:.{digits}f}".replace(".", ",")


def _fmt_num_en(x: float, digits: int = 2) -> str:
    if x is None or (isinstance(x, float) and not np.isfinite(x)):
        return "NA"
    return f"{x:.{digits}f}"


def _fmt_num(x: float, digits: int = 2) -> str:
    if _fig_lang().startswith("en"):
        return _fmt_num_en(x, digits)
    return _fmt_num_pt(x, digits)


def _term_label(term: str) -> str:
    if _fig_lang().startswith("en"):
        mapping = {
            "ano_c": "Year (trend)",
            "denuncias_100_estab": "Complaints / 100 establishments",
            "share_informal": "Informality (share)",
            "C(porte3)[T.Médio]": "Size: Medium (vs Small)",
            "C(porte3)[T.Grande]": "Size: Large (vs Small)",
        }
    else:
        mapping = {
            "ano_c": "Ano (tendência)",
            "denuncias_100_estab": "Denúncias / 100 estab.",
            "share_informal": "Informalidade (proporção)",
            "C(porte3)[T.Médio]": "Porte: Médio (vs Pequeno)",
            "C(porte3)[T.Grande]": "Porte: Grande (vs Pequeno)",
        }
    return mapping.get(str(term), str(term))


def _extract_fixed_effects(res) -> pd.DataFrame:
    """Extrai coef/IC95% dos efeitos fixos de forma robusta (MixedLM ou OLS cluster)."""
    if hasattr(res, "fe_params"):
        # MixedLM
        fe = res.fe_params
        terms = list(fe.index)
        coef = fe.astype(float)
        se = pd.Series(getattr(res, "bse_fe", np.full(len(terms), np.nan)), index=terms, dtype=float)
        try:
            ci = res.conf_int().reindex(terms)
            ci_low = pd.to_numeric(ci.iloc[:, 0], errors="coerce")
            ci_high = pd.to_numeric(ci.iloc[:, 1], errors="coerce")
        except Exception:
            ci_low = pd.Series(np.nan, index=terms)
            ci_high = pd.Series(np.nan, index=terms)

        out = pd.DataFrame(
            {
                "term": terms,
                "coef": coef.values,
                "se": se.values,
                "ci_low": ci_low.values,
                "ci_high": ci_high.values,
            }
        )
        return out

    # OLS / cluster
    params = pd.to_numeric(res.params, errors="coerce")
    bse = pd.to_numeric(res.bse, errors="coerce")
    try:
        ci = res.conf_int()
        ci_low = pd.to_numeric(ci.iloc[:, 0], errors="coerce")
        ci_high = pd.to_numeric(ci.iloc[:, 1], errors="coerce")
    except Exception:
        ci_low = pd.Series(np.nan, index=params.index)
        ci_high = pd.Series(np.nan, index=params.index)

    out = pd.DataFrame(
        {
            "term": params.index.astype(str),
            "coef": params.values,
            "se": bse.values,
            "ci_low": ci_low.values,
            "ci_high": ci_high.values,
        }
    )
    return out


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


def _forestplot_comparativo(
    tab_a: pd.DataFrame,
    tab_b: pd.DataFrame,
    *,
    label_a: str,
    label_b: str,
    title: str,
    out_png: str,
) -> None:
    """Forest plot comparativo (duas séries por linha), no estilo do exemplo."""
    a = tab_a.copy()
    b = tab_b.copy()
    for t in (a, b):
        t = t
    for t in (a, b):
        t.drop(t[t["term"].astype(str).isin(["Intercept", "const"])].index, inplace=True)

    def _prep(t: pd.DataFrame) -> pd.DataFrame:
        out = t.copy()
        out["label"] = out["term"].map(_term_label)
        out["rr"] = np.exp(pd.to_numeric(out["coef"], errors="coerce"))
        out["rr_low"] = np.exp(pd.to_numeric(out["ci_low"], errors="coerce"))
        out["rr_high"] = np.exp(pd.to_numeric(out["ci_high"], errors="coerce"))
        return out[["label", "rr", "rr_low", "rr_high"]]

    a = _prep(a)
    b = _prep(b)

    # Mantém uma ordem estável, parecida com o paper-style
    order = [
        "Porte: Grande (vs Pequeno)",
        "Porte: Médio (vs Pequeno)",
        "Ano (tendência)",
        "Denúncias / 100 estab.",
        "Informalidade (proporção)",
    ]
    all_labels = list(dict.fromkeys(order + a["label"].astype(str).tolist() + b["label"].astype(str).tolist()))

    a = a.set_index("label").reindex(all_labels)
    b = b.set_index("label").reindex(all_labels)

    _apply_elsevier_style()

    # Altura proporcional ao número de linhas
    fig, ax = plt.subplots(figsize=(10.8, max(3.0, 0.55 * len(all_labels) + 0.8)))

    # Linha de nulidade
    ax.axvline(1.0, color="black", lw=1.0, ls=(0, (2, 2)))

    # Paleta do boxplot (analise_avancada.py): pastel3
    # Usar cores apenas nas caixas; manter whiskers/ICs neutros.
    pastel3 = ["#B3CDE3", "#CCEBC5", "#FBB4AE"]
    color_a = pastel3[0]  # M2
    color_b = pastel3[2]  # M3
    ci_color = "0.35"
    box_edge = "0.2"

    y0 = np.arange(len(all_labels))[::-1]
    dy = 0.14

    # Separadores horizontais entre blocos (após os portes)
    if "Porte: Médio (vs Pequeno)" in all_labels:
        sep_idx = all_labels.index("Porte: Médio (vs Pequeno)")
        sep_y = y0[sep_idx] - 0.55
        ax.axhline(sep_y, color="0.75", lw=1)

    def _draw_series(df: pd.DataFrame, *, y_shift: float, color: str, z: int):
        for i, lab in enumerate(all_labels):
            rr = df.iloc[i]["rr"]
            lo = df.iloc[i]["rr_low"]
            hi = df.iloc[i]["rr_high"]
            if not (np.isfinite(rr) and np.isfinite(lo) and np.isfinite(hi)):
                continue
            yy = y0[i] + y_shift
            ax.plot([lo, hi], [yy, yy], color=ci_color, lw=1.0)
            ax.scatter(
                [rr],
                [yy],
                marker="s",
                s=42,
                facecolor=color,
                edgecolor=box_edge,
                linewidth=0.8,
                zorder=z,
            )

    _draw_series(a, y_shift=+dy, color=color_a, z=3)
    _draw_series(b, y_shift=-dy, color=color_b, z=3)

    ax.set_yticks(y0)
    ax.set_yticklabels(all_labels)
    ax.set_xscale("log")
    ax.grid(False)
    if _fig_lang().startswith("en"):
        ax.set_xlabel("Rate ratio (RR = exp(coef), log scale)", fontsize=10, labelpad=8)
    else:
        ax.set_xlabel("Razão de taxas (RR = exp(coef), escala log)", fontsize=10, labelpad=8)
    ax.set_title(title, loc="left", pad=8, fontsize=11)
    ax.tick_params(axis="both", which="major", labelsize=9)

    # Limites do eixo X com base em ambas as séries
    lows = np.concatenate([a["rr_low"].to_numpy(dtype=float), b["rr_low"].to_numpy(dtype=float)])
    highs = np.concatenate([a["rr_high"].to_numpy(dtype=float), b["rr_high"].to_numpy(dtype=float)])
    lows = lows[np.isfinite(lows)]
    highs = highs[np.isfinite(highs)]
    xmin = float(np.min(lows)) * 0.85 if lows.size else 0.7
    xmax = float(np.max(highs)) * 1.25 if highs.size else 1.4
    ax.set_xlim(max(0.05, xmin), xmax)

    # Coluna de valores à direita (duas linhas por variável), alinhada aos quadrados.
    trans_y = ax.get_yaxis_transform()  # x em fração do eixo, y em dados
    if _fig_lang().startswith("en"):
        ax.text(1.01, 1.02, "RR (95% CI)", transform=ax.transAxes, ha="left", va="bottom", color="black", fontsize=9)
    else:
        ax.text(1.01, 1.02, "RR (IC95%)", transform=ax.transAxes, ha="left", va="bottom", color="black", fontsize=9)

    def _txt_at(i: int, df: pd.DataFrame) -> str | None:
        rr = df.iloc[i]["rr"]
        lo = df.iloc[i]["rr_low"]
        hi = df.iloc[i]["rr_high"]
        if not (np.isfinite(rr) and np.isfinite(lo) and np.isfinite(hi)):
            return None
        return f"{_fmt_num(rr, 2)} ({_fmt_num(lo, 2)}–{_fmt_num(hi, 2)})"

    for i, _lab in enumerate(all_labels):
        ta = _txt_at(i, a)
        tb = _txt_at(i, b)
        # RR em preto (cores só nas caixas); duas linhas para mapear cada quadrado
        if ta:
            ax.text(1.01, y0[i] + dy, ta, transform=trans_y, ha="left", va="center", color="black", fontsize=8)
        if tb:
            ax.text(1.01, y0[i] - dy, tb, transform=trans_y, ha="left", va="center", color="black", fontsize=8)

    # Legenda simples, sem moldura
    handles = [
        plt.Line2D(
            [0],
            [0],
            marker="s",
            linestyle="none",
            markerfacecolor=color_a,
            markeredgecolor=box_edge,
            markeredgewidth=0.8,
            markersize=7,
            label=label_a,
        ),
        plt.Line2D(
            [0],
            [0],
            marker="s",
            linestyle="none",
            markerfacecolor=color_b,
            markeredgecolor=box_edge,
            markeredgewidth=0.8,
            markersize=7,
            label=label_b,
        ),
    ]
    ax.legend(
        handles=handles,
        loc="lower center",
        bbox_to_anchor=(0.5, -0.38),
        ncol=2,
        frameon=False,
        fontsize=9,
        handletextpad=0.6,
        columnspacing=1.4,
    )

    # Reservar espaço para a coluna de texto + legenda abaixo do xlabel
    plt.subplots_adjust(right=0.72, bottom=0.34)

    os.makedirs(os.path.dirname(out_png), exist_ok=True)
    fig.savefig(out_png, dpi=300, bbox_inches="tight", facecolor="white")
    plt.close(fig)


def _forestplot_elsevier(tab: pd.DataFrame, *, title: str, out_png: str) -> None:
    t = tab.copy()
    t = t[t["term"].astype(str) != "Intercept"].copy()
    t = t[t["term"].astype(str) != "const"].copy()

    # RR e IC em escala original (exp)
    t["rr"] = np.exp(pd.to_numeric(t["coef"], errors="coerce"))
    t["rr_low"] = np.exp(pd.to_numeric(t["ci_low"], errors="coerce"))
    t["rr_high"] = np.exp(pd.to_numeric(t["ci_high"], errors="coerce"))

    t["label"] = t["term"].map(_term_label)

    # ordem de apresentação
    order = [
        "Densidade Pop.",
        "PIB per Capita",
        "Ano (tendência)",
        "Fiscalização Anterior",
        "Porte: Grande (vs Pequeno)",
        "Porte: Médio (vs Pequeno)",
        "Denúncias / 100 estab.",
        "Informalidade (proporção)",
    ]

    # mantém somente os labels existentes e ordena; o resto vai ao fim
    existing = [x for x in order if x in set(t["label"].astype(str))]
    rest = [x for x in t["label"].astype(str).tolist() if x not in existing]
    final_order = existing + sorted(set(rest))

    t["label"] = pd.Categorical(t["label"].astype(str), categories=final_order, ordered=True)
    t = t.sort_values("label", ascending=True).reset_index(drop=True)

    y = np.arange(len(t))[::-1]

    _apply_elsevier_style()

    fig, ax = plt.subplots(figsize=(7.4, max(2.6, 0.55 * len(t) + 0.9)))

    # linha de nulidade
    ax.axvline(1.0, color="black", lw=1.0, ls=(0, (2, 2)))

    # whiskers e quadrados
    for yi, lo, hi in zip(y, t["rr_low"], t["rr_high"]):
        if np.isfinite(lo) and np.isfinite(hi):
            ax.plot([lo, hi], [yi, yi], color="black", lw=1.0)

    ax.scatter(t["rr"], y, marker="s", s=36, color="black", zorder=3)

    ax.set_yticks(y)
    ax.set_yticklabels(t["label"].astype(str))

    # escala log no eixo X
    ax.set_xscale("log")

    # limites com folga
    xmin = float(np.nanmin(t["rr_low"])) if t["rr_low"].notna().any() else 0.8
    xmax = float(np.nanmax(t["rr_high"])) if t["rr_high"].notna().any() else 1.2
    xmin = max(0.05, xmin * 0.85)
    xmax = xmax * 1.25
    ax.set_xlim(xmin, xmax)

    # sem grid vertical
    ax.grid(False)

    ax.set_xlabel("Razão de taxas (exp(coef), escala log)")
    ax.set_title(title, loc="left", pad=8)

    # Coluna de valores numéricos alinhada à direita
    for yi, rr, lo, hi in zip(y, t["rr"], t["rr_low"], t["rr_high"]):
        txt = f"{_fmt_num_pt(rr, 2)} [{_fmt_num_pt(lo, 2)}–{_fmt_num_pt(hi, 2)}]"
        ax.text(
            1.01,
            yi,
            txt,
            transform=ax.get_yaxis_transform(),
            ha="left",
            va="center",
            color="black",
        )

    # reservar espaço para a coluna de texto
    plt.subplots_adjust(right=0.78)

    os.makedirs(os.path.dirname(out_png), exist_ok=True)
    fig.savefig(out_png, dpi=300, bbox_inches="tight", facecolor="white")
    plt.close(fig)


def _forestplot_paineis(
    tab_taxa: pd.DataFrame,
    tab_yield: pd.DataFrame,
    *,
    title_left: str,
    title_right: str,
    out_png: str,
) -> None:
    """Figura única com 2 painéis lado a lado (estilo small multiples), sem sobreposição."""

    def _prep(tab: pd.DataFrame) -> pd.DataFrame:
        t = tab.copy()
        t = t[~t["term"].astype(str).isin(["Intercept", "const"])].copy()
        t["rr"] = np.exp(pd.to_numeric(t["coef"], errors="coerce"))
        t["rr_low"] = np.exp(pd.to_numeric(t["ci_low"], errors="coerce"))
        t["rr_high"] = np.exp(pd.to_numeric(t["ci_high"], errors="coerce"))
        t["label"] = t["term"].map(_term_label)
        order = [
            "Porte: Grande (vs Pequeno)",
            "Porte: Médio (vs Pequeno)",
            "Ano (tendência)",
            "Denúncias / 100 estab.",
            "Informalidade (proporção)",
        ]
        existing = [x for x in order if x in set(t["label"].astype(str))]
        rest = [x for x in t["label"].astype(str).tolist() if x not in existing]
        final_order = existing + sorted(set(rest))
        t["label"] = pd.Categorical(t["label"].astype(str), categories=final_order, ordered=True)
        t = t.sort_values("label", ascending=True).reset_index(drop=True)
        return t

    t1 = _prep(tab_taxa)
    t2 = _prep(tab_yield)

    # Unificar ordem de linhas
    labels = list(dict.fromkeys(t1["label"].astype(str).tolist() + t2["label"].astype(str).tolist()))
    t1 = t1.set_index("label").reindex(labels).reset_index().rename(columns={"index": "label"})
    t2 = t2.set_index("label").reindex(labels).reset_index().rename(columns={"index": "label"})

    y = np.arange(len(labels))[::-1]

    _apply_elsevier_style()
    fig, (ax1, ax2) = plt.subplots(
        ncols=2,
        figsize=(10.6, max(3.2, 0.55 * len(labels) + 0.9)),
        sharey=True,
        gridspec_kw={"wspace": 0.10},
    )

    def _draw(ax, t: pd.DataFrame, *, panel_title: str):
        ax.axvline(1.0, color="black", lw=1.0, ls=(0, (2, 2)))
        for yi, lo, hi in zip(y, t["rr_low"], t["rr_high"]):
            if np.isfinite(lo) and np.isfinite(hi):
                ax.plot([lo, hi], [yi, yi], color="0.35", lw=1.0)
        ax.scatter(t["rr"], y, marker="s", s=28, facecolor="black", edgecolor="0.2", linewidth=0.6, zorder=3)
        ax.set_xscale("log")
        ax.grid(False)
        ax.set_title(panel_title, fontsize=10, pad=8)
        ax.tick_params(axis="x", labelsize=9)

    _draw(ax1, t1, panel_title=title_left)
    _draw(ax2, t2, panel_title=title_right)

    ax1.set_yticks(y)
    ax1.set_yticklabels(labels, fontsize=9)
    ax2.tick_params(axis="y", left=False, labelleft=False)

    # mesmos limites em ambos
    lows = np.concatenate([t1["rr_low"].to_numpy(dtype=float), t2["rr_low"].to_numpy(dtype=float)])
    highs = np.concatenate([t1["rr_high"].to_numpy(dtype=float), t2["rr_high"].to_numpy(dtype=float)])
    lows = lows[np.isfinite(lows)]
    highs = highs[np.isfinite(highs)]
    xmin = float(np.min(lows)) * 0.85 if lows.size else 0.7
    xmax = float(np.max(highs)) * 1.25 if highs.size else 1.4
    xmin = max(0.05, xmin)
    ax1.set_xlim(xmin, xmax)
    ax2.set_xlim(xmin, xmax)

    # xlabel único
    if _fig_lang().startswith("en"):
        fig.supxlabel("Rate ratio (RR = exp(coef), log scale)", fontsize=10, y=0.04)
    else:
        fig.supxlabel("Razão de taxas (RR = exp(coef), escala log)", fontsize=10, y=0.04)

    os.makedirs(os.path.dirname(out_png), exist_ok=True)
    fig.savefig(out_png, dpi=300, bbox_inches="tight", facecolor="white")
    plt.close(fig)


def main() -> None:
    base_repo = _resolver_base_repo()
    xlsx = os.path.join(base_repo, "1-DADOS", "FISCALIZAÇÃO", "Tabela_Final_(BACKUP 07012023).xlsx")

    suffix = "_en" if _fig_lang().startswith("en") else ""
    out_m2 = os.path.join(base_repo, "3 - FIGURAS", "PREDITIVO", f"forestplot_multinivel_M2{suffix}.png")
    out_m3 = os.path.join(base_repo, "3 - FIGURAS", "PREDITIVO", f"forestplot_multinivel_M3{suffix}.png")
    out_cmp = os.path.join(base_repo, "3 - FIGURAS", f"forestplot_multinivel_comparativo{suffix}.png")
    out_paineis = os.path.join(base_repo, "3 - FIGURAS", f"forestplot_multinivel_paineis{suffix}.png")
    out_resumo = os.path.join(base_repo, "4-ANALISES", "RESULTADOS_FOREST_EFEITO.md")

    raw = pd.read_excel(xlsx, sheet_name="Sheet1")
    df = raw.rename(columns={c: _norm_col(c) for c in raw.columns}).copy()

    df = df.dropna(subset=["ano", "municipio"]).copy()
    df["ano"] = pd.to_numeric(df["ano"], errors="coerce")
    df = df[df["ano"].notna()].copy()
    df["ano"] = df["ano"].astype(int)

    df["municipio"] = df["municipio"].astype(str).str.strip()

    # Variáveis base
    df["qtd_estab"] = pd.to_numeric(_col(df, "quantidade_de_estabelecimentos"), errors="coerce").fillna(0)
    df["total_visitas"] = pd.to_numeric(_col(df, "total_de_visitas"), errors="coerce").fillna(0)
    df["irreg"] = pd.to_numeric(_col(df, "visitas_irregulares"), errors="coerce").fillna(0)

    # Porte em 3 níveis
    pop = pd.to_numeric(_col(df, "populacao"), errors="coerce")
    if pop.notna().any():
        pop_ref = pop.fillna(pop.median())
        df["porte3"] = pd.cut(
            pop_ref,
            bins=[0, 20000, 100000, np.inf],
            labels=["Pequeno", "Médio", "Grande"],
        )
    else:
        df["porte3"] = "Pequeno"

    # Ano como tendência (centrado)
    df["ano_c"] = df["ano"] - int(df["ano"].min())

    # Covariáveis
    df["quantidade_de_denuncias"] = pd.to_numeric(_col(df, "quantidade_de_denuncias"), errors="coerce")
    df["quantidade_de_academias_nao_registradas"] = pd.to_numeric(
        _col(df, "quantidade_de_academias_nao_registradas"), errors="coerce"
    )

    denom_estab = df["qtd_estab"].replace(0, np.nan)
    df["denuncias_100_estab"] = 100 * (df["quantidade_de_denuncias"] / denom_estab)
    df["share_informal"] = (df["quantidade_de_academias_nao_registradas"] / denom_estab).clip(0, 1)

    # Outcomes (log-taxa)
    df["log_taxa_inspecao"] = _safe_log_rate(df["total_visitas"], df["qtd_estab"], add=0.5)
    df["log_yield"] = _safe_log_rate(df["irreg"], df["total_visitas"], add=0.5)

    m2 = df[(df["qtd_estab"] > 0) & df["log_taxa_inspecao"].notna()].copy()
    m3 = df[(df["total_visitas"] > 0) & df["log_yield"].notna()].copy()

    for d in (m2, m3):
        for c in ["denuncias_100_estab", "share_informal"]:
            med = float(np.nanmedian(d[c])) if d[c].notna().any() else 0.0
            d[c] = d[c].fillna(med)

    f_m2 = "log_taxa_inspecao ~ ano_c + C(porte3) + denuncias_100_estab + share_informal"
    f_m3 = "log_yield ~ ano_c + C(porte3) + denuncias_100_estab + share_informal"

    def _fit_mixed_or_cluster_ols(formula: str, data: pd.DataFrame):
        try:
            res = smf.mixedlm(formula, data, groups=data["municipio"]).fit(reml=False, method="lbfgs")
            return "MixedLM", res
        except Exception:
            ols = smf.ols(formula, data).fit(cov_type="cluster", cov_kwds={"groups": data["municipio"]})
            return "OLS (EP cluster)", ols

    kind_m2, res_m2 = _fit_mixed_or_cluster_ols(f_m2, m2)
    kind_m3, res_m3 = _fit_mixed_or_cluster_ols(f_m3, m3)

    # Tamanho de efeito (global): R2 + f^2
    r2m_m2, r2c_m2 = (None, None)
    r2m_m3, r2c_m3 = (None, None)

    if kind_m2.startswith("MixedLM"):
        r2m_m2, r2c_m2 = _mixedlm_r2_nakagawa(res_m2)
    else:
        r2m_m2 = _safe_float(getattr(res_m2, "rsquared", None))

    if kind_m3.startswith("MixedLM"):
        r2m_m3, r2c_m3 = _mixedlm_r2_nakagawa(res_m3)
    else:
        r2m_m3 = _safe_float(getattr(res_m3, "rsquared", None))

    f2_m2 = _cohen_f2_from_r2(r2m_m2)
    f2_m3 = _cohen_f2_from_r2(r2m_m3)

    tab_m2 = _extract_fixed_effects(res_m2)
    tab_m3 = _extract_fixed_effects(res_m3)

    _forestplot_elsevier(
        tab_m2,
        title=f"Forest plot – M2 Taxa de fiscalização (visitas/estab.) | {kind_m2}",
        out_png=out_m2,
    )
    _forestplot_elsevier(
        tab_m3,
        title=f"Forest plot – M3 Yield (irregulares/visita) | {kind_m3}",
        out_png=out_m3,
    )

    _forestplot_comparativo(
        tab_m2,
        tab_m3,
        label_a="Taxa de fiscalização (visitas/estab.)",
        label_b="Yield da fiscalização (irregulares/visita)",
        title="Forest plot comparativo (RR, IC95%)",
        out_png=out_cmp,
    )

    _forestplot_paineis(
        tab_m2,
        tab_m3,
        title_left="Taxa de fiscalização (visitas/estab.)",
        title_right="Yield da fiscalização (irregulares/visita)",
        out_png=out_paineis,
    )

    # Salvar resumo para o manuscrito
    def _fmt3(x: float | None) -> str:
        return "NA" if x is None else f"{x:.3f}".replace(".", ",")

    resumo = (
        "# Resumo — tamanho de efeito (modelos do forest plot)\n\n"
        "Métrica principal: $R^2$ marginal (Nakagawa) quando MixedLM; $R^2$ usual quando OLS.\n"
        "Tamanho de efeito global: $f^2 = R^2/(1-R^2)$.\n\n"
        f"- Taxa de fiscalização (visitas/estab.) | {kind_m2}: R2_marg={_fmt3(r2m_m2)}; R2_cond={_fmt3(r2c_m2)}; f2={_fmt3(f2_m2)}\n"
        f"- Yield da fiscalização (irregulares/visita) | {kind_m3}: R2_marg={_fmt3(r2m_m3)}; R2_cond={_fmt3(r2c_m3)}; f2={_fmt3(f2_m3)}\n"
    )
    try:
        with open(out_resumo, "w", encoding="utf-8") as f:
            f.write(resumo)
    except Exception:
        pass

    print(f"OK: salvou {out_m2}")
    print(f"OK: salvou {out_m3}")
    print(f"OK: salvou {out_cmp}")
    print(f"OK: salvou {out_paineis}")
    print(f"OK: salvou {out_resumo}")


if __name__ == "__main__":
    main()
