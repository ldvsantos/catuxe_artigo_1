"""SAT-only Network figures (Elsevier-style).

Builds co-occurrence networks from the SAT MCA categorical dataset:
  - mca_dados_categorizados_sat.csv

Outputs (overwrites) the four PNGs referenced by LaTeX pipeline:
  - ../../2-FIGURAS/2-EN/network_completa.png
  - ../../2-FIGURAS/2-EN/network_communities.png
  - ../../2-FIGURAS/2-EN/network_algoritmo_produto.png  (now Algorithm × Application)
  - ../../2-FIGURAS/2-EN/network_centrality_metrics.png

Design note:
- We intentionally avoid any hard-coded “product/authentication” taxonomy.
- Nodes are category-values: e.g., "Algorithm: RandomForest".

Run:
  python plot_network_sat_elsevier.py
"""

from __future__ import annotations

from dataclasses import dataclass
from itertools import combinations
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

import matplotlib.pyplot as plt
import networkx as nx
import numpy as np
import pandas as pd


# Elsevier-like pastel palette (consistent with prior figure work)
PASTEL = {
    "blue": "#8CB7D9",
    "green": "#9FD1AE",
    "orange": "#F2C38F",
    "pink": "#E7A6B8",
    "purple": "#B8A7D9",
    "teal": "#8FD3D1",
    "gray": "#9AA0A6",
}


@dataclass(frozen=True)
class Paths:
    root: Path

    @property
    def input_csv(self) -> Path:
        return self.root / "mca_dados_categorizados_sat.csv"

    @property
    def out_dir_fig(self) -> Path:
        return (self.root / "../../2-FIGURAS/2-EN").resolve()

    @property
    def out_network_full(self) -> Path:
        return self.out_dir_fig / "network_completa.png"

    @property
    def out_network_communities(self) -> Path:
        return self.out_dir_fig / "network_communities.png"

    @property
    def out_network_algo_prod(self) -> Path:
        return self.out_dir_fig / "network_algoritmo_produto.png"

    @property
    def out_network_metrics(self) -> Path:
        return self.out_dir_fig / "network_centrality_metrics.png"


def _clean_value(value: object) -> str | None:
    if value is None:
        return None
    if isinstance(value, float) and np.isnan(value):
        return None
    text = str(value).strip()
    if not text or text.lower() in {"nan", "none", "na", "n/a"}:
        return None
    return text


def load_sat_mca_table(csv_path: Path) -> pd.DataFrame:
    df = pd.read_csv(csv_path)
    # Normalize whitespace
    for c in df.columns:
        if df[c].dtype == object:
            df[c] = df[c].astype(str).str.strip()
    return df


def build_cooccurrence_graph(
    df: pd.DataFrame,
    dimensions: Iterable[str],
    min_edge_weight: int = 3,
) -> nx.Graph:
    dims = list(dimensions)
    missing = [d for d in dims if d not in df.columns]
    if missing:
        raise ValueError(f"Missing columns in input CSV: {missing}")

    counts: Dict[Tuple[str, str], int] = {}

    for _, row in df.iterrows():
        nodes: List[str] = []
        for dim in dims:
            v = _clean_value(row[dim])
            if v is None:
                continue
            nodes.append(f"{dim}: {v}")

        # de-duplicate within a row
        nodes = list(dict.fromkeys(nodes))
        if len(nodes) < 2:
            continue

        for a, b in combinations(sorted(nodes), 2):
            counts[(a, b)] = counts.get((a, b), 0) + 1

    g = nx.Graph()
    for (a, b), w in counts.items():
        if w >= min_edge_weight:
            g.add_edge(a, b, weight=w)

    return g


def build_bipartite_graph(
    df: pd.DataFrame,
    left_dim: str,
    right_dim: str,
    min_edge_weight: int = 2,
) -> nx.Graph:
    if left_dim not in df.columns or right_dim not in df.columns:
        raise ValueError(f"Expected columns {left_dim!r} and {right_dim!r} in input CSV")

    counts: Dict[Tuple[str, str], int] = {}

    for _, row in df.iterrows():
        left = _clean_value(row[left_dim])
        right = _clean_value(row[right_dim])
        if left is None or right is None:
            continue
        a = f"{left_dim}: {left}"
        b = f"{right_dim}: {right}"
        counts[(a, b)] = counts.get((a, b), 0) + 1

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


