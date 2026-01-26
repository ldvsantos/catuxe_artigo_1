"""
Painel FAIR (Radar + Barras) no estilo Elsevier/Manuscrito.
Reproduz a figura composta (a) Radar e (b) Indicadores com estilo visual padronizado.

Entradas:
- scores_por_dimensao_sat.csv (para o Radar)
- indicadores_fair_detalhados_sat.csv (para o Bar plot)

Saída:
- fair_radar_2.png
"""

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
from math import pi

# Configuração de estilo
plt.rcParams.update({
    "figure.dpi": 300,
    "savefig.dpi": 300,
    "font.family": "serif",
    "font.size": 11,
    "axes.facecolor": "white",
    "figure.facecolor": "white",
    "axes.spines.top": False,
    "axes.spines.right": False,
    "axes.grid": False,
})

# Cores e padrões
COLOR_RADAR_FILL = "#CCEBC5"  # Pastel Green
COLOR_RADAR_LINE = "#4CAF50"  # Darker Green
COLOR_BAR_FACE = "#B3CDE3"    # Pastel Blue
COLOR_BAR_EDGE = "0.2"
HATCH_PATTERN = "//////"

def _load_data(script_dir):
    # SAT-only source (built from BibTeX): build_sat_fair_dataset.py
    radar_csv = os.path.join(script_dir, "scores_por_dimensao_sat.csv")
    bar_csv = os.path.join(script_dir, "indicadores_fair_detalhados_sat.csv")
    
    if not os.path.exists(radar_csv) or not os.path.exists(bar_csv):
        raise FileNotFoundError(
            "Arquivos CSV SAT de dados não encontrados. Rode build_sat_fair_dataset.py"
        )
        
    df_radar = pd.read_csv(radar_csv)
    df_bar = pd.read_csv(bar_csv)
    return df_radar, df_bar

def plot_radar(ax, df):
    # Preparar dados circularmente
    categories = df['dimensao'].tolist()
    
    values = df['percentual'].tolist()
    
    # Fechar o ciclo
    values += values[:1]
    angles = [n / float(len(categories)) * 2 * pi for n in range(len(categories))]
    angles += angles[:1]
    
    # Eixo polar
    ax.set_theta_offset(pi / 2)
    ax.set_theta_direction(-1)
    
    # Rótulos do eixo X (categorias)
    ax.set_xticks(angles[:-1])
    ax.set_xticklabels(categories, color='black', size=11)
    # Afastar os labels do centro para não encavalar
    ax.tick_params(axis='x', pad=10)

    # Ajuste fino de rotação/alinhamento para evitar cortes e quebras feias
    for label, angle in zip(ax.get_xticklabels(), angles[:-1], strict=False):
        text = label.get_text()
        # Impede que o texto do radar "vaze" por cima do painel (b)
        label.set_clip_on(True)
        if text in {"Accessible", "Reusable"}:
            label.set_rotation(90)
            label.set_rotation_mode("anchor")
            label.set_ha("center")
            label.set_va("center")
        else:
            # rotação tangencial suave (mantém Interoperable íntegro)
            rot = np.degrees(angle) - 90
            label.set_rotation(rot)
            label.set_rotation_mode("anchor")
            label.set_ha("center")
            label.set_va("center")
    
    # Rótulos do eixo Y & Grid
    # Mover labels radiais para um ângulo mais limpo (ex: 45 graus)
    ax.set_rlabel_position(45)
    plt.yticks([20, 40, 60, 80, 100], ["20%", "40%", "60%", "80%", ""], color="grey", size=8)
    plt.ylim(0, 100)
    
    # Grid manual circular (opcional, o default do polar já é bom, mas vamos customizar se preciso)
    ax.yaxis.grid(True, linestyle=(0, (5, 5)), color="0.8")
    ax.xaxis.grid(True, linestyle="-", color="0.8")
    ax.spines["polar"].set_visible(False) # Remove círculo externo forte

    # Plot
    ax.plot(angles, values, linewidth=1.5, linestyle='solid', color=COLOR_RADAR_LINE)
    ax.fill(angles, values, color=COLOR_RADAR_FILL, alpha=0.6)
    
    # Title (tag externa será colocada no Axes superior)
    # ax.set_title("(a) FAIR Dimensions Compliance", y=1.1, fontsize=11, fontweight="bold")


