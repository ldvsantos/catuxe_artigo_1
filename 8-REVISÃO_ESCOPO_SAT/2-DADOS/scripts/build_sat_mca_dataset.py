#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build SAT MCA categorical dataset from the filtered BibTeX corpus.

Goal
- Generate a categorical table compatible with the MCA biplot, but based ONLY on
  the SAT (Sistemas Agrícolas Tradicionais) corpus.

Input
- 8-REVISÃO_ESCOPO_SAT/2-DADOS/referencias_filtradas/referencias_scopus_wos_filtradas.bib

Output
- 8-REVISÃO_ESCOPO_SAT/2-DADOS/scripts/mca_dados_categorizados_sat.csv

Notes
- This is a heuristic classifier over title/abstract/keywords.
- It also filters out obvious IG/product-authentication topics when detected.
"""

from __future__ import annotations

import os
import re
from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Tuple

import pandas as pd


SAT_TERMS = [
    # Mirrors the SAT priority list used elsewhere in the repo
    'traditional agricultural system', 'traditional farming system',
    'traditional agriculture', 'traditional agroecosystem',
    'sistemas agrícolas tradicionais', 'sistema agrícola tradicional',
    'agricultura tradicional', 'agroecolog',
    'socioecological system', 'socio-ecological system',
    'biocultural', 'cultural landscape', 'agrobiodiversity',
    'traditional knowledge', 'indigenous knowledge', 'local knowledge',
    'shifting cultivation', 'slash-and-burn', 'swidden'
]

# Strong IG/product-authentication signals (used to exclude).
IG_EXCLUDE_TERMS = [
    'geographical indication', 'geographical indications',
    'protected designation of origin', 'protected geographical indication',
    'denomination of origin', 'pdo', 'pgi',
    'origin detection', 'food fraud', 'adulteration',
    # common product tokens from the old IG dataset
    'wine', 'honey', 'cheese', 'olive', 'coffee', 'tea'
]

COUNTRY_TO_REGION = {
    # Americas
    'usa': 'Americas',
    'united states': 'Americas',
    'canada': 'Americas',
    'mexico': 'Americas',
    'brazil': 'Americas',
    'brasil': 'Americas',
    'peru': 'Americas',
    'colombia': 'Americas',
    'argentina': 'Americas',
    'chile': 'Americas',
    # Europe
    'uk': 'Europe',
    'united kingdom': 'Europe',
    'france': 'Europe',
    'germany': 'Europe',
    'italy': 'Europe',
    'spain': 'Europe',
    'portugal': 'Europe',
    'netherlands': 'Europe',
    'sweden': 'Europe',
    'norway': 'Europe',
    # Asia
    'china': 'Asia',
    'india': 'Asia',
    'indonesia': 'Asia',
    'malaysia': 'Asia',
    'vietnam': 'Asia',
    'thailand': 'Asia',
    'japan': 'Asia',
    'nepal': 'Asia',
    'laos': 'Asia',
    'myanmar': 'Asia',
    'cambodia': 'Asia',
    # Africa
    'south africa': 'Africa',
    'tanzania': 'Africa',
    'madagascar': 'Africa',
    'kenya': 'Africa',
    'ethiopia': 'Africa',
    # Oceania
    'australia': 'Oceania',
    'new zealand': 'Oceania',
}


@dataclass
class BibEntry:
    title: str
    year: Optional[int]
    abstract: str
    keywords: str
    author_keywords: str
    affiliations: str
    address: str

    @property
    def blob(self) -> str:
        return " ".join(
            [
                self.title,
                self.abstract,
                self.keywords,
                self.author_keywords,
                self.affiliations,
                self.address,
            ]
        ).lower()


def _extract_field(raw: str, field: str) -> str:
    # Handles brace-enclosed values from standard exporters.
    m = re.search(rf"\n\s*{re.escape(field)}\s*=\s*\{{(.+?)\}}\s*(?:,|\n)", raw, re.IGNORECASE | re.DOTALL)
    if not m:
        return ""
    val = m.group(1).replace("\n", " ").replace("\r", " ")
    return " ".join(val.split()).strip()


def parse_bib(filepath: str) -> List[BibEntry]:
    with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    raw_entries = re.split(r"@\w+\s*\{", content)
    entries: List[BibEntry] = []

    for raw in raw_entries[1:]:
        title = _extract_field(raw, "title")
        year_str = _extract_field(raw, "year")
        abstract = _extract_field(raw, "abstract")
        keywords = _extract_field(raw, "keywords")
        author_keywords = _extract_field(raw, "author_keywords")
        affiliations = _extract_field(raw, "affiliations")
        address = _extract_field(raw, "address")

        year: Optional[int] = None
        if year_str:
            m = re.search(r"(19\d{2}|20\d{2})", year_str)
            if m:
                year = int(m.group(1))

        entries.append(
            BibEntry(
                title=title,
                year=year,
                abstract=abstract,
                keywords=keywords,
                author_keywords=author_keywords,
                affiliations=affiliations,
                address=address,
            )
        )

    return entries


def _has_any(text: str, terms: Iterable[str]) -> bool:
    return any(t in text for t in terms)


def infer_period(year: Optional[int]) -> str:
    if year is None:
        return "NA"
    if 2010 <= year <= 2014:
        return "2010-14"
    if 2015 <= year <= 2019:
        return "2015-19"
    if 2020 <= year <= 2025:
        return "2020-25"
    if year < 2010:
        return "<2010"
    return ">2025"


def infer_algorithm(text: str) -> str:
    t = text
    # Priority ordering matters.
    if re.search(r"\b(transformer|bert|vit|vision transformer)\b", t):
        return "DeepLearning"
    if re.search(r"\b(cnn|convolutional neural network|deep learning|lstm|rnn|gru)\b", t):
        return "DeepLearning"
    if re.search(r"\b(random forest|random forests)\b", t):
        return "RandomForest"
    if re.search(r"\b(svm|support vector machine|support vector machines)\b", t):
        return "SVM"
    if re.search(r"\b(xgboost|lightgbm|gradient boosting|boosting)\b", t):
        return "Boosting"
    if re.search(r"\b(decision tree|cart)\b", t):
        return "DecisionTree"
    if re.search(r"\b(knn|k-nearest neighbor|k nearest neighbour)\b", t):
        return "KNN"
    if re.search(r"\b(linear regression|logistic regression|multilinear regression|regression)\b", t):
        return "Regression"
    if re.search(r"\b(naive bayes)\b", t):
        return "NaiveBayes"
    if re.search(r"\b(k-means|kmeans|clustering|hierarchical clustering)\b", t):
        return "Clustering"
    return "Other"


def infer_evidence(text: str) -> str:
    t = text
    sat = bool(re.search(r"\b(sentinel|landsat|modis|worldview|planet|alos|aster|satellite)\b", t))
    uav = bool(re.search(r"\b(uav|drone|unmanned aerial)\b", t))
    gis = bool(re.search(r"\b(gis|geospatial|geographic information system)\b", t))
    hyperspec = "hyperspectral" in t
    multispec = "multispectral" in t
    timeseries = bool(re.search(r"\b(time series|timeseries|multi-temporal|temporal)\b", t))

    flags = [sat, uav, gis, hyperspec, multispec, timeseries]
    if sum(bool(x) for x in flags) >= 2:
        return "Hybrid"
    if sat:
        return "Satellite"
    if uav:
        return "UAV"
    if hyperspec:
        return "Hyperspectral"
    if multispec:
        return "Multispectral"
    if timeseries:
        return "TimeSeries"
    if gis:
        return "GIS"
    if "remote sensing" in t:
        return "RemoteSensing"
    return "Other"


def infer_context(text: str) -> str:
    t = text
    if "agroforestry" in t:
        return "Agroforestry"
    if re.search(r"\b(shifting cultivation|swidden|slash-and-burn|slash and burn)\b", t):
        return "Swidden"
    if re.search(r"\b(traditional agricultural system|traditional farming system|traditional agroecosystem)\b", t):
        return "TraditionalSystem"
    if re.search(r"\b(indigenous knowledge|traditional knowledge|local knowledge|ilk)\b", t):
        return "TraditionalKnowledge"
    if "biocultural" in t or "cultural landscape" in t:
        return "Biocultural"
    return "SAT-General"


def infer_application(text: str) -> str:
    t = text
    if re.search(r"\b(lulc|land use|land-use|land cover|land-cover)\b", t):
        return "LULC"
    if "deforestation" in t or "forest loss" in t:
        return "Deforestation"
    if re.search(r"\b(yield|crop yield|yield prediction|rice-yield)\b", t):
        return "Yield"
    if "carbon" in t and ("stock" in t or "sequestration" in t):
        return "Carbon"
    if "biodiversity" in t:
        return "Biodiversity"
    if "soil" in t:
        return "Soil"
    if "mapping" in t:
        return "Mapping"
    if "monitor" in t or "monitoring" in t:
        return "Monitoring"
    if "classification" in t:
        return "Classification"
    return "Other"


def infer_region(text: str) -> str:
    t = text
    found_regions = set()
    for country, region in COUNTRY_TO_REGION.items():
        if country in t:
            found_regions.add(region)

    if len(found_regions) == 1:
        return next(iter(found_regions))
    if len(found_regions) >= 2:
        return "Global"

    # Heuristic fallbacks
    if "amazon" in t or "peru" in t or "brazil" in t or "brasil" in t:
        return "Americas"
    if "africa" in t:
        return "Africa"
    if "europe" in t:
        return "Europe"
    if "asia" in t:
        return "Asia"
    return "Global"


def main() -> None:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    bib_path = os.path.join(script_dir, "..", "referencias_filtradas", "referencias_scopus_wos_filtradas.bib")
    out_csv = os.path.join(script_dir, "mca_dados_categorizados_sat.csv")

    if not os.path.exists(bib_path):
        raise FileNotFoundError(f"Arquivo .bib não encontrado: {bib_path}")

    entries = parse_bib(bib_path)

    kept_rows: List[Dict[str, object]] = []
    excluded_ig = 0
    excluded_not_sat = 0
    excluded_no_year = 0

    for i, e in enumerate(entries, 1):
        blob = e.blob

        if _has_any(blob, IG_EXCLUDE_TERMS):
            excluded_ig += 1
            continue

        if not _has_any(blob, SAT_TERMS):
            # Only keep what clearly matches SAT. This avoids mixing corpora.
            excluded_not_sat += 1
            continue

        if e.year is None:
            excluded_no_year += 1
            continue

        row = {
            "ID": i,
            "Ano": e.year,
            "Periodo": infer_period(e.year),
            "Algoritmo": infer_algorithm(blob),
            "Evidencia": infer_evidence(blob),
            "Contexto": infer_context(blob),
            "Aplicacao": infer_application(blob),
            "Regiao": infer_region((e.affiliations + " " + e.address).lower()),
        }
        kept_rows.append(row)

    df = pd.DataFrame(kept_rows)

    if df.empty:
        raise RuntimeError(
            "Nenhuma referência foi classificada como SAT após filtros. "
            "Se isso for inesperado, revise SAT_TERMS/IG_EXCLUDE_TERMS em build_sat_mca_dataset.py"
        )

    # Normalize missing/regroup
    df["Periodo"] = df["Periodo"].replace({"NA": "Other", "<2010": "2010-14", ">2025": "2020-25"})

    # Keep only periods we plot (collapse if needed)
    df["Periodo"] = df["Periodo"].replace({"2010-14": "2010-14", "2015-19": "2015-19", "2020-25": "2020-25"})

    # Save
    df.to_csv(out_csv, index=False)

    print(f"✓ SAT MCA dataset gerado: {out_csv}")
    print(f"  - Entradas no .bib: {len(entries)}")
    print(f"  - Mantidas (SAT): {len(df)}")
    print(f"  - Excluídas por IG/produto: {excluded_ig}")
    print(f"  - Excluídas (sem match SAT): {excluded_not_sat}")
    print(f"  - Excluídas (ano ausente): {excluded_no_year}")


if __name__ == "__main__":
    main()
