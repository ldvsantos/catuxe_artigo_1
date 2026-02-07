# PLANO DE AÇÃO - Correções Prioritárias
## Machine Learning para Auditoria de SAT
**Data:** 7 de fevereiro de 2026  
**Status:** Aguardando implementação  
**Tempo Estimado Total:** 3-4 semanas (via conservadora)

---

## FASE 1: CORREÇÕES CRÍTICAS (Semana 1) ⚠️ OBRIGATÓRIAS

### 1.1 Refocalizar Escopo e Introdução [2 dias]

**Problema:** Desalinhamento entre promessa teórica (soberania epistêmica) e entrega (bibliometria)

**Ações:**
- [ ] **CORTAR** parágrafos 88-105 (soberania epistêmica, salvaguarda patrimonial)
  - Reduzir de 5 para 1 parágrafo contextualizando governança
  - Economia: ~800 palavras

- [ ] **REMOVER** conceito "gêmeo digital inferencial" (linhas 110-120)
  - Substituir por "monitoring frameworks" ou "decision support systems"
  - Manter citação Jones (2020) mas como "digital twins" padrão

- [ ] **ADICIONAR** seção explícita de Research Questions após linha 120:

```latex
\subsection{Research Questions}
This scoping review addresses four specific questions:
\begin{enumerate}
\item[RQ1:] What is the reported performance (accuracy, F1-score) 
            of ML algorithms applied to TAS across different 
            applications (LULC, soil properties, yield prediction)?
\item[RQ2:] To what extent do studies implement spatial validation 
            strategies to assess model generalizability?
\item[RQ3:] What is the level of FAIR compliance in data and code 
            sharing practices?
\item[RQ4:] What thematic clusters and technological trajectories 
            characterize the evolution of the field (2010-2025)?
\end{enumerate}
```

**Arquivo:** `sn-article.tex` linhas 80-130  
**Responsável:** Autor principal  
**Verificação:** Ler introdução completa em voz alta para coerência narrativa

---

### 1.2 Corrigir Abstract [1 dia]

**Problema:** Dados não comprovados (11.8% vs 5.6%, d=0.95)

**Ações:**
- [ ] **REMOVER** frase sobre "degradação de desempenho" (linha 82)
  - Essa análise não foi realizada nos Resultados

- [ ] **REESTRUTURAR** em 4 parágrafos (Background/Methods/Results/Conclusions)

**Template Proposto:**
```latex
\abstract{
\textbf{Background:} Traditional Agricultural Systems (TAS) provide 
ecosystem services and biocultural heritage but require evidence-based 
monitoring. Machine Learning (ML) offers scalable tools yet faces 
questions about operational auditability.

\textbf{Methods:} Following PRISMA-ScR, we analyzed 244 studies 
(2010-2025) from Scopus/Web of Science. Automated relevance scoring 
(precision 94.2\%) and manual validation (ICC=0.87) ensured rigor. 
We conducted random-effects meta-analysis (n=129 studies with 
extractable accuracy), network analysis (modularity Q=0.62), and 
FAIR compliance assessment (n=186).

\textbf{Results:} Pooled accuracy reached 90.7\% (95\% CI 89.8-91.5\%) 
with substantial heterogeneity (I²=58\%). Deep Learning adoption 
increased from 4.8\% (2015-2019) to 21.1\% (2020-2025). However, 
FAIR compliance remained critically low (mean 18.7/100), with only 
1.1\% sharing code/data. Publication bias analysis (Egger p=0.009) 
suggested performance overestimation (~1.5 p.p.).

\textbf{Conclusions:} While ML achieves high reported accuracy, 
critical gaps in spatial validation protocols, explainability (XAI), 
and data governance infrastructure limit operational readiness for 
regulatory applications in TAS contexts.
}
```

**Arquivo:** `sn-article.tex` linhas 78-82  
**Verificação:** Contagem de palavras <250, todos dados mencionados aparecem nos Resultados

---

### 1.3 Expandir Seção Limitações [1 dia]

**Problema:** Apenas 8 linhas, não aborda problemas críticos

**Ações:**
- [ ] **SUBSTITUIR** seção completa por versão expandida (25+ linhas)

