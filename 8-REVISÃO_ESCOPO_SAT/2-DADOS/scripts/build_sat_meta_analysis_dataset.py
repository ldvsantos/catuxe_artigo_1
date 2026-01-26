#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build SAT meta-analysis inputs from the filtered BibTeX corpus.

This replaces the old IG/synthetic R pipeline (`09_meta_analise.R`) by extracting
reported accuracies from SAT-only papers directly from the BibTeX metadata.

Inputs
- 8-REVISÃO_ESCOPO_SAT/2-DADOS/referencias_filtradas/referencias_scopus_wos_filtradas.bib

Outputs
- 8-REVISÃO_ESCOPO_SAT/2-DADOS/1-ESTATISTICA/1-RSTUDIO/9-META_ANALISE/dados_meta_analise_sat.csv
- 8-REVISÃO_ESCOPO_SAT/2-DADOS/1-ESTATISTICA/1-RSTUDIO/9-META_ANALISE/meta_analise_por_algoritmo_sat.csv

Notes
- Accuracy extraction is heuristic (regex over title/abstract/keywords).
- When sample size cannot be extracted, we set n_amostral=100 to provide a
  conservative variance proxy for plots. This should be replaced by a curated
  extraction table if you need strict meta-analytic validity.
"""

from __future__ import annotations

import math
import os
import re
from dataclasses import dataclass
from typing import Iterable, List, Optional

import numpy as np
import pandas as pd


SAT_TERMS = [
    "traditional agricultural system",
    "traditional farming system",
    "traditional agriculture",
    "traditional agroecosystem",
    "sistemas agrícolas tradicionais",
    "sistema agrícola tradicional",
    "agricultura tradicional",
    "agroecolog",
    "socioecological system",
    "socio-ecological system",
    "biocultural",
    "cultural landscape",
    "agrobiodiversity",
    "traditional knowledge",
    "indigenous knowledge",
    "local knowledge",
    "shifting cultivation",
    "slash-and-burn",
    "swidden",
]

IG_EXCLUDE_TERMS = [
    "geographical indication",
    "geographical indications",
    "protected designation of origin",
    "protected geographical indication",
    "denomination of origin",
    "pdo",
    "pgi",
    "origin detection",
    "food fraud",
    "adulteration",
    "wine",
    "honey",
    "cheese",
    "olive",
    "coffee",
    "tea",
]


@dataclass
class BibEntry:
    key: str
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
    m = re.search(
        rf"\n\s*{re.escape(field)}\s*=\s*\{{(.+?)\}}\s*(?:,|\n)",
        raw,
        re.IGNORECASE | re.DOTALL,
    )
    if not m:
        return ""
    val = m.group(1).replace("\n", " ").replace("\r", " ")
    return " ".join(val.split()).strip()


def parse_bib(filepath: str) -> List[BibEntry]:
    with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    # Keep the citekey by splitting in a way that preserves it.
    parts = re.split(r"@(\w+)\s*\{", content)
    # parts = [before_first, type1, rest1, type2, rest2, ...]
    entries: List[BibEntry] = []
    for i in range(1, len(parts), 2):
        raw = parts[i + 1]
        key_match = re.match(r"\s*([^,]+)", raw)
        key = key_match.group(1).strip() if key_match else ""

        title = _extract_field(raw, "title")
        year_str = _extract_field(raw, "year")
        abstract = _extract_field(raw, "abstract")
        keywords = _extract_field(raw, "keywords")
        author_keywords = _extract_field(raw, "author_keywords")
        affiliations = _extract_field(raw, "affiliations")
        address = _extract_field(raw, "address")

        year: Optional[int] = None
        if year_str:
            ym = re.search(r"(19\d{2}|20\d{2})", year_str)
            if ym:
                year = int(ym.group(1))

        entries.append(
            BibEntry(
                key=key,
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


def _infer_algorithm(text: str) -> str:
    t = text

    # Priority ordering matters.
    if re.search(r"\b(transformer|bert|vit|vision transformer)\b", t):
        return "Deep Learning"
    if re.search(r"\b(cnn|convolutional neural network|deep learning|lstm|rnn|gru)\b", t):
        return "Deep Learning"
    if re.search(r"\b(artificial neural network|neural network|\bann\b)\b", t):
        return "Neural Network"
    if re.search(r"\b(random forest|random forests)\b", t):
        return "Random Forest"
    if re.search(r"\b(svm|support vector machine|support vector machines)\b", t):
        return "SVM"
    if re.search(r"\b(xgboost|lightgbm|catboost)\b", t):
        return "XGBoost"
    if re.search(r"\b(gradient boosting|boosting)\b", t):
        return "XGBoost"
    if re.search(r"\b(pls-da|pls da|partial least squares discriminant)\b", t):
        return "PLS-DA"
    if re.search(r"\b(decision tree|cart)\b", t):
        return "Decision Tree"
    if re.search(r"\b(knn|k-nearest neighbor|k nearest neighbour)\b", t):
        return "KNN"
    return "Other"


def _extract_accuracy_pct(text: str) -> Optional[float]:
    t = " ".join(text.split())

    # Prefer "overall accuracy" then generic "accuracy". Capture percent numbers.
    patterns = [
        r"overall\s+accuracy[^0-9%]{0,30}(\d{1,3}(?:\.\d+)?)\s*%",
        r"accuracy[^0-9%]{0,30}(\d{1,3}(?:\.\d+)?)\s*%",
        r"(\d{1,3}(?:\.\d+)?)\s*%\s*(?:overall\s*)?accuracy",
        r"achieves\s+(\d{1,3}(?:\.\d+)?)\s*%\s*accuracy",
    ]

    candidates: List[float] = []
    for pat in patterns:
        for m in re.finditer(pat, t, flags=re.IGNORECASE):
            try:
                val = float(m.group(1))
            except Exception:
                continue
            if 0.0 <= val <= 100.0:
                candidates.append(val)
        if candidates:
            # If we matched a higher-priority pattern, stop early.
            break

    if not candidates:
        return None

    # Prefer the highest, since abstracts may list multiple and the first isn't always overall.
    return float(max(candidates))


def _extract_sample_size(text: str) -> Optional[int]:
    t = " ".join(text.split())

    patterns = [
        r"\b(?:n|N)\s*=\s*(\d{2,7})\b",
        r"\b(\d{2,7})\s*(?:sampling\s+sites|samples|households|plots|observations|records)\b",
    ]

    candidates: List[int] = []
    for pat in patterns:
        for m in re.finditer(pat, t, flags=re.IGNORECASE):
            try:
                val = int(m.group(1))
            except Exception:
                continue
            if 10 <= val <= 10_000_000:
                candidates.append(val)

    if not candidates:
        return None

    # Take the largest plausible value.
    return int(max(candidates))


def _clamp01(x: np.ndarray | float, eps: float = 1e-4):
    return np.clip(x, eps, 1.0 - eps)


def _logit(p: np.ndarray | float):
    p = _clamp01(np.asarray(p, dtype=float))
    return np.log(p / (1.0 - p))


def _ilogit(x: np.ndarray | float):
    x = np.asarray(x, dtype=float)
    return 1.0 / (1.0 + np.exp(-x))


def _reml_tau2(yi: np.ndarray, vi: np.ndarray) -> float:
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
        return 0.5 * (float(np.sum(np.log(vi + tau2))) + math.log(sw) + q)

    hi = float(max(1e-6, np.var(yi)))
    hi = max(hi, float(np.nanmax(vi)) * 5.0)

    f0 = nll(0.0)
    fhi = nll(hi)
    expand = 0
    while np.isfinite(fhi) and fhi < f0 and expand < 12:
        hi *= 2.0
        fhi = nll(hi)
        expand += 1

    lo = 0.0
    gr = (math.sqrt(5) - 1) / 2
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

    bib_path = os.path.join(sat_root, "2-DADOS", "referencias_filtradas", "referencias_scopus_wos_filtradas.bib")
    meta_dir = os.path.join(sat_root, "2-DADOS", "1-ESTATISTICA", "1-RSTUDIO", "9-META_ANALISE")

    os.makedirs(meta_dir, exist_ok=True)

    entries = parse_bib(bib_path)

    rows = []
    for e in entries:
        blob = e.blob
        if not _has_any(blob, SAT_TERMS):
            continue
        if _has_any(blob, IG_EXCLUDE_TERMS):
            continue

        acc = _extract_accuracy_pct(" ".join([e.title, e.abstract, e.keywords, e.author_keywords]))
        if acc is None:
            continue

        n = _extract_sample_size(" ".join([e.abstract, e.keywords, e.author_keywords, e.affiliations, e.address]))
        if n is None:
            n = 100

        algo = _infer_algorithm(" ".join([e.title, e.abstract, e.keywords, e.author_keywords]).lower())

        year = e.year
        if year is None:
            continue

        # Variance proxy on percent scale for the meta-regression plot.
        p = float(_clamp01(acc / 100.0))
        se_prop = math.sqrt(p * (1.0 - p) / float(n))
        var_pct = float((se_prop * 100.0) ** 2)

        rows.append(
            {
                "estudo_id": e.key or f"{year}-{len(rows)+1}",
                "autor_ano": f"{(e.key or 'Study').strip()}_{year}",
                "ano": int(year),
                "algoritmo": algo,
                "acuracia": float(acc),
                "n_amostral": int(n),
                "variancia": var_pct,
            }
        )

    df = pd.DataFrame(rows)
    if df.empty:
        raise RuntimeError("Nenhuma acurácia extraída do corpus SAT. Verifique filtros/termos.")

    # Save per-study dataset (for meta-regression).
    out_study = os.path.join(meta_dir, "dados_meta_analise_sat.csv")
    df.sort_values(["ano", "algoritmo"], inplace=True)
    df.to_csv(out_study, index=False)

    # Build meta-analysis by algorithm (random effects on logit scale).
    algo_rows = []
    for algo, g in df.groupby("algoritmo", sort=False):
        p = _clamp01(g["acuracia"].to_numpy(dtype=float) / 100.0)
        n = g["n_amostral"].to_numpy(dtype=float)

        yi = _logit(p)
        # Delta-method: var(logit(p)) ~ 1/(n*p*(1-p))
        vi = 1.0 / (n * p * (1.0 - p))

        tau2 = _reml_tau2(yi, vi)
        wi = 1.0 / (vi + tau2)
        wsum = float(np.sum(wi))
        mu = float(np.sum(wi * yi) / wsum)
        se_mu = float(math.sqrt(1.0 / wsum))
        ci_mu = (mu - 1.96 * se_mu, mu + 1.96 * se_mu)

        p_mu = float(_ilogit(mu))
        p_lo = float(_ilogit(ci_mu[0]))
        p_hi = float(_ilogit(ci_mu[1]))

        algo_rows.append(
            {
                "algoritmo": algo,
                "acuracia_pooled": p_mu * 100.0,
                "ic_inferior": p_lo * 100.0,
                "ic_superior": p_hi * 100.0,
                "n_estudos": int(len(g)),
            }
        )

    df_algo = pd.DataFrame(algo_rows).sort_values("acuracia_pooled", ascending=False)
    out_algo = os.path.join(meta_dir, "meta_analise_por_algoritmo_sat.csv")
    df_algo.to_csv(out_algo, index=False)

    print(f"✓ SAT meta dataset: {out_study}")
    print(f"✓ SAT meta by algorithm: {out_algo}")
    print(f"✓ Studies with extracted accuracy: {len(df)}")


if __name__ == "__main__":
    main()
