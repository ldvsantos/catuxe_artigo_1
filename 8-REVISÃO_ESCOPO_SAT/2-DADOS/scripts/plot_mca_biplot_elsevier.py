"""
MCA Biplot - Elsevier Style (Pastel Colors)
Replicates the logic of mca_temporal_biplot_completo.R using Python (prince).
Optimized for layout, label readability, and specific axis limits.
"""

import os

from typing import Dict, List

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import prince
from adjustText import adjust_text
from matplotlib.patches import Ellipse
import matplotlib.transforms as transforms
from scipy.stats import chi2

# --- Label density control ---
MAX_LABELS_TOTAL = 12
MAX_LABELS_PER_TEXT = 1

# --- Elsevier Visual Style ---
COLOR_ALGO = "#FBB4AE"  # Pastel Red
COLOR_INST = "#B3CDE3"  # Pastel Blue
COLOR_APP  = "#CCEBC5"  # Pastel Green
COLOR_OTHER = "#E0E0E0" # Light Gray
COLOR_PERIODS = {
    "2010-14": "#1B9E77",
    "2015-19": "#D95F02",
    "2020-25": "#7570B3"
}

def confidence_ellipse(x, y, ax, confidence: float = 0.95, facecolor='none', **kwargs):
    """Confidence ellipse usando covariância (alinhada ao eixo principal).

    - confidence segue a interpretação do ggplot2::stat_ellipse(level=...)
    - usa chi2(df=2) para escala
    """
    x = np.asarray(x, dtype=float)
    y = np.asarray(y, dtype=float)
    if x.size != y.size:
        raise ValueError("x and y must be the same size")
    if x.size < 3:
        return None

    cov = np.cov(x, y)
    if not np.all(np.isfinite(cov)):
        return None

    vals, vecs = np.linalg.eigh(cov)
    order = vals.argsort()[::-1]
    vals = vals[order]
    vecs = vecs[:, order]

    # Ângulo do maior autovetor
    angle = np.degrees(np.arctan2(vecs[1, 0], vecs[0, 0]))

    # Escala do raio pelo quantil chi2
    q = chi2.ppf(confidence, df=2)
    if not np.isfinite(q) or q <= 0:
        return None

    width, height = 2.0 * np.sqrt(vals * q)
    mean_x = float(np.mean(x))
    mean_y = float(np.mean(y))

    e = Ellipse((mean_x, mean_y), width=width, height=height, angle=angle, facecolor=facecolor, **kwargs)
    return ax.add_patch(e)


def _infer_tipo(df: pd.DataFrame) -> pd.Series:
    # Para SAT: prioriza Algoritmo > Evidencia > Aplicacao
    def _row_tipo(row) -> str:
        if str(row.get("Algoritmo", "Other")) != "Other":
            return "Algorithm"
        if str(row.get("Evidencia", "Other")) != "Other":
            return "Evidence"
        if str(row.get("Aplicacao", "Other")) != "Other":
            return "Application"
        return "Other"

    return df.apply(_row_tipo, axis=1)


def _rescale_individuals_to_bounds(
    coords_ind: pd.DataFrame,
    x_limit: float,
    y_min: float,
    y_max: float,
    margin: float = 0.97,
):
    # Reescala APENAS os indivíduos para preencher os limites definidos em X/Y.
    # Isso evita o efeito de "MCA minúsculo" quando o eixo é fixo.
    if len(coords_ind) == 0:
        return coords_ind, 1.0

    x = coords_ind[0].to_numpy(dtype=float)
    y = coords_ind[1].to_numpy(dtype=float)

    max_abs_x = float(np.nanmax(np.abs(x)))
    max_pos_y = float(np.nanmax(y))
    max_neg_y = float(np.nanmax(-y))  # magnitude do lado negativo

    scales = []
    if np.isfinite(max_abs_x) and max_abs_x > 0:
        scales.append((x_limit * margin) / max_abs_x)
    if np.isfinite(max_pos_y) and max_pos_y > 0:
        scales.append((y_max * margin) / max_pos_y)
    if np.isfinite(max_neg_y) and max_neg_y > 0:
        scales.append((abs(y_min) * margin) / max_neg_y)

    if not scales:
        return coords_ind, 1.0

    scale = float(min(scales))
    coords_ind[[0, 1]] = coords_ind[[0, 1]] * scale
    return coords_ind, scale