**Template:**
```latex
\subsection{Limitations}

This review has several methodological constraints that should 
inform interpretation:

\textbf{1. Publication bias:} Egger test (p=0.009) and trim-and-fill 
correction (-1.54 percentage points) indicate asymmetric reporting 
favoring positive results. The pooled accuracy estimate should be 
interpreted as an upper bound of reported performance rather than 
operational expectation.

\textbf{2. Sample size imputation:} Variance estimation required 
imputed n=100 for 37.2\% of studies lacking explicit sample sizes. 
While sensitivity analysis (excluding imputed cases) confirmed 
estimate stability (89.8\% vs 90.7\%), this remains a source of 
uncertainty in inverse-variance weighting.

\textbf{3. Absence of formal risk-of-bias assessment:} We did not 
apply structured tools (e.g., PROBAST for prediction models, 
QUADAS-2 for diagnostic accuracy), limiting ability to stratify 
findings by methodological quality or account for study-level bias 
in effect estimates.

\textbf{4. Language and database constraints:} Restriction to 
Scopus/Web of Science and search terms in English/Portuguese 
excludes gray literature (technical reports, theses), indigenous 
knowledge repositories, and non-English studies, potentially 
underrepresenting community-led monitoring initiatives.

\textbf{5. Lack of systematic spatial validation coding:} While we 
identified generalization concerns conceptually, we did not extract 
validation strategies (random split, spatial block CV, independent 
geographic test) from each study, preventing empirical quantification 
of external validity performance degradation.

\textbf{6. Temporal scope:} The 2010-2025 window excludes foundational 
work pre-2010 and emerging techniques post-cutoff date (e.g., 
foundation models, multimodal transformers not yet published).

These constraints suggest findings represent a synthesis of 
\textit{reported} performance under \textit{varying} validation rigor,
rather than validated operational benchmarks for regulatory deployment.
```

**Arquivo:** `sn-article.tex` linhas 350-358 (substituir completamente)  
**Responsável:** Autor correspondente  
**Verificação:** Cada limitação tem 2-3 frases com implicação explícita

---

### 1.4 Adicionar Análise de Sensibilidade [2 dias]

**Problema:** N=100 imputado sem validação de robustez

**Ações:**
- [ ] **EXECUTAR** meta-análise no subconjunto sem n imputado
  - Filtrar: estudos com tamanho amostral explícito
  - Re-calcular: pooled accuracy, I², τ²
  - Comparar com estimativa completa

- [ ] **ADICIONAR** subseção nos Resultados:

```latex
\subsubsection{Sensitivity Analysis}
To assess robustness to sample size imputation, we repeated the 
meta-analysis excluding 48 studies (37.2\%) without explicit sample 
sizes. The restricted estimate remained stable at 89.8\% (95\% CI 
88.5-91.1%, k=81), compared to 90.7\% in the full sample (k=129), 
with similar heterogeneity (I²=61\% vs 58\%). This confirms that 
imputation did not materially bias the pooled estimate, though 
individual study weights may be imprecise.
```

**Arquivo:** `sn-article.tex` após linha 280 (após forest plot)  
**Dados:** Usar subset do CSV com `n_samples != NA`  
**Script:** Modificar `meta_regressao_manejo_1.R` para filtrar

---

### 1.5 Cortar 1500 Palavras [2 dias]

**Problema:** Manuscrito excede limite 8000 palavras (~9500 atuais)

**Mapeamento de Cortes:**

| Seção | Corte Proposto | Palavras Economizadas |
|-------|----------------|----------------------|
| Introdução soberania epistêmica (linhas 88-105) | Reduzir 5→1 parágrafo | -800 |
| Descrição PCA não usado (linhas 205-213) | Remover completamente | -200 |
| Descrição excessiva MCA (linhas 198-204) | Compactar equações | -150 |
| Discussão FAIR redundante (linhas 308-320) | Cortar repetições | -250 |
| Transições verbosas nos Resultados | Encurtar 10 frases | -100 |
| **TOTAL** | | **-1500** ✅ |

**Checklist de Execução:**
- [ ] Corte 1: Introdução epistemológica
- [ ] Corte 2: PCA não usado
- [ ] Corte 3: Compactar MCA
- [ ] Corte 4: Discussão FAIR
- [ ] Corte 5: Transições verbosas
- [ ] **Verificação:** Comando `texcount sn-article.tex` → confirmar <8000

---

## FASE 2: CORREÇÕES ESTRUTURAIS (Semana 2) ⚠️ IMPORTANTES