def compute_communities(g: nx.Graph) -> Dict[str, int]:
    if g.number_of_nodes() == 0:
        return {}

    gc = largest_connected_subgraph(g)
    # Greedy modularity is stable and avoids extra deps
    comms = list(nx.algorithms.community.greedy_modularity_communities(gc, weight="weight"))
    node_to_comm: Dict[str, int] = {}
    for i, comm in enumerate(comms, start=1):
        for n in comm:
            node_to_comm[n] = i

    # Nodes outside largest component get 0
    for n in g.nodes:
        node_to_comm.setdefault(n, 0)

    return node_to_comm


def node_type(node: str) -> str:
    # "Dim: Value" -> Dim
    if ":" in node:
        return node.split(":", 1)[0].strip()
    return "Other"


def dim_color_map(dims: List[str]) -> Dict[str, str]:
    colors = [
        PASTEL["blue"],
        PASTEL["green"],
        PASTEL["orange"],
        PASTEL["purple"],
        PASTEL["pink"],
        PASTEL["teal"],
        PASTEL["gray"],
    ]
    m: Dict[str, str] = {}
    for i, d in enumerate(dims):
        m[d] = colors[i % len(colors)]
    return m


def draw_network(
    g: nx.Graph,
    out_path: Path,
    title: str,
    color_mode: str,
    dim_colors: Dict[str, str] | None = None,
    node_to_comm: Dict[str, int] | None = None,
    seed: int = 7,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)

    if g.number_of_nodes() == 0:
        raise RuntimeError("Graph has 0 nodes after filtering; lower min_edge_weight or verify input.")

    # Layout on largest component for stability; then map back
    gc = largest_connected_subgraph(g)
    pos_gc = nx.spring_layout(gc, seed=seed, k=None, weight="weight")
    pos = {n: pos_gc.get(n, (0.0, 0.0)) for n in g.nodes}

    degrees = dict(g.degree())
    weights = [g.edges[e].get("weight", 1) for e in g.edges]
    max_w = max(weights) if weights else 1

    # Node sizes
    deg_vals = np.array([degrees.get(n, 0) for n in g.nodes], dtype=float)
    node_sizes = 60 + 45 * np.sqrt(deg_vals)

    # Node colors
    if color_mode == "dimension":
        if dim_colors is None:
            raise ValueError("dim_colors is required when color_mode='dimension'")
        node_colors = [dim_colors.get(node_type(n), PASTEL["gray"]) for n in g.nodes]
    elif color_mode == "community":
        if node_to_comm is None:
            raise ValueError("node_to_comm is required when color_mode='community'")
        # community palette
        comm_ids = sorted(set(node_to_comm.values()))
        comm_palette = [
            PASTEL["blue"],
            PASTEL["green"],
            PASTEL["orange"],
            PASTEL["purple"],
            PASTEL["pink"],
            PASTEL["teal"],
            PASTEL["gray"],
        ]
        comm_color = {cid: comm_palette[i % len(comm_palette)] for i, cid in enumerate(comm_ids)}
        node_colors = [comm_color.get(node_to_comm.get(n, 0), PASTEL["gray"]) for n in g.nodes]
    else:
        raise ValueError(f"Unknown color_mode: {color_mode}")

    fig = plt.figure(figsize=(12.5, 10.0), dpi=600)
    ax = fig.add_subplot(111)
    ax.set_title(title, fontsize=16, fontweight="bold")
    ax.axis("off")

    # Edges
    edge_alphas = [0.15 + 0.70 * (w / max_w) for w in weights]
    edge_widths = [0.6 + 2.4 * (w / max_w) for w in weights]

    nx.draw_networkx_edges(
        g,
        pos,
        ax=ax,
        width=edge_widths,
        alpha=edge_alphas,
        edge_color="#4D4D4D",
    )

    nx.draw_networkx_nodes(
        g,
        pos,
        ax=ax,
        node_size=node_sizes,
        node_color=node_colors,
        linewidths=0.6,
        edgecolors="white",
        alpha=0.95,
    )

    # Labels: only top nodes by degree to reduce clutter
    top_n = 18
    top_nodes = [n for n, _ in sorted(degrees.items(), key=lambda kv: kv[1], reverse=True)[:top_n]]
    labels = {n: n.split(":", 1)[1].strip() if ":" in n else n for n in top_nodes}

    nx.draw_networkx_labels(
        g,
        pos,
        labels=labels,
        font_size=10,
        font_color="#222222",
        font_weight="bold",
        ax=ax,
    )

    fig.tight_layout()
    fig.savefig(out_path, facecolor="white", bbox_inches="tight")
    plt.close(fig)


