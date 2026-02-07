"""Gera louvain_modules_detailed.png (módulos Louvain detalhados) para o corpus SAT.

Este script substitui o pipeline antigo em R (scripts/OLD/05_louvain_communities_viz.R)
mantendo a ideia central do gráfico:
- Seleciona os 3 maiores módulos (comunidades) detectados por Louvain.
- Plota 3 painéis (um por módulo), com arestas ponderadas e nós rotulados.
- Aplica paleta e estilo compatíveis com as demais figuras de rede do artigo.

Entrada:
- 8-REVISÃO_ESCOPO_SAT/2-DADOS/scripts/mca_dados_categorizados_sat.csv

Saída:
- 8-REVISÃO_ESCOPO_SAT/2-FIGURAS/2-EN/louvain_modules_detailed.png
"""

from __future__ import annotations

from itertools import combinations
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Tuple

import matplotlib.pyplot as plt
import networkx as nx
import numpy as np
import pandas as pd
from matplotlib.patches import Patch


# Elsevier-like pastel palette (consistent with plot_network_sat_elsevier.py)
PASTEL = {
    "blue": "#8CB7D9",
    "green": "#9FD1AE",
    "orange": "#F2C38F",
    "pink": "#E7A6B8",
    "purple": "#B8A7D9",
    "teal": "#8FD3D1",
    "gray": "#9AA0A6",
}

# PT→EN dimension label mapping
DIM_EN = {
    "Algoritmo": "Algorithm",
    "Evidencia": "Evidence",
    "Contexto": "Context",
    "Aplicacao": "Application",
    "Regiao": "Region",
}


def _node_dim(node: str) -> str:
    return node.split(":", 1)[0].strip() if ":" in node else ""


def _node_label(node: str) -> str:
    return node.split(":", 1)[1].strip() if ":" in node else node


def dim_color_map(dims: Sequence[str]) -> Dict[str, str]:
    # Prefer a stable mapping across figures.
    preferred = ["Algoritmo", "Evidencia", "Aplicacao", "Contexto", "Regiao"]
    ordered = [d for d in preferred if d in dims] + [d for d in dims if d not in preferred]
    palette = [PASTEL["blue"], PASTEL["orange"], PASTEL["green"], PASTEL["purple"], PASTEL["pink"], PASTEL["teal"], PASTEL["gray"]]
    return {d: palette[i % len(palette)] for i, d in enumerate(ordered)}


def _clean_value(value: object) -> str | None:
    if value is None:
        return None
    if isinstance(value, float) and np.isnan(value):
        return None
    text = str(value).strip()
    if not text or text.lower() in {"nan", "none", "na", "n/a"}:
        return None
    return text


def build_cooccurrence_graph(
    df: pd.DataFrame,
    dimensions: Iterable[str],
    min_edge_weight: int = 3,
) -> nx.Graph:
    dims = list(dimensions)
    missing = [d for d in dims if d not in df.columns]
    if missing:
        raise ValueError(f"Colunas ausentes no CSV: {missing}")

    counts: Dict[Tuple[str, str], int] = {}

    for _, row in df.iterrows():
        nodes: List[str] = []
        for dim in dims:
            v = _clean_value(row[dim])
            if v is None:
                continue
            nodes.append(f"{dim}: {v}")

        nodes = list(dict.fromkeys(nodes))
        if len(nodes) < 2:
            continue

        for a, b in combinations(nodes, 2):
            u, v = sorted((a, b))
            counts[(u, v)] = counts.get((u, v), 0) + 1

    g = nx.Graph()
    for (a, b), w in counts.items():
        if w >= min_edge_weight:
            g.add_edge(a, b, weight=w)

    return g


def largest_connected_subgraph(g: nx.Graph) -> nx.Graph:
    if g.number_of_nodes() == 0:
        return g.copy()
    if nx.is_connected(g):
        return g.copy()
    comp = max(nx.connected_components(g), key=len)
    return g.subgraph(comp).copy()


def compute_louvain_communities(g: nx.Graph) -> Dict[str, int]:
    if g.number_of_nodes() == 0:
        return {}

    gc = largest_connected_subgraph(g)

    # NetworkX 3.5 has Louvain built-in.
    comms = list(nx.algorithms.community.louvain_communities(gc, weight="weight", seed=7))

    node_to_comm: Dict[str, int] = {}
    for i, comm in enumerate(comms, start=1):
        for n in comm:
            node_to_comm[n] = i

    for n in g.nodes:
        node_to_comm.setdefault(n, 0)
    return node_to_comm