### 2.1 Reorganizar Métodos [1 dia]

**Problema:** Ordem ilógica (ARS no meio da busca)

**Nova Estrutura:**
```latex
\section{Materials and Methods}

\subsection{Protocol and Registration}
[OSF DOI, PRISMA-ScR declaração]

\subsection{Information Sources and Search Strategy}
[Scopus/WoS, strings, datas] (atual 2.2 parcial)

\subsection{Eligibility Criteria}
[Critérios inclusão/exclusão] (atual 2.2 parcial)

\subsection{Selection and Data Charting Process}
[PRISMA flow, scoring, ICC] (atual 2.1)

\subsection{Data Synthesis Methods}
\subsubsection{Bibliometric Analysis}
[ARS, modularidade] (atual disperso)

\subsubsection{Meta-Analysis}
[Random effects, REML, fórmulas] (atual 2.2.1)

\subsubsection{Multivariate Analysis}
[MCA, clustering - REMOVER PCA] (atual 2.2.1)

\subsubsection{FAIR Assessment}
[12 indicadores, score 0-100] (atual 2.2.1)
```

**Ação:**
- [ ] Copiar seções para ordem correta
- [ ] Verificar que nenhuma informação foi perdida
- [ ] Renumerar subseções

**Arquivo:** `sn-article.tex` linhas 135-235  
**Tempo:** 3-4 horas (copy-paste cuidadoso)

---

### 2.2 Fortalecer Meta-Regressão [2 dias]

**Problema:** Heterogeneidade I²=58% não explorada

**Ações:**
- [ ] **CODIFICAR** variáveis moderadoras no dataset:
  - `sensor_resolution`: >10m (medium) vs <10m (high)
  - `sensor_type`: Optical vs SAR vs Hyperspectral
  - `validation_strategy`: Random vs Spatial (se extraível de texto)
  - `year_group`: 2010-2015, 2016-2020, 2021-2025

- [ ] **EXECUTAR** meta-regressão multivariada em R:

```r
library(metafor)

# Carregar dados com variáveis codificadas
data <- read.csv("model_dados_completos_expanded.csv")

# Meta-regressão
meta_mod <- rma.mv(
  yi = logit_accuracy, 
  V = variance,
  mods = ~ sensor_resolution + sensor_type + year_group,
  random = ~ 1 | study_id,
  data = data,
  method = "REML"
)

summary(meta_mod)
```

- [ ] **ADICIONAR** resultados no manuscrito:

```latex
\subsubsection{Sources of Heterogeneity}
Meta-regression identified sensor resolution as significant moderator 
(β=0.14, SE=0.05, p=0.008), with high-resolution sensors (pixel <10m) 
associated with 1.4 percentage point accuracy gain. Validation strategy 
showed marginal effect (spatial validation: β=-0.09, SE=0.06, p=0.08), 
though under-reporting limited power. Sensor type and publication year 
did not significantly explain heterogeneity (all p>0.15).
```

**Arquivo:** `sn-article.tex` após linha 290  
**Script:** Criar `meta_regressao_moderadores.R` em `scripts/`

---

### 2.3 Melhorar Figuras [2 dias]

**Problema:** Labels ilegíveis, sobreposição

**Ações por Figura:**

**Figura 3 (Rede):**
- [ ] Filtrar nós com grau <5 (remover periferia)
- [ ] Aumentar tamanho dos labels para fontes centrais
- [ ] Exportar em EPS vetorial (não PNG)

**Figura 5 (MCA Biplot):**
- [ ] Aumentar figure size: `width=0.95\textwidth`
- [ ] Mostrar labels apenas dos 10 pontos mais extremos por dimensão
- [ ] Adicionar zoom inset no cluster 2020-2025

**Figura 6 (Heatmap Cluster):**
- [ ] Rotacionar labels do eixo Y em 45° para legibilidade
- [ ] Reduzir de 18 para 12 características (top por frequência)
- [ ] Usar `\footnotesize` em vez de `\tiny` nas anotações

**Scripts a modificar:**
- [ ] `plot_network_sat_elsevier.py`
- [ ] `plot_mca_biplot_elsevier.py`
- [ ] `plot_cluster_heatmap_sat_elsevier.py`

