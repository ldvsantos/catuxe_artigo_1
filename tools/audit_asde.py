#!/usr/bin/env python3
"""Auditoria do manuscrito sn-article.tex contra diretrizes ASDE IFA 2025."""
import re, sys

TEX = r"C:\Users\vidal\OneDrive\Documentos\13 - CLONEGIT\artigo_1_catuxe\8-REVISÃO_ESCOPO_SAT\latex\sn-article.tex"
t = open(TEX, "r", encoding="utf-8").read()

erros = []
avisos = []
ok_items = []

def erro(msg):
    erros.append(msg)
    print(f"  [ERRO] {msg}")

def aviso(msg):
    avisos.append(msg)
    print(f"  [AVISO] {msg}")

def ok(msg):
    ok_items.append(msg)
    print(f"  [OK] {msg}")

# ========== 1. ABSTRACT ==========
print("=" * 60)
print("1. ABSTRACT")
print("=" * 60)
m = re.search(r"\\abstract\{(.+?)\}\s*\\keywords", t, re.DOTALL)
if m:
    abs_raw = m.group(1)
    abs_clean = re.sub(r"\\[a-zA-Z]+(\[[^\]]*\])?(\{[^}]*\})?", " ", abs_raw)
    abs_clean = re.sub(r"[\$\{\}\\\%\~]", " ", abs_clean)
    abs_clean = re.sub(r"\s+", " ", abs_clean).strip()
    abs_words = len(abs_clean.split())
    if abs_words <= 300:
        ok(f"Abstract: {abs_words} palavras (limite 300)")
    else:
        erro(f"Abstract: {abs_words} palavras EXCEDE limite de 300")

    # Check abbreviations in abstract
    abs_abbrevs = re.findall(r"\b[A-Z]{2,}\b", abs_raw)
    # Filter out allowed patterns
    abs_abbrevs = [a for a in abs_abbrevs if a not in ("IC", "FAIR", "OR", "AND")]
    if abs_abbrevs:
        aviso(f"Possiveis abreviacoes no abstract: {set(abs_abbrevs)}")
    
    # Check for literature references in abstract
    if "\\citep" in abs_raw or "\\cite{" in abs_raw:
        erro("Abstract contem referencias bibliograficas (proibido pela ASDE)")
    else:
        ok("Abstract sem referencias bibliograficas")

    # Abstract structure: 3 parts (background/hypothesis, methods, results/novelty)
    if "Aqui demonstramos" in abs_raw or "Here we" in abs_raw:
        ok("Abstract contem claim de novidade (Aqui demonstramos/Here we)")
    else:
        aviso("Abstract deve conter claim tipo 'Here we show/demonstrate'")

# ========== 2. KEYWORDS ==========
print("\n" + "=" * 60)
print("2. KEYWORDS")
print("=" * 60)
km = re.search(r"\\keywords\{(.+?)\}", t, re.DOTALL)
if km:
    kws = [k.strip() for k in km.group(1).split(",")]
    if len(kws) <= 10:
        ok(f"{len(kws)} keywords (limite 10)")
    else:
        erro(f"{len(kws)} keywords EXCEDE limite de 10")

# ========== 3. TITULO ==========
print("\n" + "=" * 60)
print("3. TITULO")
print("=" * 60)
tm = re.search(r"\\title\{(.+?)\}", t, re.DOTALL)
if tm:
    title = tm.group(1)
    title_clean = re.sub(r"\\textbf\{(.+?)\}", r"\1", title)
    if ". Uma meta-" in title_clean or ". A meta-" in title_clean:
        ok("Sufixo '. A meta-analysis' presente")
    else:
        erro("Titulo deve terminar com '. A meta-analysis' (ponto, nao dois pontos)")
    
    if "?" in title:
        erro("Titulo NAO pode ser pergunta")
    else:
        ok("Titulo nao e pergunta")

# ========== 4. LINENO + PAGE NUMBERING ==========
print("\n" + "=" * 60)
print("4. NUMERACAO DE LINHAS E PAGINAS")
print("=" * 60)
if "lineno" in t:
    ok("lineno ativado")