def _infer_module_theme(node_labels: Sequence[str]) -> str:
    """Infer a primary theme label used as panel title.

    For this manuscript we keep the title minimal and stable: either
    'Deep learning', 'Classical ML', or 'Mixed'. This avoids duplicated titles
    like 'Classical ML & ...' that complicate (a)/(b) subpanel interpretation.
    """

    x = " ".join(s.lower() for s in node_labels)

    def has(pattern: str) -> bool:
        import re

        return re.search(pattern, x) is not None

    is_deep = has(r"\bdeep\b|neural|cnn|lstm|transformer")
    is_classical = has(r"svm|\bknn\b|random ?forest|decision ?tree|gradient ?boost|xgboost")

    if is_deep and not is_classical:
        return "Deep learning"
    if is_classical and not is_deep:
        return "Classical ML"
    if is_deep and is_classical:
        # Prefer to classify as Mixed to avoid ambiguity.
        return "Mixed"
    return "Mixed"


def _top_k_nodes_by_degree(g: nx.Graph, k: int) -> List[str]:
    deg = dict(g.degree(weight="weight"))
    return [n for n, _ in sorted(deg.items(), key=lambda kv: kv[1], reverse=True)[:k]]


def _draw_module(ax: plt.Axes, g: nx.Graph, title: str, dim_colors: Dict[str, str]) -> None:
    ax.set_title(title, fontsize=14, fontweight="bold")
    ax.axis("off")
    # Prevent stretching/distortion of the network layout
    ax.set_aspect("equal")

    if g.number_of_nodes() == 0:
        return

    # Layout similar to ggraph(layout="stress"); kamada-kawai is a close analogue.
    try:
        pos = nx.kamada_kawai_layout(g, weight="weight")
    except Exception:
        pos = nx.spring_layout(g, seed=7, weight="weight")

    weights = np.array([g.edges[e].get("weight", 1.0) for e in g.edges], dtype=float)
    if weights.size:
        w_ptp = float(np.ptp(weights))
        edge_widths = 0.8 + 2.7 * (weights - float(weights.min())) / (w_ptp if w_ptp else 1.0)
        edge_alphas = 0.25 + 0.45 * (weights - float(weights.min())) / (w_ptp if w_ptp else 1.0)
    else:
        edge_widths = []
        edge_alphas = []

    nx.draw_networkx_edges(
        g,
        pos,
        ax=ax,
        width=edge_widths,
        alpha=edge_alphas,
        edge_color="#6B6B6B",
    )

    deg_vals = np.array([float(g.degree(n, weight="weight")) for n in g.nodes], dtype=float)
    max_deg = float(deg_vals.max()) if deg_vals.size else 0.0
    node_sizes = 220 + 980 * (deg_vals / max_deg if max_deg else deg_vals)

    node_colors = [dim_colors.get(_node_dim(n), PASTEL["gray"]) for n in g.nodes]
    nx.draw_networkx_nodes(
        g,
        pos,
        ax=ax,
        node_size=node_sizes,
        node_color=node_colors,
        edgecolors="white",
        linewidths=1.0,
        alpha=0.95,
    )

    # Labels: show all if small; otherwise only the most central.
    if g.number_of_nodes() <= 26:
        label_nodes = list(g.nodes)
        font_size = 10
    else:
        label_nodes = _top_k_nodes_by_degree(g, k=20)
        font_size = 10

    labels = {n: _node_label(n) for n in label_nodes}
    nx.draw_networkx_labels(
        g,
        pos,
        labels=labels,
        font_size=font_size,
        font_color="#222222",
        font_weight="bold",
        ax=ax,
    )


def _add_panel_tag(ax: plt.Axes, tag: str) -> None:
    ax.text(
        0.01,
        0.99,
        tag,
        transform=ax.transAxes,
        ha="left",
        va="top",
        fontsize=12,
        fontweight="bold",
        color="#111111",
    )