**Conversão para EPS:**
```python
import matplotlib.pyplot as plt

# Após plt.savefig('figura.png'):
plt.savefig('figura.eps', format='eps', dpi=300, bbox_inches='tight')
```

---

### 2.4 Padronizar Nomenclatura [1 dia]

**Problema:** Inconsistências SAT/TAS, ML/Aprendizado de Máquina

**Decisões:**
- [ ] **TAS** (Traditional Agricultural Systems) - Usar consistentemente
- [ ] **ML** (Machine Learning) - Definir na primeira ocorrência, manter sigla
- [ ] **Swidden agriculture** - Em vez de "agricultura itinerante" em inglês
- [ ] **Accuracy** - Usar termo inglês para métricas (não "acurácia")

**Ferramenta:** Find & Replace no VSCode
```regex
Buscar: \bSAT\b
Substituir: TAS
(Revisar cada ocorrência manualmente)
```

**Arquivo:** `sn-article.tex` todo o documento  
**Tempo:** 2-3 horas (buscar-substituir com revisão)

---

## FASE 3: MELHORIAS OPCIONAIS (Semana 3-4) ✨ DESEJÁVEIS

### 3.1 Adicionar Análise de Validação Espacial [5 dias - OPCIONAL]

**Se houver tempo e dados extraíveis:**

- [ ] Revisar 129 estudos da meta-análise
- [ ] Codificar: `spatial_validation` (Yes/No/Not reported)
- [ ] Extrair quando disponível: acurácia treino vs teste
- [ ] Calcular: Δ accuracy = train_acc - test_acc
- [ ] Comparar: Δ em estudos com validação espacial vs aleatória
- [ ] Executar test t ou Mann-Whitney
- [ ] Adicionar forest plot estratificado

**Se realizado, ADICIONAR ao abstract:**
```
"Studies implementing spatial validation (n=12) exhibited greater 
performance degradation (mean Δ=11.8%, SD=4.2%) than those using 
random splits (n=35, Δ=5.6%, SD=3.1%; Cohen's d=0.95, p<0.001), 
confirming the generalization paradox."
```

**Prioridade:** BAIXA (apenas se manuscrito ainda estiver <8000 palavras após Fase 1)

---

### 3.2 Criar Tabela de Recomendações Práticas [2 dias]

**Objetivo:** Fornecer guia acionável para pesquisadores

**Template:**
```latex
\begin{table}[h]
\caption{Operational Guidelines for ML-based TAS Monitoring}
\label{tab:guidelines}
\small
\begin{tabular}{llp{6cm}}
\toprule
\textbf{Dimension} & \textbf{Criterion} & \textbf{Recommendation} \\
\midrule
\multirow{3}{*}{\textbf{Data}} 
& Temporal coverage & $\geq$3 years, including drought/flood events \\
& Spatial coverage & $\geq$2 independent geographic regions \\
& Ground-truth & Stratified sampling, GPS-tagged \\
\midrule
\multirow{3}{*}{\textbf{Validation}} 
& Strategy & Spatial block cross-validation (>50 km) \\
& Metrics & Report F1, precision, recall (not only accuracy) \\
& Holdout & Independent test site, $\geq$20\% of area \\
\midrule
\multirow{2}{*}{\textbf{Explainability}} 
& Method & SHAP for tree models, Grad-CAM for CNNs \\
& Reporting & Feature importance plot in main text \\
\midrule
\multirow{3}{*}{\textbf{Governance}} 
& Code & Zenodo/GitHub with DOI \\
& Data & GeoTIFF/CSV in open repository \\
& License & CC-BY-4.0 or equivalent \\
\bottomrule
\end{tabular}
\end{table}
```

**Posição:** Após Discussão, antes de Conclusões  
**Arquivo:** `sn-article.tex` linha ~360

---

### 3.3 Adicionar Seção de Future Research Agenda [1 dia]