else:
    erro("Falta opcao lineno no documentclass")

# ========== 5. SECOES IMRaD ==========
print("\n" + "=" * 60)
print("5. ESTRUTURA IMRaD")
print("=" * 60)
sections = {
    "Introduction": "Introdu",
    "Materials and methods": "Materiais e M",
    "Results": "Resultado",
    "Discussion": "Discuss",
    "Conclusion": "Conclus",
}
for name, pattern in sections.items():
    if pattern.lower() in t.lower():
        ok(f"Secao '{name}' presente")
    else:
        erro(f"Secao '{name}' FALTANDO")

# Check Results + Discussion combined vs separate
res_pos = t.lower().find("\\section[resultados]")
disc_pos = t.lower().find("\\section[discuss")
if res_pos > -1 and disc_pos > -1:
    aviso("Results e Discussion sao secoes SEPARADAS. ASDE recomenda combinar. Se separadas, justificar no cover letter.")

# ========== 6. DECLARATIONS ==========
print("\n" + "=" * 60)
print("6. DECLARATIONS")
print("=" * 60)
decls = [
    "Funding",
    "Conflicts of interest",
    "Ethics approval",
    "Consent to participate",
    "Consent for publication",
    "Data availability",
    "Code availability",
    "Authors' contributions",
]
for d in decls:
    if d.lower() in t.lower() or d.replace("'", "").lower() in t.lower():
        ok(f"{d}")
    else:
        erro(f"{d} FALTANDO")

# ========== 7. REFERENCES OF META-ANALYSIS ==========
print("\n" + "=" * 60)
print("7. REFERENCES OF THE META-ANALYSIS")
print("=" * 60)
if "References of the meta-analysis" in t or "References of the Meta" in t:
    ok("Secao presente")
else:
    erro("Secao 'References of the meta-analysis' FALTANDO")

if "ACAO REQUERIDA" in t:
    erro("Placeholder ainda presente - lista dos 244 estudos NAO preenchida")

# ========== 8. FIGURA 1 (foto cor) ==========
print("\n" + "=" * 60)
print("8. FIGURA 1 (FOTO COR NA INTRODUCAO)")
print("=" * 60)
if "photo_intro" in t or "sat.jpg" in t:
    ok("Foto colorida presente na introducao")
else:
    erro("Falta foto colorida (landscape) na Introducao como Figura 1")

# Photocredit
fig1_caption = re.search(r"\\caption\{.*?photo_intro.*?\}", t, re.DOTALL)
if not fig1_caption:
    fig1_caption = re.search(r"\\caption\{Quintais.*?\}", t, re.DOTALL)

if fig1_caption:
    cap = fig1_caption.group(0)
    if "Photocredit" in cap or "photocredit" in cap.lower() or "Photo credit" in cap:
        ok("Photocredit presente na legenda")
    else:
        erro("Falta 'Photocredit: Nome' no final da legenda da Figura 1")
else:
    aviso("Nao foi possivel localizar caption da Figura 1")

# ========== 9. ABREVIACOES ==========
print("\n" + "=" * 60)
print("9. ABREVIACOES")
print("=" * 60)
aviso("ASDE limita a 1-2 abreviacoes comuns (ex: DNA, LED). Verificar manualmente uso de SVM, CNN, LSTM, MCA, ARS, etc.")

# ========== 10. FOOTNOTES ==========
print("\n" + "=" * 60)
print("10. FOOTNOTES")
print("=" * 60)
doc_start = t.find(r"\begin{document}")
body = t[doc_start:]
if "\\footnote" in body:
    erro("Footnotes encontradas no texto (proibido pela ASDE)")
else:
    ok("Sem footnotes")

# ========== 11. ENUMERATE/ITEMIZE ==========
print("\n" + "=" * 60)
print("11. LISTAS (ENUMERATE/ITEMIZE)")
print("=" * 60)
if "\\begin{enumerate}" in body:
    erro("enumerate encontrado no corpo do texto")