def _pick_label_examples(
    coords_ind: pd.DataFrame,
    label_col: str,
    max_total: int = MAX_LABELS_TOTAL,
    max_per_text: int = MAX_LABELS_PER_TEXT,
) -> pd.DataFrame:
    """Select a small set of representative points to label.

    Strategy:
    - avoid repeating the same label text too much
    - prefer points farther from origin (more legible, more informative)
    """
    if label_col not in coords_ind.columns or len(coords_ind) == 0:
        return coords_ind.iloc[0:0]

    tmp = coords_ind.copy()
    tmp[label_col] = tmp[label_col].astype(str)
    tmp = tmp[tmp[label_col].str.lower().ne("other")]
    if tmp.empty:
        return tmp

    tmp["_r2"] = (tmp[0].astype(float) ** 2) + (tmp[1].astype(float) ** 2)
    tmp = tmp.sort_values("_r2", ascending=False)

    selected_idx: List[int] = []
    used_counts: Dict[str, int] = {}

    for idx, row in tmp.iterrows():
        text = str(row[label_col]).strip()
        if not text:
            continue
        cnt = used_counts.get(text, 0)
        if cnt >= max_per_text:
            continue
        selected_idx.append(idx)
        used_counts[text] = cnt + 1
        if len(selected_idx) >= max_total:
            break

    return coords_ind.loc[selected_idx]