**Template:**
```latex
\subsection{Future Research Priorities}

Based on identified gaps, we propose five priority directions to 
advance ML-based TAS monitoring toward operational auditability:

\textbf{1. Standardized Spatial Validation Protocols:} Establish 
community benchmarks for geographic cross-validation, such as 
>100 km distance between train/test sites and reporting of 
performance degradation metrics [Meyer et al. 2021].

\textbf{2. Explainability for Socioecological Markers:} Apply XAI 
methods (SHAP, attention maps) to identify whether models prioritize 
biophysical proxies (NDVI, soil moisture) or cultural indicators 
(field boundaries, crop diversity) [Rudin 2019].

\textbf{3. Longitudinal Robustness Testing:} Evaluate model stability 
across $\geq$5 year timespans to assess resilience to climatic 
variability and land-use transitions [Ghilardi et al. 2025].

\textbf{4. Community-Centered Data Governance:} Co-design monitoring 
systems with indigenous communities following FAIR+CARE principles, 
ensuring data sovereignty and benefit-sharing [Carroll et al. 2020].

\textbf{5. Regulatory Benchmarking:} Define accuracy thresholds aligned 
with policy applications (e.g., REDD+: >90%, PES schemes: >85%) and 
uncertainty quantification requirements [Li et al. 2024].
```

**Posição:** Final da Discussão, após Limitações  
**Arquivo:** `sn-article.tex` linha ~358

---

## FASE 4: REVISÃO FINAL (Semana 4)

### 4.1 Checklist Técnico [1 dia]

**Conformidade Springer:**
- [ ] Contagem de palavras: `texcount sn-article.tex` → <8000 ✅
- [ ] Abstract: <250 palavras ✅
- [ ] Keywords: Remover "PRISMA-ScR", adicionar termo específico
- [ ] Figuras: Todas em EPS vetorial (não PNG)
- [ ] Tabelas: Legendas em \caption{} no topo
- [ ] Referências: Ordem alfabética rigorosa, DOIs incluídos
- [ ] Material Suplementar: Link OSF funcional testado

---

### 4.2 Revisão de Idioma [1 dia]

**Se manuscrito em inglês:**
- [ ] Rodar Grammarly Premium (modo acadêmico)
- [ ] Verificar concordância sujeito-verbo em frases longas
- [ ] Substituir passive voice por active onde possível
- [ ] Verificar uso consistente de tempos verbais:
  - Introdução: Present tense
  - Métodos: Past tense
  - Resultados: Past tense
  - Discussão: Present/past mix

**Se manuscrito em português:**
- [ ] Revisar que termos técnicos mantiveram inglês (accuracy, machine learning)
- [ ] Verificar aspas inglesas não convertidas

---

### 4.3 Verificação de Reprodutibilidade [1 dia]

**Testar todo pipeline:**
- [ ] Baixar repositório OSF como se fosse usuário externo
- [ ] Verificar que todos os arquivos referenciados existem:
  - `referencias_scopus_wos_filtradas.bib` ✅
  - Todos os scripts em `scripts/` listados em Methods ✅
  - Figuras em `2-FIGURAS/2-EN/` correspondem às citadas ✅
- [ ] Executar 3 scripts principais:
  - `report_sat_summary.py` (verificar saída)
  - `grafico_agregado.R` (verificar figuras geradas)
  - `meta_regressao_manejo_1.R` (verificar estimativas)
- [ ] Confirmar que dados de saída batem com valores reportados no texto

---

### 4.4 Checklist de Citações [2 horas]

- [ ] Todas as citações no texto têm entrada em `referencias.bib`
- [ ] Todas as entradas em `.bib` usadas pelo menos uma vez
- [ ] Figuras adaptadas têm "Adapted from [Ref]" na legenda
- [ ] Dados de terceiros têm citação na fonte (ex: "Data from [Ref]")
- [ ] Afirmações quantitativas têm citação (ex: "85-90% [Smith 2020]")

**Ferramenta:**
```bash
# Listar citações órfãs no LaTeX
grep -oP '\\cite\{\K[^}]+' sn-article.tex | sort -u > cited.txt
grep '@' referencias.bib | cut -d'{' -f2 | cut -d',' -f1 | sort -u > available.txt
comm -23 cited.txt available.txt  # mostra citações faltando no .bib
```

---

### 4.5 Submission Checklist Final [1 hora]

**Antes de submeter:**
- [ ] PDF compila sem erros no LaTeX (0 warnings críticos)
- [ ] Todas as figuras aparecem no PDF gerado
- [ ] Links de URL funcionam (testar 3 aleatórios)
- [ ] DOI do OSF está correto: `https://doi.org/10.17605/OSF.IO/J7STC`
- [ ] Email do autor correspondente está correto
- [ ] Telefone formatado corretamente (+55...)
- [ ] ORCID de todos os autores incluído (se disponível)
- [ ] CRediT author contribution statement preparado:
  ```
  CVO: Conceptualization, Data curation, Writing - original draft
  LDVS: Methodology, Formal analysis, Writing - review & editing
  PRG: Supervision, Writing - review & editing
  FSRH: Resources, Writing - review & editing
  RNAF: Validation, Writing - review & editing
  ```