def main() -> None:
    script_dir = Path(__file__).resolve().parent
    input_csv = script_dir / "mca_dados_categorizados_sat.csv"
    out_png = (script_dir / ".." / ".." / "2-FIGURAS" / "2-EN" / "louvain_modules_detailed.png").resolve()

    if not input_csv.exists():
        raise FileNotFoundError(
            f"CSV não encontrado: {input_csv}. Rode build_sat_mca_dataset.py primeiro."
        )

    df = pd.read_csv(input_csv)

    # Dimensões coerentes com o artigo/rede SAT
    dims = ["Algoritmo", "Evidencia", "Aplicacao", "Regiao", "Contexto"]

    # No pipeline antigo: min_coocorrencia = 3
    g_full = build_cooccurrence_graph(df, dims, min_edge_weight=3)
    if g_full.number_of_nodes() == 0:
        raise RuntimeError("Grafo vazio; verifique o CSV ou reduza min_edge_weight.")

    node_to_comm = compute_louvain_communities(g_full)
    comm_ids = sorted({cid for cid in node_to_comm.values() if cid > 0})
    if not comm_ids:
        raise RuntimeError("Falha ao detectar comunidades Louvain (nenhuma comunidade encontrada).")

    # Select the 3 largest modules by node count.
    comm_sizes = {cid: sum(1 for n in g_full.nodes if node_to_comm.get(n, 0) == cid) for cid in comm_ids}
    largest_comms = [cid for cid, _ in sorted(comm_sizes.items(), key=lambda kv: kv[1], reverse=True)[:3]]

    modules: List[nx.Graph] = []
    titles: List[str] = []
    
    for i, cid in enumerate(largest_comms, 1):
        nodes = [n for n in g_full.nodes if node_to_comm.get(n, 0) == cid]
        g_mod = g_full.subgraph(nodes).copy()
        g_mod.remove_nodes_from(list(nx.isolates(g_mod)))
        if g_mod.number_of_nodes() == 0:
            continue
        
        # Generate title based on module content
        top_labels = [_node_label(n) for n in _top_k_nodes_by_degree(g_mod, k=min(5, g_mod.number_of_nodes()))]
        theme = _infer_module_theme(top_labels)
        
        # Avoid "Classical ML" label, use generic "Module" instead
        if theme == "Classical ML":
            title = f"Technology Module {i}"
        elif theme == "Deep learning":
            title = "Deep Learning Module"
        else:
            title = f"Module {i}"
        
        modules.append(g_mod)
        titles.append(title)

    dim_colors = dim_color_map(dims)

    plt.rcParams.update(
        {
            "figure.dpi": 600,
            "savefig.dpi": 600,
            "font.family": "sans-serif",
            "font.size": 11,
            "axes.facecolor": "white",
            "figure.facecolor": "white",
        }
    )

    out_png.parent.mkdir(parents=True, exist_ok=True)

    # Adjusted figsize for 2 panels to avoid stretching (13x7 is roughly 2 squares side-by-side)
    fig, axes = plt.subplots(1, len(modules), figsize=(13, 7))
    fig.suptitle("Technological Modules Identified", fontsize=16, fontweight="bold", y=0.98)

    if len(modules) == 1:
        axes = [axes]

    for ax, g_mod, title in zip(axes, modules, titles, strict=False):
        _draw_module(ax, g_mod, title=title, dim_colors=dim_colors)
        # Panel tags removed as per user request

    # Shared legend (dimension -> color)
    present_dims = sorted({_node_dim(n) for n in g_full.nodes if _node_dim(n)})
    preferred_order = ["Algoritmo", "Evidencia", "Aplicacao", "Contexto", "Regiao"]
    present_dims = sorted(present_dims, key=lambda d: preferred_order.index(d) if d in preferred_order else 999)
    handles = [Patch(facecolor=dim_colors.get(d, PASTEL["gray"]), edgecolor="none", label=DIM_EN.get(d, d)) for d in present_dims]
    leg = fig.legend(
        handles=handles,
        title="Node dimension",
        loc="lower center",
        ncol=min(5, len(handles)) if handles else 1,
        frameon=True,
        framealpha=0.92,
        bbox_to_anchor=(0.5, 0.03),
    )
    if leg:
        leg.get_frame().set_edgecolor("#DDDDDD")

    fig.tight_layout(rect=[0.02, 0.08, 0.98, 0.93])
    fig.savefig(out_png, bbox_inches="tight", facecolor="white")
    plt.close(fig)

    print(f"✓ Figura salva em: {out_png}")


if __name__ == "__main__":
    main()
