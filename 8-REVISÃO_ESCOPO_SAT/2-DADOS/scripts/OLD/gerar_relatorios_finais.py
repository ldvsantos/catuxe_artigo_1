import re
import os
from collections import Counter
import pandas as pd

# Caminhos
INPUT_BIB = '../referencias_filtradas/referencias_scopus_wos_filtradas.bib'
OUTPUT_LISTA = '../relatorios/1-lista_alta_relevancia.md'
OUTPUT_BIBLIO = '../relatorios/2-analise_bibliometrica.md'
OUTPUT_TOP7 = '../relatorios/3-analise_top7_excelencia.md'

print(f"Lendo {INPUT_BIB}...")

def parse_bib_file(filepath):
    entries = []
    current_entry = {}
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split by @article, @inproceedings, etc
    raw_entries = re.split(r'@\w+{', content)
    
    for raw in raw_entries[1:]: # Skip first empty split
        entry = {}
        
        # Extract fields
        for field in ['title', 'author', 'year', 'journal', 'abstract', 'keywords', 'author_keywords', 'affiliations', 'address', 'note']:
            # Search for field = {value} or field = "value" or field = value
            # Simplified regex for brace-enclosed values which is what our script produces
            match = re.search(rf'\s+{field}\s*=\s*{{(.*?)}}(?:,|\s*\n)', raw, re.DOTALL | re.IGNORECASE)
            if match:
                entry[field] = match.group(1).replace('\n', ' ').strip()
            else:
                entry[field] = ""
        
        # Extract Score from Note
        if entry['note']:
            score_match = re.search(r'Score:\s*([\d\.]+)', entry['note'])
            if score_match:
                entry['score'] = float(score_match.group(1))
            else:
                entry['score'] = 0.0
            
            source_match = re.search(r'Fonte:\s*(\w+)', entry['note'])
            if source_match:
                entry['source'] = source_match.group(1)
            else:
                entry['source'] = 'Unknown'
        else:
            entry['score'] = 0.0
            entry['source'] = 'Unknown'
            
        entries.append(entry)
        
    return entries

entries = parse_bib_file(INPUT_BIB)
print(f"Total entries loaded: {len(entries)}")

# ============================================================================
# 1. LISTA ALTA RELEVANCIA (8 <= SCORE < 15)
# ============================================================================
print("Gerando lista de alta relevância...")
high_rel = [e for e in entries if 8.0 <= e['score'] < 15.0]
high_rel.sort(key=lambda x: x['score'], reverse=True)

with open(OUTPUT_LISTA, 'w', encoding='utf-8') as f:
    f.write("# Lista de Artigos de Alta Relevância (Score 8-14)\n\n")
    f.write(f"Total: {len(high_rel)} artigos\n\n")
    
    for i, e in enumerate(high_rel, 1):
        f.write(f"## {i}. {e['title']}\n")
        f.write(f"- **Autores:** {e['author']}\n")
        f.write(f"- **Ano:** {e['year']} | **Revista:** {e['journal']}\n")
        f.write(f"- **Score:** {e['score']} | **Fonte:** {e['source']}\n")
        f.write(f"- **Resumo:** {e['abstract'][:300]}...\n\n")
        f.write("---\n")

# ============================================================================
# 2. ANALISE BIBLIOMETRICA
# ============================================================================
print("Gerando análise bibliométrica...")
all_keywords = []
all_countries = []

for e in entries:
    # Keywords
    kws = e['keywords'] + " " + e['author_keywords']
    if kws.strip():
        # Split by ; or ,
        parts = re.split(r'[;,]', kws)
        for p in parts:
            clean_kw = p.strip().lower()
            if clean_kw and len(clean_kw) > 2:
                all_keywords.append(clean_kw)
                
    # Countries (Simple extraction from affiliations/address)
    text_loc = e['affiliations'] + " " + e['address']
    # List of common countries in English/Portuguese
    common_countries = ['usa', 'united states', 'china', 'india', 'brazil', 'brasil', 
                       'germany', 'france', 'italy', 'spain', 'australia', 'canada', 
                       'united kingdom', 'uk', 'japan', 'indonesia', 'malaysia', 
                       'vietnam', 'thailand', 'mexico', 'colombia', 'peru', 'argentina']
    
    found_countries = set()
    text_lower = text_loc.lower()
    for c in common_countries:
        if c in text_lower:
            # Map variations
            if c in ['usa', 'united states']: c = 'USA'
            elif c in ['brasil', 'brazil']: c = 'Brazil'
            elif c in ['uk', 'united kingdom']: c = 'UK'
            else: c = c.title()
            found_countries.add(c)
    
    all_countries.extend(list(found_countries))

kw_counts = Counter(all_keywords).most_common(20)
country_counts = Counter(all_countries).most_common(15)

with open(OUTPUT_BIBLIO, 'w', encoding='utf-8') as f:
    f.write("# Análise Bibliométrica Preliminar\n\n")
    f.write("Baseado em 235 artigos filtrados.\n\n")
    
    f.write("## Top 20 Palavras-chave\n")
    f.write("| Palavra-chave | Frequência |\n")
    f.write("|---|---|\n")
    for kw, count in kw_counts:
        f.write(f"| {kw} | {count} |\n")
    
    f.write("\n## Top 15 Países (Inferido das Afiliações)\n")
    f.write("| País | Artigos |\n")
    f.write("|---|---|\n")
    for c, count in country_counts:
        f.write(f"| {c} | {count} |\n")

# ============================================================================
# 3. ANALISE TOP 7 EXCELENCIA
# ============================================================================
print("Gerando análise Top 7...")
top7 = [e for e in entries if e['score'] >= 15.0]
top7.sort(key=lambda x: x['score'], reverse=True)

with open(OUTPUT_TOP7, 'w', encoding='utf-8') as f:
    f.write("# Análise Detalhada: Artigos de Excelência (Top 7)\n\n")
    f.write("Artigos com Score >= 15.0 (Combinam termos fortes de SAT + ML)\n\n")
    
    for i, e in enumerate(top7, 1):
        f.write(f"## {i}. {e['title']}\n")
        f.write(f"**Score:** {e['score']} | **Ano:** {e['year']} | **Fonte:** {e['source']}\n\n")
        f.write(f"**Autores:** {e['author']}\n\n")
        f.write(f"**Journal:** {e['journal']}\n\n")
        f.write(f"### Resumo\n{e['abstract']}\n\n")
        f.write(f"### Palavras-chave\n{e['keywords']} {e['author_keywords']}\n\n")
        f.write("---\n")

print("Relatórios gerados com sucesso!")
