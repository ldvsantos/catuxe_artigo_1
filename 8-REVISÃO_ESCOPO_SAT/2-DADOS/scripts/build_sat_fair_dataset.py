#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build SAT FAIR inputs from the filtered BibTeX corpus.

This replaces the old IG/synthetic R pipeline (`11_conformidade_fair.R`) by
heuristically scoring FAIR-like signals directly from the SAT-only BibTeX
metadata (title/abstract/keywords/url/doi).

Inputs
- 8-REVISÃO_ESCOPO_SAT/2-DADOS/referencias_filtradas/referencias_scopus_wos_filtradas.bib

Outputs (written next to this script, as expected by the plotting script)
- scores_por_dimensao_sat.csv
- indicadores_fair_detalhados_sat.csv

Notes
- This is NOT a substitute for a curated FAIR extraction. It is a provenance-
  correct, text-mining proxy so we stop using synthetic IG/product data.
"""

from __future__ import annotations

import os
import re
from dataclasses import dataclass
from typing import Iterable, List, Optional

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
    doi: str
    url: str

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
                self.doi,
                self.url,
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

    parts = re.split(r"@(\w+)\s*\{", content)
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
        doi = _extract_field(raw, "doi")
        url = _extract_field(raw, "url")

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
                doi=doi,
                url=url,
            )
        )

    return entries


def _has_any(text: str, terms: Iterable[str]) -> bool:
    return any(t in text for t in terms)


def _flag_repository(text: str) -> bool:
    return bool(
        re.search(
            r"\b(zenodo|figshare|osf\.io|open science framework|dataverse|dryad|mendeley data|kaggle|pangaea)\b",
            text,
        )
        or re.search(r"\b(github\.com|gitlab\.com|bitbucket\.org)\b", text)
    )


def _flag_code(text: str) -> str:
    if re.search(r"\b(github\.com|gitlab\.com|bitbucket\.org)\b", text):
        return "Sim"
    if re.search(r"\b(source code|code available|code is available|open-source|open source)\b", text):
        return "Parcial"
    return "Não"


def _flag_license(text: str) -> bool:
    return bool(re.search(r"\b(cc-by|creative commons|license|licence|mit license|apache)\b", text))


def _flag_standard_format(text: str) -> bool:
    return bool(re.search(r"\b(csv|geotiff|tiff|netcdf|hdf5|shapefile|geojson|json|xml)\b", text))


def _flag_vocab(text: str) -> bool:
    return bool(re.search(r"\b(agrovoc|ontology|controlled vocabulary|thesaurus)\b", text))


def _flag_supplementary(text: str) -> bool:
    return bool(re.search(r"\b(supplementary|supporting information|appendix)\b", text))


def _flag_api(text: str) -> bool:
    return bool(re.search(r"\b(api|rest api|endpoint)\b", text))


def _flag_blockchain(text: str) -> bool:
    return "blockchain" in text


def _metadata_richness(e: BibEntry) -> str:
    has_abs = len(e.abstract.strip()) >= 80
    has_kw = bool(e.keywords.strip()) or bool(e.author_keywords.strip())
    if has_abs and has_kw:
        return "Sim"
    if has_abs or has_kw:
        return "Parcial"
    return "Não"


def main() -> None:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sat_root = os.path.abspath(os.path.join(script_dir, "..", ".."))
    bib_path = os.path.join(sat_root, "2-DADOS", "referencias_filtradas", "referencias_scopus_wos_filtradas.bib")

    entries = parse_bib(bib_path)

    rows = []
    for e in entries:
        blob = e.blob
        if not _has_any(blob, SAT_TERMS):
            continue
        if _has_any(blob, IG_EXCLUDE_TERMS):
            continue

        doi_available = bool(e.doi.strip()) or ("doi.org/" in e.url.lower()) or bool(re.search(r"\b10\.\d{4,9}/\S+\b", blob))
        meta_rich = _metadata_richness(e)

        data_repo = _flag_repository(blob)
        supp = _flag_supplementary(blob)

        fmt = _flag_standard_format(blob)
        vocab = _flag_vocab(blob)

        license_ok = _flag_license(blob)
        code = _flag_code(blob)
        doc = "Completa" if (code == "Sim" and len(e.abstract.strip()) >= 200) else ("Parcial" if len(e.abstract.strip()) >= 120 else "Insuficiente")

        blockchain = "Sim" if _flag_blockchain(blob) else "Não"
        api = "Sim" if _flag_api(blob) else "Não"

        score_f = (10 if doi_available else 0) + (15 if meta_rich == "Sim" else (7 if meta_rich == "Parcial" else 0))
        score_a = (15 if data_repo else 0) + (10 if supp else 0)
        score_i = (15 if fmt else 0) + (10 if vocab else 0)
        score_r = (8 if license_ok else 0) + (10 if code == "Sim" else (5 if code == "Parcial" else 0)) + (7 if doc == "Completa" else (3 if doc == "Parcial" else 0))
        score_total = score_f + score_a + score_i + score_r

        rows.append(
            {
                "estudo_id": e.key or "",
                "ano": e.year,
                "doi_disponivel": "Sim" if doi_available else "Não",
                "metadados_ricos": meta_rich,
                "dados_repositorio": "Sim" if data_repo else "Não",
                "dados_suplementares": "Sim" if supp else "Não",
                "formato_padrao": "Sim" if fmt else "Não",
                "vocabulario_controlado": "Sim" if vocab else "Não",
                "licenca_clara": "Sim" if license_ok else "Não",
                "codigo_disponivel": code,
                "documentacao_metodo": doc,
                "blockchain": blockchain,
                "api_disponivel": api,
                "score_f": score_f,
                "score_a": score_a,
                "score_i": score_i,
                "score_r": score_r,
                "score_fair": score_total,
                "compliant": "Sim" if score_total >= 50 else "Não",
            }
        )

    df = pd.DataFrame(rows)
    if df.empty:
        raise RuntimeError("Nenhum estudo SAT detectado para cálculo FAIR (verifique filtros/termos).")

    # Scores por dimensão (média) — mesma estrutura esperada pelo plot.
    scores_dim = (
        df[["score_f", "score_a", "score_i", "score_r"]]
        .mean()
        .rename(
            {
                "score_f": "Findable",
                "score_a": "Accessible",
                "score_i": "Interoperable",
                "score_r": "Reusable",
            }
        )
        .reset_index()
    )
    scores_dim.columns = ["dimensao", "score_medio"]
    scores_dim["score_max_possivel"] = 25
    scores_dim["percentual"] = (scores_dim["score_medio"] / 25.0) * 100.0

    # Indicadores individuais — compatível com o plot.
    indicators = [
        ("DOI disponível", "doi_disponivel", lambda s: (s == "Sim")),
        ("Metadados ricos", "metadados_ricos", lambda s: (s == "Sim")),
        ("Dados em repositório", "dados_repositorio", lambda s: (s == "Sim")),
        ("Dados suplementares", "dados_suplementares", lambda s: (s == "Sim")),
        ("Formato padrão", "formato_padrao", lambda s: (s == "Sim")),
        ("Vocabulário controlado", "vocabulario_controlado", lambda s: (s == "Sim")),
        ("Licença clara", "licenca_clara", lambda s: (s == "Sim")),
        ("Código disponível", "codigo_disponivel", lambda s: (s == "Sim")),
        ("Documentação completa", "documentacao_metodo", lambda s: (s == "Completa")),
        ("Blockchain", "blockchain", lambda s: (s == "Sim")),
        ("API disponível", "api_disponivel", lambda s: (s == "Sim")),
    ]

    n = len(df)
    ind_rows = []
    for pt, col, pred in indicators:
        series = df[col]
        n_sim = int(pred(series).sum())
        ind_rows.append(
            {
                "indicador": pt,
                "n_sim": n_sim,
                "percentual": (n_sim / n) * 100.0,
                "gap": 100.0 - (n_sim / n) * 100.0,
                "indicador_en": {
                    "DOI disponível": "DOI available",
                    "Metadados ricos": "Rich metadata",
                    "Dados em repositório": "Data in repository",
                    "Dados suplementares": "Supplementary data",
                    "Formato padrão": "Standard format",
                    "Vocabulário controlado": "Controlled vocabulary",
                    "Licença clara": "Clear license",
                    "Código disponível": "Code available",
                    "Documentação completa": "Complete documentation",
                    "API disponível": "API available",
                    "Blockchain": "Blockchain",
                }.get(pt, pt),
            }
        )

    df_ind = pd.DataFrame(ind_rows).sort_values("percentual", ascending=False)

    out_scores = os.path.join(script_dir, "scores_por_dimensao_sat.csv")
    out_ind = os.path.join(script_dir, "indicadores_fair_detalhados_sat.csv")

    scores_dim.to_csv(out_scores, index=False)
    df_ind.to_csv(out_ind, index=False)

    print(f"✓ SAT FAIR dimension scores: {out_scores}")
    print(f"✓ SAT FAIR indicators: {out_ind}")
    print(f"✓ Studies scored: {n}")


if __name__ == "__main__":
    main()
