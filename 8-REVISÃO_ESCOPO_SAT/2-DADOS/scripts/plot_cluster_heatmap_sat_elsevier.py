"""Cluster heatmap (SAT-only) with Elsevier-like color scale.

Inputs:
- mca_dados_categorizados_sat.csv

Output (overwrite, to keep LaTeX stable):
- ../../2-FIGURAS/2-EN/cluster_heatmap_profiles_edit.png

Run:
  python plot_cluster_heatmap_sat_elsevier.py
"""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.colors import LinearSegmentedColormap
from scipy.cluster.hierarchy import dendrogram, linkage
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score


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
            "font.size": 10,
            "axes.facecolor": "white",
            "figure.facecolor": "white",
        }
    )


def one_hot_from_categories(df: pd.DataFrame, dims: list[str]) -> tuple[pd.DataFrame, list[str]]:
    frames: list[pd.DataFrame] = []
    for d in dims:
        s = df[d].fillna("NA").astype(str).str.strip()
        # Keep a stable prefix for interpretability
        dummies = pd.get_dummies(s, prefix=d, prefix_sep="_")
        frames.append(dummies)
    X = pd.concat(frames, axis=1)
    return X, list(X.columns)


def pretty_feature(name: str) -> str:
    # "Dim_Value" -> "Dim=Value" for readability
    if "_" in name:
        d, v = name.split("_", 1)
        return f"{d}={v}"
    return name


def cluster_label_from_profiles(prof: pd.DataFrame, dims: list[str], cluster_id: int) -> str:
    def _short_value(s: str) -> str:
        v = s.split("=", 1)[-1]
        rep = {
            "SAT-General": "SATGen",
            "DeepLearning": "DL",
            "RandomForest": "RF",
            "DecisionTree": "DT",
            "NeuralNetwork": "NN",
        }
        for k, r in rep.items():
            v = v.replace(k, r)
        v = v.replace(" ", "")
        return v[:10]

    picks: list[str] = []
    for d in ["Contexto", "Aplicacao", "Algoritmo"]:
        if d not in dims:
            continue
        cols = [c for c in prof.columns if c.startswith(f"{d}_")]
        if not cols:
            continue
        s = prof.loc[cluster_id, cols].sort_values(ascending=False)
        if s.empty:
            continue
        best = pretty_feature(s.index[0])
        picks.append(_short_value(best))

    if not picks:
        return f"C{cluster_id}"
    return "/".join(picks[:2])


def _branch_label(leaf_labels: list[str], leaf_ids: list[int], heat0: pd.DataFrame) -> str:
    # Summarize which cluster column is more "active" for this subtree
    sub = heat0.iloc[leaf_ids]
    means = sub.mean(axis=0)
    best = str(means.idxmax())

    # Summarize dominant dimensions among features in this subtree
    dim_counts: dict[str, int] = {}
    for i in leaf_ids:
        d = leaf_labels[i].split("=", 1)[0]
        dim_counts[d] = dim_counts.get(d, 0) + 1
    top_dims = sorted(dim_counts.items(), key=lambda kv: (-kv[1], kv[0]))[:2]
    dim_map = {
        "Algoritmo": "Alg",
        "Aplicacao": "App",
        "Contexto": "Ctx",
        "Evidencia": "Evd",
        "Regiao": "Reg",
    }
    dims_txt = "/".join(dim_map.get(d, d[:3]) for d, _ in top_dims)
    return f"C{best} {dims_txt}".strip()


def choose_k(X: np.ndarray, k_min: int = 2, k_max: int = 6, seed: int = 7) -> tuple[int, float]:
    best_k = k_min
    best_s = -1.0
    for k in range(k_min, k_max + 1):
        km = KMeans(n_clusters=k, random_state=seed, n_init=20)
        labels = km.fit_predict(X)
        # silhouette requires at least 2 clusters and no single cluster
        if len(set(labels)) < 2:
            continue
        s = float(silhouette_score(X, labels, metric="euclidean"))
        if s > best_s:
            best_s = s
            best_k = k
    return best_k, best_s


