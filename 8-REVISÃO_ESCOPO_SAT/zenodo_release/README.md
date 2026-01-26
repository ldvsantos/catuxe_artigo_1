# SAT-ML Scoping Review — Zenodo Dataset Package

This package bundles the minimal artifacts to reproduce the bibliographic triage, descriptive analyses, network co-occurrence, MCA, clustering, meta-analysis/meta-regression, and FAIR scoring for the scoping review on Machine Learning applied to Traditional Agricultural Systems (SAT).

## Contents
- data/PRISMA.csv — PRISMA-ScR flow data (counts per stage)
- data/model_dados_completos.csv — consolidated metadata corpus (post-dedup)
- data/mca_dados_categorizados_sat.csv — standardized categorical variables for MCA
- data/temporal_tendencias.csv — aggregated time series for temporal plots
- searches/scopus_query.txt — Scopus search string
- searches/webofscience_query_R.txt — Web of Science search string
- bib/referencias.bib — LaTeX bibliography file
- bib/scopus_export.bib — Scopus export (raw)
- bib/wos_export.bib — Web of Science export (raw)
- scripts/report_sat_summary.py — summary metrics
- scripts/plot_* — plotting scripts for network/MCA/temporal/meta

## Reproducibility
1. Install Python 3.10+ and R (4.2+ recommended).
2. Create a virtual environment and install dependencies.

```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

3. Run summaries/plots (examples):

```bash
python scripts/report_sat_summary.py --input data/model_dados_completos.csv
python scripts/plot_temporal_sat_elsevier.py --ts data/temporal_tendencias.csv
python scripts/plot_network_sat_elsevier.py --input data/mca_dados_categorizados_sat.csv
```

## Metadata
- Title: Scoping review of Machine Learning in Traditional Agricultural Systems (SAT)
- Creators: Catuxe Varjão de Santana Oliveira; Luiz Diego Vidal Santos (corresponding)
- Description: Consolidated corpus, standardized variables, queries, and scripts to reproduce the main figures and quantitative syntheses (network, MCA, clustering, meta-analysis, FAIR).
- Access: Open
- License: To be confirmed by authors (recommended: CC-BY-4.0)

## How to publish in Zenodo
1. Log in to https://zenodo.org with ORCID/GitHub.
2. New Upload → Fill metadata (title, creators, description, keywords, access=open).
3. Attach files from this `zenodo_release` (keep folder structure or flatten under `/`).
4. Choose license (e.g., CC-BY-4.0) and publish to mint DOI.
5. Update the manuscript data availability section with the minted DOI.

## Notes
- Do not include any confidential data.
- Ensure all files referenced in the manuscript are present.
- Large images are cached under `latex/_fig_cache/`; include only those required.