def plot_bars(ax, df):
    # Remover indicadores sem evidência (n=0)
    if "n_sim" in df.columns:
        df = df[df["n_sim"].fillna(0).astype(int) > 0].copy()

    # Ordenar por percentual
    df = df.sort_values("percentual", ascending=True).reset_index(drop=True)
    
    # Dados
    names = df['indicador_en'].tolist()
    values = df['percentual'].tolist()
    n_sim = df['n_sim'].tolist()
    
    y_pos = np.arange(len(names))
    
    # Barras
    rects = ax.barh(y_pos, values, align='center', height=0.7,
                    color=COLOR_BAR_FACE, edgecolor=COLOR_BAR_EDGE,
                    hatch=HATCH_PATTERN, linewidth=0.8)
    
    # Eixos
    ax.set_yticks(y_pos)
    ax.set_yticklabels(names, fontsize=10)
    ax.set_xlabel("Compliance rate (%)", fontsize=10, labelpad=8)
    ax.set_xlim(0, 115) # Espaço para rótulos
    
    # Grid vertical apenas
    ax.xaxis.grid(True, linestyle=(0, (5, 5)), color="0.85", zorder=0)
    ax.set_axisbelow(True)
    
    # Rótulos de valor
    for i, rect in enumerate(rects):
        width = rect.get_width()
        label_text = f"{values[i]:.1f}%\n(n={n_sim[i]})"
        ax.text(width + 2, rect.get_y() + rect.get_height()/2, label_text,
                ha='left', va='center', fontsize=9, color='black')
    
    # Title
    # ax.set_title("(b) Individual Indicators", loc="left", fontsize=11, fontweight="bold")


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sat_root = os.path.abspath(os.path.join(script_dir, "..", ".."))
    fig_dir_en = os.path.join(sat_root, "2-FIGURAS", "2-EN")
    
    # Carregar dados
    df_radar, df_bar = _load_data(script_dir)
    
    fig = plt.figure(figsize=(14, 6))
    
    # GridSpec: aumentar wspace para afastar os painéis
    gs = fig.add_gridspec(1, 2, width_ratios=[1, 1.35], wspace=0.55)
    
    # (a) Radar
    ax1 = fig.add_subplot(gs[0, 0], polar=True)
    plot_radar(ax1, df_radar)

    # Tag (a) dentro do próprio painel
    ax1.text(
        -0.08,
        1.08,
        "(a)",
        transform=ax1.transAxes,
        fontsize=12,
        fontweight="bold",
        va="top",
        ha="left",
    )
    
    # (b) Barras
    ax2 = fig.add_subplot(gs[0, 1])
    plot_bars(ax2, df_bar)

    # Tag (b) dentro do próprio painel
    ax2.text(
        -0.08,
        1.04,
        "(b)",
        transform=ax2.transAxes,
        fontsize=12,
        fontweight="bold",
        va="top",
        ha="left",
    )
    
    # Espaço extra nas margens
    plt.subplots_adjust(left=0.05, right=0.95, top=0.85, bottom=0.1)
    
    # Salvar
    out_png = os.path.join(fig_dir_en, "fair_radar_2.png")
    os.makedirs(fig_dir_en, exist_ok=True)

    fig.savefig(out_png, dpi=300, bbox_inches="tight", pad_inches=0.2, facecolor="white")
    print(f"✓ Figura salva em: {out_png}")

if __name__ == "__main__":
    main()