def main() -> None:
    _style()

    here = Path(__file__).resolve().parent
    df = pd.read_csv(here / "mca_dados_categorizados_sat.csv")

    df = df.dropna(subset=["Ano"]).copy()
    df["Ano"] = df["Ano"].astype(int)
    df = df[(df["Ano"] >= 2010) & (df["Ano"] <= 2025)].copy()

    dims = ["Algoritmo", "Evidencia", "Contexto", "Aplicacao", "Regiao"]
    X_df, feature_names = one_hot_from_categories(df, dims)

    X = X_df.to_numpy(dtype=float)

    k, sil = choose_k(X, k_min=2, k_max=5, seed=7)
    km = KMeans(n_clusters=k, random_state=7, n_init=30)
    labels = km.fit_predict(X)

    df_out = df[["ID", "Ano"]].copy() if "ID" in df.columns else df[["Ano"]].copy()
    df_out["cluster"] = labels + 1

    # Cluster sizes
    sizes = df_out["cluster"].value_counts().sort_index()

    # Cluster profiles: mean presence for each feature
    prof = (
        pd.DataFrame(X, columns=feature_names)
        .assign(cluster=labels + 1)
        .groupby("cluster")
        .mean(numeric_only=True)
        .reindex(index=sorted(sizes.index))
    )

    # Select top features by overall mean, keep heatmap readable
    overall = prof.mean(axis=0).sort_values(ascending=False)
    top_features = overall.head(18).index.tolist()
    prof_top = prof[top_features]

    # Simple textual summary for manuscript alignment
    for cl in prof.index:
        topc = prof.loc[cl].sort_values(ascending=False).head(6)
        pretty = ", ".join([f"{pretty_feature(i)}={float(v):.3f}" for i, v in topc.items()])
        print(f"CLUSTER_TOP_FEATURES cluster={cl} {pretty}")

    # Colormap aligned with article palette
    cmap = LinearSegmentedColormap.from_list(
        "elsevier_pastel_seq",
        ["#ffffff", PASTEL["blue"], PASTEL["purple"]],
        N=256,
    )

    # Re-orient to match the previous manuscript style: features on Y, clusters on X.
    heat = prof_top.T.copy()  # rows=features, cols=clusters
    heat.index = [pretty_feature(i) for i in heat.index]
    heat.columns = [f"{int(i)}" for i in heat.columns]

    # Dendrogram for features (left), to recover the "tree" appearance.
    heat0 = heat.copy()  # keep original row order for linkage + labeling
    leaf_labels = list(heat0.index)

    Z = linkage(heat0.values, method="ward", metric="euclidean")
    den0 = dendrogram(Z, orientation="left", no_plot=True)
    order = den0["leaves"]
    heat = heat0.iloc[order]

    fig = plt.figure(figsize=(7.6, 7.9))
    # Keep the right side free for feature labels; put the colorbar below (horizontal).
    gs = fig.add_gridspec(
        nrows=2,
        ncols=2,
        width_ratios=[1.25, 3.25],
        height_ratios=[12.0, 0.9],
        wspace=0.06,
        hspace=0.18,
    )
    ax_den = fig.add_subplot(gs[0, 0])
    ax_hm = fig.add_subplot(gs[0, 1])
    ax_cb = fig.add_subplot(gs[1, 1])

    den = dendrogram(
        Z,
        orientation="left",
        ax=ax_den,
        color_threshold=0,
        above_threshold_color="#666666",
        no_labels=True,
    )
    ax_den.axis("off")

    # Annotate internal nodes (branches) that aggregate more than 3 leaves.
    n_leaves = int(Z.shape[0] + 1)
    children: dict[int, tuple[int, int]] = {n_leaves + i: (int(Z[i, 0]), int(Z[i, 1])) for i in range(Z.shape[0])}

    leaf_pos = {leaf: 5.0 + 10.0 * i for i, leaf in enumerate(den["leaves"])}

    def _collect_leaves(node: int, cache: dict[int, list[int]]) -> list[int]:
        if node < n_leaves:
            return [node]
        if node in cache:
            return cache[node]
        a, b = children[node]
        out = _collect_leaves(a, cache) + _collect_leaves(b, cache)
        cache[node] = out
        return out

    cache: dict[int, list[int]] = {}
    xlim = ax_den.get_xlim()
    dx = 0.03 * (xlim[1] - xlim[0])
    for i in range(Z.shape[0]):
        count = int(Z[i, 3])
        if count <= 3:
            continue
        node_id = n_leaves + i
        leaf_ids = _collect_leaves(node_id, cache)
        y = float(np.mean([leaf_pos[j] for j in leaf_ids]))
        dist = float(Z[i, 2])
        label = _branch_label(leaf_labels, leaf_ids, heat0)
        ax_den.text(
            dist + dx,
            y,
            label,
            fontsize=7,
            color="#444444",
            va="center",
            ha="left",
            bbox=dict(facecolor="white", edgecolor="none", alpha=0.75, pad=0.6),
        )

    # Align heatmap row centers to dendrogram leaf coordinates (5, 15, 25, ...)
    n_rows = int(heat.shape[0])
    y_max = 10.0 * n_rows
    extent = (-0.5, float(heat.shape[1]) - 0.5, 0.0, y_max)
    im = ax_hm.imshow(
        heat.values,
        aspect="auto",
        cmap=cmap,
        vmin=0.0,
        vmax=1.0,
        origin="lower",
        extent=extent,
    )

    y_ticks = [5.0 + 10.0 * i for i in range(n_rows)]
    ax_hm.set_yticks(y_ticks)
    ax_hm.set_yticklabels(list(heat.index), fontsize=9)
    # Match the classic "dendrogram + labels on the right" layout to avoid visual overlap.
    ax_hm.yaxis.tick_right()
    ax_hm.tick_params(axis="y", labelleft=False, labelright=True, pad=2)

    # Match y-limits so the dendrogram branches line up with heatmap rows.
    ax_hm.set_ylim(ax_den.get_ylim())

    ax_hm.set_xticks(np.arange(heat.shape[1]))
    xt = []
    for c in heat.columns:
        ci = int(c)
        name = cluster_label_from_profiles(prof, dims, ci)
        xt.append(f"{name} (n={int(sizes.loc[ci])})")
    ax_hm.set_xticklabels(xt, fontsize=9)

    ax_hm.set_title("Feature profile per cluster", pad=10)

    ax_hm.set_xticks(np.arange(-0.5, heat.shape[1], 1), minor=True)
    ax_hm.set_yticks(np.arange(-0.5, heat.shape[0], 1), minor=True)
    ax_hm.grid(which="minor", color="white", linestyle="-", linewidth=1.0)
    ax_hm.tick_params(which="minor", bottom=False, left=False)

    cbar = fig.colorbar(im, cax=ax_cb, orientation="horizontal")
    cbar.set_label("Mean Occurrence", fontsize=9, labelpad=4)
    cbar.set_ticks([0.0, 0.5, 1.0])
    cbar.set_ticklabels(["0%", "50%", "100%"])
    cbar.ax.tick_params(labelsize=8)

    # Manual spacing is more stable here than tight_layout (avoids axis overlap artifacts).
    fig.subplots_adjust(left=0.06, right=0.98, top=0.92, bottom=0.06)

    out_dir = (here / "../../2-FIGURAS/2-EN").resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "cluster_heatmap_profiles_edit.png"
    fig.savefig(out_path, facecolor="white", bbox_inches="tight")
    plt.close(fig)

    print(f"CLUSTER (SAT-only): k={k} silhouette={sil:.3f} sizes={dict(sizes)}")
    print(f"OK: saved {out_path}")


if __name__ == "__main__":
    main()