def main():
    # 1. Setup paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    input_csv = os.path.join(script_dir, "mca_dados_categorizados_sat.csv")
    output_png = os.path.join(script_dir, "..", "..", "2-FIGURAS", "2-EN", "mca_biplot_temporal_completo.png")
    
    # 2. Load Data
    if not os.path.exists(input_csv):
        raise FileNotFoundError(
            f"CSV não encontrado: {input_csv}. "
            "Gere o dataset SAT executando: python build_sat_mca_dataset.py"
        )

    df = pd.read_csv(input_csv)
    
    # MCA Variables
    cols_mca = ["Algoritmo", "Evidencia", "Contexto", "Aplicacao", "Regiao"]
    X = df[cols_mca]
    
    # 3. Perform MCA (using same random_state for consistency)
    mca = prince.MCA(
        n_components=2,
        n_iter=10,
        copy=True,
        check_input=True,
        engine='sklearn',
        random_state=42
    )
    mca = mca.fit(X)
    
    # Coordinates
    coords_ind = mca.row_coordinates(X)
    coords_var = mca.column_coordinates(X)

    # Metadados para plot (alinhados por índice)
    df = df.copy()
    df["Tipo"] = _infer_tipo(df)

    coords_ind["Periodo"] = df["Periodo"].values
    coords_ind["Tipo"] = df["Tipo"].values
    coords_ind["Contexto"] = df["Contexto"].values

    # Filter Outliers (Range X: [-4,4], Y: [-4,4] — filtro amplo; limites finais serão Y [-4,4])
    mask_ind = (coords_ind[0].abs() <= 4) & (coords_ind[1].abs() <= 4)
    outliers_count = int((~mask_ind).sum())
    if outliers_count > 0:
        print(f"Removed {outliers_count} outliers outside range [-4, 4]")
    coords_ind = coords_ind.loc[mask_ind].copy()
    
    # Reescala os indivíduos para preencher os limites finais: X [-4,4] e Y [-4,4]
    # Pequena folga para não colar rótulos/pontos no limite
    coords_ind, scale = _rescale_individuals_to_bounds(coords_ind, x_limit=4.0, y_min=-4.0, y_max=4.0, margin=0.92)
    if scale != 1.0:
        print(f"Applied individuals rescale factor: {scale:.3f}")

    # 4. Plot Config
    plt.style.use('default')
    plt.rcParams.update({
        "font.family": "serif",
        "font.size": 12,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "legend.frameon": False,
        # "figure.autolayout": False  # Handled by constrained_layout
    })
    
    # Proporção da figura alinhada aos limites (X=8 unidades, Y=6 unidades => 8/6 = 1.33)
    fig, ax = plt.subplots(figsize=(12, 9), constrained_layout=True)
    
    # Set explicit limits
    ax.set_xlim(-4, 4)
    ax.set_ylim(-4, 4)
    ax.set_aspect('equal', adjustable='box')
    
    # Grid
    ax.grid(True, linestyle=':', color='gray', alpha=0.5, zorder=0)
    ax.axhline(0, color='gray', linestyle='-', linewidth=0.8, zorder=1)
    ax.axvline(0, color='gray', linestyle='-', linewidth=0.8, zorder=1)
    
    # (A) Pontos dos estudos (como no script original R)
    tipo_style = {
        "Algorithm": {"marker": "o", "face": COLOR_ALGO},
        "Evidence": {"marker": "s", "face": COLOR_INST},
        "Application": {"marker": "^", "face": COLOR_APP},
        "Other": {"marker": "o", "face": COLOR_OTHER},
    }

    for tipo, st in tipo_style.items():
        sub = coords_ind[coords_ind["Tipo"] == tipo]
        if len(sub) == 0:
            continue
        ax.scatter(
            sub[0],
            sub[1],
            s=55,
            marker=st["marker"],
            facecolors=st["face"],
            edgecolors="black",
            linewidth=0.6,
            alpha=0.75,
            label=tipo,
            zorder=3,
        )

    # (B) Elipses por período (95% aprox), sobre os pontos
    periods = ["2010-14", "2015-19", "2020-25"]
    for p in periods:
        subset = coords_ind[coords_ind["Periodo"] == p]
        if len(subset) >= 3:
            confidence_ellipse(
                subset[0],
                subset[1],
                ax,
                confidence=0.95,
                edgecolor=COLOR_PERIODS.get(p, "gray"),
                linewidth=2.0,
                label=f"Period {p}",
                zorder=4,
            )

    # Observação: removemos os pontos de variáveis (coords_var) porque estavam em escala diferente
    # e deixavam a nuvem de estudos minúscula no centro quando o eixo é fixado em ±4.

    # (D) Rótulos de contexto: mostrar apenas alguns exemplos (evita repetição/poluição)
    texts_to_adjust = []
    label_points = _pick_label_examples(coords_ind, "Contexto")
    for _, row in label_points.iterrows():
        t = ax.text(
            row[0],
            row[1],
            str(row["Contexto"]),
            fontsize=9,
            fontweight="bold",
            color="black",
            zorder=6,
        )
        texts_to_adjust.append(t)
    
    # Axis Labels with variance
    if hasattr(mca, 'percentage_of_variance_'):
        expl_var = mca.percentage_of_variance_
        label_x = f"Dimension 1 ({expl_var[0]:.1f}%)"
        label_y = f"Dimension 2 ({expl_var[1]:.1f}%)"
    else:
        label_x = "Dimension 1"
        label_y = "Dimension 2"
        
    ax.set_xlabel(label_x, fontsize=12)
    ax.set_ylabel(label_y, fontsize=12)
    ax.set_title(
        "Biplot da MCA (SAT): Evolução Temporal (X ±4 | Y -4..4)",
        fontsize=14,
        fontweight='bold',
        pad=14,
    )

    # Optimize Label Placement
    if texts_to_adjust:
        print("Adjusting context labels...")
        adjust_text(
            texts_to_adjust,
            ax=ax,
            expand=(1.10, 1.15),
            force_text=(0.15, 0.20),
            force_static=(0.10, 0.10),
            time_lim=2.5,
            ensure_inside_axes=True,
            verbose=False,
        )

    # Legenda única (Tipo + Período juntos)
    handles, labels = ax.get_legend_handles_labels()
    by_label = dict(zip(labels, handles))

    tipo_order = ["Algorithm", "Evidence", "Application", "Other"]
    period_order = [f"Period {p}" for p in ["2010-14", "2015-19", "2020-25"]]
    ordered = [k for k in (tipo_order + period_order) if k in by_label]

    ax.legend(
        [by_label[k] for k in ordered],
        ordered,
        loc="upper left",
        title="Tipo / Período",
        fontsize=10,
        title_fontsize=11,
    )

    # Save
    plt.savefig(output_png, dpi=300)
    print(f"Figure saved to {output_png}")

if __name__ == "__main__":
    main()