def plot_centrality_metrics(g: nx.Graph, out_path: Path, title: str = "Centrality metrics (Top nodes)") -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)

    if g.number_of_nodes() == 0:
        raise RuntimeError("Graph has 0 nodes; cannot compute centrality metrics")

    gc = largest_connected_subgraph(g)

    deg = dict(gc.degree())
    bet = nx.betweenness_centrality(gc, weight="weight", normalized=True)
    clo = nx.closeness_centrality(gc)

    try:
        eig = nx.eigenvector_centrality(gc, weight="weight", max_iter=2000)
    except Exception:
        eig = {n: 0.0 for n in gc.nodes}

    def top(series: Dict[str, float], k: int = 12) -> List[Tuple[str, float]]:
        return sorted(series.items(), key=lambda kv: kv[1], reverse=True)[:k]

    top_deg = top({k: float(v) for k, v in deg.items()})
    top_bet = top(bet)
    top_clo = top(clo)
    top_eig = top(eig)

    panels = [
        ("Degree", top_deg, PASTEL["blue"]),
        ("Betweenness", top_bet, PASTEL["orange"]),
        ("Closeness", top_clo, PASTEL["green"]),
        ("Eigenvector", top_eig, PASTEL["purple"]),
    ]

    fig, axes = plt.subplots(2, 2, figsize=(14, 10), dpi=600)
    fig.suptitle(title, fontsize=16, fontweight="bold")

    for ax, (name, items, color) in zip(axes.ravel(), panels, strict=False):
        labels = [n.split(":", 1)[1].strip() if ":" in n else n for n, _ in items]
        values = [v for _, v in items]

        y = np.arange(len(labels))
        ax.barh(y, values, color=color, alpha=0.9)
        ax.set_yticks(y)
        ax.set_yticklabels(labels, fontsize=10)
        ax.invert_yaxis()
        ax.set_title(name, fontsize=12, fontweight="bold")
        ax.grid(axis="x", alpha=0.25)

    fig.tight_layout(rect=[0, 0, 1, 0.96])
    fig.savefig(out_path, facecolor="white", bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    here = Path(__file__).resolve().parent
    paths = Paths(root=here)

    if not paths.input_csv.exists():
        raise FileNotFoundError(f"Input not found: {paths.input_csv}")

    df = load_sat_mca_table(paths.input_csv)

    dims_full = ["Algoritmo", "Evidencia", "Contexto", "Aplicacao", "Regiao"]
    g_full = build_cooccurrence_graph(df, dims_full, min_edge_weight=3)

    # Quick stats (largest connected component for path-based metrics)
    if g_full.number_of_nodes() > 0:
        gc = largest_connected_subgraph(g_full)
        density = nx.density(g_full)
        diameter = nx.diameter(gc) if gc.number_of_nodes() > 1 else 0
        avg_path = nx.average_shortest_path_length(gc) if gc.number_of_nodes() > 1 else 0.0

        comms = list(nx.algorithms.community.greedy_modularity_communities(gc, weight="weight"))
        modularity = nx.algorithms.community.modularity(gc, comms, weight="weight") if comms else 0.0

        print(
            "NETWORK STATS (SAT-only, min_edge_weight=3):\n"
            f"- nodes={g_full.number_of_nodes()} edges={g_full.number_of_edges()}\n"
            f"- density={density:.3f}\n"
            f"- diameter(LCC)={diameter} avg_shortest_path(LCC)={avg_path:.2f}\n"
            f"- modularity(LCC)={modularity:.3f} communities(LCC)={len(comms)}"
        )

    dim_colors = dim_color_map(dims_full)
    draw_network(
        g_full,
        paths.out_network_full,
        title="SAT co-occurrence network (category-values)",
        color_mode="dimension",
        dim_colors=dim_colors,
    )

    node_to_comm = compute_communities(g_full)
    draw_network(
        g_full,
        paths.out_network_communities,
        title="SAT network communities (greedy modularity)",
        color_mode="community",
        node_to_comm=node_to_comm,
    )

    # Keep filename for LaTeX compatibility; content is now Algorithm × Application (SAT-only)
    g_bi = build_bipartite_graph(df, left_dim="Algoritmo", right_dim="Aplicacao", min_edge_weight=2)
    draw_network(
        g_bi,
        paths.out_network_algo_prod,
        title="Algorithm × Application network (SAT-only)",
        color_mode="dimension",
        dim_colors=dim_color_map(["Algoritmo", "Aplicacao"]),
        seed=11,
    )

    plot_centrality_metrics(g_full, paths.out_network_metrics)

    print("OK: network figures generated")
    print(f"- {paths.out_network_full}")
    print(f"- {paths.out_network_communities}")
    print(f"- {paths.out_network_algo_prod}")
    print(f"- {paths.out_network_metrics}")


if __name__ == "__main__":
    main()
