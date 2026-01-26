"""Summarize SAT-only datasets for LaTeX numbers.

Prints key metrics used in Results/Discussion so the manuscript matches the figures.

Run:
  python report_sat_summary.py
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd


def count_bib_entries(bib_path: Path) -> int:
    text = bib_path.read_text(encoding="utf-8", errors="ignore")
    # naive but stable: count occurrences of "@" at line starts
    return sum(1 for line in text.splitlines() if line.lstrip().startswith("@"))


def main() -> None:
    here = Path(__file__).resolve().parent

    bib = (here / "../referencias_filtradas/referencias_scopus_wos_filtradas.bib").resolve()
    mca_csv = (here / "mca_dados_categorizados_sat.csv").resolve()
    fair_dim = (here / "scores_por_dimensao_sat.csv").resolve()
    fair_ind = (here / "indicadores_fair_detalhados_sat.csv").resolve()
    meta_studies = (here / "../1-ESTATISTICA/1-RSTUDIO/9-META_ANALISE/dados_meta_analise_sat.csv").resolve()
    meta_algo = (here / "../1-ESTATISTICA/1-RSTUDIO/9-META_ANALISE/meta_analise_por_algoritmo_sat.csv").resolve()

    print("SAT SUMMARY")

    if bib.exists():
        n_bib = count_bib_entries(bib)
        print(f"bib_entries={n_bib}")
    else:
        print("bib_entries=NA")

    if mca_csv.exists():
        df_mca = pd.read_csv(mca_csv)
        print(f"mca_rows={len(df_mca)}")
        years = df_mca["Ano"].dropna().astype(int)
        if len(years) > 0:
            print(f"mca_year_min={years.min()} mca_year_max={years.max()}")
    else:
        print("mca_rows=NA")

    if fair_dim.exists():
        df_dim = pd.read_csv(fair_dim)
        total_score = float(df_dim["score_medio"].sum())
        total_max = float(df_dim["score_max_possivel"].sum())
        print(f"fair_total_score={total_score:.3f} fair_total_max={total_max:.0f} fair_total_pct={(100*total_score/total_max):.3f}")
        for _, r in df_dim.iterrows():
            print(
                f"fair_{r['dimensao'].strip()}_score={float(r['score_medio']):.3f} "
                f"max={float(r['score_max_possivel']):.0f} pct={float(r['percentual']):.3f}"
            )
    else:
        print("fair_dims=NA")

    if fair_ind.exists():
        df_ind = pd.read_csv(fair_ind)
        if "n_sim" in df_ind.columns:
            n_pos = int((df_ind["n_sim"].fillna(0).astype(int) > 0).sum())
            n_zero = int((df_ind["n_sim"].fillna(0).astype(int) == 0).sum())
            print(f"fair_indicators_total={len(df_ind)} fair_indicators_n_pos={n_pos} fair_indicators_n_zero={n_zero}")
    else:
        print("fair_indicators=NA")

    if meta_studies.exists():
        df_meta = pd.read_csv(meta_studies)
        print(f"meta_k={len(df_meta)}")
        print(f"meta_year_min={int(df_meta['ano'].min())} meta_year_max={int(df_meta['ano'].max())}")
        print(f"meta_accuracy_mean={df_meta['acuracia'].mean():.3f} meta_accuracy_sd={df_meta['acuracia'].std(ddof=1):.3f}")
    else:
        print("meta_k=NA")

    if meta_algo.exists():
        df_algo = pd.read_csv(meta_algo)
        df_algo = df_algo.sort_values("n_estudos", ascending=False)
        print("meta_by_algorithm")
        for _, r in df_algo.iterrows():
            print(
                f"- {r['algoritmo']}: pooled={float(r['acuracia_pooled']):.3f} "
                f"CI=[{float(r['ic_inferior']):.3f}, {float(r['ic_superior']):.3f}] n={int(r['n_estudos'])}"
            )


if __name__ == "__main__":
    main()