else:
    ok("Sem enumerate")
if "\\begin{itemize}" in body:
    erro("itemize encontrado no corpo do texto")
else:
    ok("Sem itemize")

# ========== 12. IDIOMA ==========
print("\n" + "=" * 60)
print("12. IDIOMA")
print("=" * 60)
if "brazilian" in t:
    erro("Manuscrito em PORTUGUES. ASDE exige American English.")
else:
    ok("Idioma")

# ========== 13. ORDEM DE CITACAO DE FIGURAS ==========
print("\n" + "=" * 60)
print("13. ORDEM DE CITACAO DE FIGURAS")
print("=" * 60)
doc_lines = body.split("\n")
refs = {}
labels = {}
for i, line in enumerate(doc_lines):
    for m2 in re.finditer(r"\\ref\{(fig:[^}]+)\}", line):
        k = m2.group(1)
        if k not in refs:
            refs[k] = i
    for m2 in re.finditer(r"\\label\{(fig:[^}]+)\}", line):
        k = m2.group(1)
        if k not in labels:
            labels[k] = i
for k in sorted(labels, key=lambda x: labels[x]):
    ref_line = refs.get(k, None)
    lab_line = labels[k]
    if ref_line is not None:
        if ref_line < lab_line:
            ok(f"{k}: citada antes do float")
        else:
            erro(f"{k}: citada DEPOIS do float (ref L{ref_line} > label L{lab_line})")
    else:
        erro(f"{k}: NAO CITADA no texto")

# ========== 14. CONTAGEM TOTAL DE FIGURAS/TABELAS ==========
print("\n" + "=" * 60)
print("14. CONTAGEM DE FIGURAS + TABELAS")
print("=" * 60)
n_figs = len(labels)
n_tabs = len(re.findall(r"\\label\{tab:", body))
total = n_figs + n_tabs
print(f"  Figuras: {n_figs}, Tabelas: {n_tabs}, Total: {total}")
aviso("Meta-analises NAO tem limite de figuras/tabelas (limite de 8 e so para Research Articles)")

# ========== 15. AI DISCLOSURE ==========
print("\n" + "=" * 60)
print("15. DECLARACAO DE USO DE IA")
print("=" * 60)
ai_patterns = ["AI tools", "AI use", "artificial intelligence was used", "ChatGPT", "Copilot", "language model"]
ai_found = any(p.lower() in t.lower() for p in ai_patterns)
if ai_found:
    ok("Declaracao de IA encontrada no artigo")
else:
    aviso("ASDE exige declaracao de uso de IA no cover letter E no artigo (se aplicavel)")

# ========== 16. ORCID ==========
print("\n" + "=" * 60)
print("16. ORCID")
print("=" * 60)
if "orcid" in t.lower():
    ok("ORCID presente")
else:
    aviso("ORCID obrigatorio para corresponding author (pode ser inserido no sistema de submissao)")

# ========== 17. DOI FORMAT ==========
print("\n" + "=" * 60)
print("17. FORMATO DOI")
print("=" * 60)
aviso("ASDE exige DOIs no formato https://doi.org/. Verificar no .bib/.bbl")

# ========== 18. APPENDICES ==========
print("\n" + "=" * 60)
print("18. APENDICES/ANEXOS")
print("=" * 60)
if "\\appendix" in body or "Appendix" in body or "Anexo" in body:
    erro("Apendices/Anexos NAO sao aceitos pela ASDE")
else:
    ok("Sem apendices/anexos")

# ========== RESUMO ==========
print("\n" + "=" * 60)
print("RESUMO FINAL DA AUDITORIA ASDE")
print("=" * 60)
print(f"  ERROS CRITICOS: {len(erros)}")
for e in erros:
    print(f"    - {e}")
print(f"\n  AVISOS: {len(avisos)}")
for a in avisos:
    print(f"    - {a}")
print(f"\n  CONFORMES: {len(ok_items)}")