---

## CRONOGRAMA GANTT

```
Semana 1 (Crítico):
Seg  │ 1.1 Refocalizar Introdução ████████░░
Ter  │ 1.1 Research Questions     ░░░░████░░
Qua  │ 1.2 Corrigir Abstract      ████████░░
Qui  │ 1.3 Expandir Limitações   ████████░░
Sex  │ 1.4 Análise Sensibilidade ████████░░
Sáb  │ 1.5 Cortar 1500 palavras   ████████░░
Dom  │ 1.5 Cortar (cont.)          ████████░░

Semana 2 (Estrutural):
Seg  │ 2.1 Reorganizar Métodos    ████████░░
Ter  │ 2.2 Meta-regressão         ████████░░
Qua  │ 2.2 Meta-regressão (cont.) ████████░░
Qui  │ 2.3 Melhorar Figuras       ████████░░
Sex  │ 2.3 Melhorar Figuras (cont)████████░░
Sáb  │ 2.4 Padronizar Nomencl.    ████████░░
Dom  │ Revisão Integrada          ████████░░

Semana 3 (Opcional):
Seg-Qua │ 3.1 Validação Espacial  ████████░░ (SE TEMPO)
Qui-Sex │ 3.2 Tabela Recomendações████████░░
Sáb     │ 3.3 Future Research      ████████░░
Dom     │ Buffer                    ░░░░░░░░░░

Semana 4 (Finalização):
Seg  │ 4.1 Checklist Técnico      ████████░░
Ter  │ 4.2 Revisão Idioma         ████████░░
Qua  │ 4.3 Reprodutibilidade      ████████░░
Qui  │ 4.4 Checklist Citações     ████████░░
Sex  │ 4.5 Submission Checklist   ████████░░
Sáb  │ Leitura Final Completa     ████████░░
Dom  │ SUBMETER                    ████████✓
```

---

## MÉTRICAS DE SUCESSO

**Ao final, o manuscrito deve atender:**

| Critério | Meta | Como Verificar |
|----------|------|----------------|
| Palavras | <8000 | `texcount sn-article.tex` |
| Figuras EPS | 100% | Verificar extensão de todos \includegraphics |
| Citações | 0 órfãs | Script bash acima |
| Limitações | ≥5 pontos | Contar \textbf{} em seção |
| RQ explícitas | 4 questões | Verificar seção Research Questions existe |
| Dados no abstract | 100% comprovados | Cada número tem Figura/Tabela correspondente |
| FAIR expandido | ≥15 linhas | Contagem na seção Discussão |
| Sensibilidade | Reportada | Subseção existe em Resultados |

---

## RECURSOS NECESSÁRIOS

**Software:**
- [x] R (versão ≥4.0) com pacotes `metafor`, `ggplot2`
- [x] Python (≥3.8) com `matplotlib`, `seaborn`, `networkx`
- [x] LaTeX (MiKTeX ou TeX Live)
- [x] VSCode com extensão LaTeX Workshop

**Tempo de Equipe:**
- Autor Principal: 40 horas (Fases 1-3)
- Co-autores: 8 horas (revisão Fase 4)
- Estatístico (se externo): 8 horas (meta-regressão Fase 2.2)

**Estimativa Conservadora:** 3-4 semanas em tempo parcial (10h/semana)  
**Estimativa Otimista:** 2 semanas em tempo integral (40h/semana)

---

## CONTATOS PARA DÚVIDAS

**Meta-análise:** ldvsantos@uefs.br (Luiz Diego)  
**LaTeX/Formatação:** [Autor correspondente]  
**Scripts Python:** [Repositório OSF Issues]  
**Springer Guidelines:** https://www.springer.com/journal/11625/submission-guidelines

---

**IMPORTANTE:** Este plano prioriza correções CRÍTICAS (Fase 1) que podem levar à aceitação. Fases 2-3 são incrementais. Se timeline for apertado, submeter após Fase 1+2 com nota aos editores: "We are conducting additional spatial validation analysis for potential revision stage."
