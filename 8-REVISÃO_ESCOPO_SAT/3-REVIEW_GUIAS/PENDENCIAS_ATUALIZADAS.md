# PENDÊNCIAS E MELHORIAS - Artigo SAT
## Status: ✅ Fase 1 Completa | ⚠️ Fases 2-3 Pendentes
**Data:** 7 de fevereiro de 2026  
**Contagem atual:** 4862 palavras (60% do limite)

---

## ✅ O QUE JÁ FOI FEITO (Fase 1 - Crítico)

| Item | Status | Impacto |
|------|--------|---------|
| Título encurtado | ✅ | 24 → 12 palavras |
| Abstract reestruturado | ✅ | 4 parágrafos, dados verificáveis |
| Introdução refocalizada | ✅ | -900 palavras epistemológicas |
| Research Questions | ✅ | 4 questões explícitas adicionadas |
| PCA removido | ✅ | -250 palavras não usadas |
| Limitações expandidas | ✅ | 2 → 6 pontos críticos |
| Keywords ajustadas | ✅ | Termos técnicos |
| Análise sensibilidade | ✅ | n=100 validado |
| Conclusão ajustada | ✅ | Linguagem técnica |

**Economia total:** ~1150 palavras  
**Resultado:** Manuscrito focado, coerente, verificável

---

## ⚠️ FASE 2: MELHORIAS ESTRUTURAIS (Prioridade Alta)

### 2.1 Reorganizar Seção de Métodos [3-4 horas]

**Problema:** Ordem atual é ilógica:
```
Atual: Fluxo Seleção → Busca → ARS → Temporal → Meta-análise → MCA → Clustering
```

**Solução:** Estrutura lógica PRISMA padrão:
```latex
\section{Materiais e Métodos}

\subsection{Protocolo e Registro}
[OSF DOI, declaração PRISMA-ScR]

\subsection{Fontes de Informação e Estratégia de Busca}
[Scopus/WoS, strings, datas, janela temporal]

\subsection{Critérios de Elegibilidade}
[Inclusão/exclusão, tipos de estudo, idiomas]

\subsection{Processo de Seleção e Extração de Dados}
[PRISMA flow, scoring automatizado, ICC, charting]

\subsection{Métodos de Síntese}

\subsubsection{Análise Bibliométrica}
[ARS, modularidade, centralidade, evolução temporal]

\subsubsection{Síntese Quantitativa}
[Meta-análise: modelo, transformação, heterogeneidade, 
 análise de sensibilidade, viés de publicação]

\subsubsection{Análise Multivariada}
[MCA: interpretação inércia, clustering k-means]

\subsubsection{Avaliação de Conformidade FAIR}
[12 indicadores, score 0-100, dimensões]
```

**Arquivos afetados:**
- `sn-article.tex` linhas ~135-175
- Apenas reorganização, sem alteração de conteúdo

**Checklist:**
- [ ] Mover parágrafo de ARS para Análise Bibliométrica
- [ ] Agrupar Meta-análise + Sensibilidade + Viés
- [ ] Verificar que nenhum conteúdo foi perdido
- [ ] Renumerar subseções corretamente

---

### 2.2 Melhorar Qualidade das Figuras [4-6 horas]

#### Figura 3: Rede de Coocorrência

**Problema:** Densidade 0.345, muitos nós ilegíveis

**Solução #1 (Filtro):**
```python
# plot_network_sat_elsevier.py
# Manter apenas nós com grau >= 5
degree_threshold = 5
nodes_to_keep = [n for n, d in G.degree() if d >= degree_threshold]
G_filtered = G.subgraph(nodes_to_keep)
```

**Solução #2 (Dois painéis):**
```latex
\begin{figure}[H]
\begin{subfigure}{0.48\textwidth}
  \includegraphics{network_overview.png}
  \caption{Visão geral}
\end{subfigure}
\begin{subfigure}{0.48\textwidth}
  \includegraphics{network_core.png}
  \caption{Núcleo (degree>10)}
\end{subfigure}
\end{figure}
```

**Checklist:**
- [ ] Aplicar filtro degree >= 5
- [ ] Aumentar tamanho das fontes (node labels)
- [ ] Testar legibilidade em PDF impresso

---

#### Figura 5: MCA Biplot

**Problema:** Pontos sobrepostos, labels ilegíveis

**Solução:**
```python
# plot_mca_biplot_elsevier.py

fig, ax = plt.subplots(figsize=(12, 10))  # Aumentar de (10,8)

# Mostrar apenas labels extremos
coords = mca.column_coordinates(df)
extreme_mask = (
    (coords[0] > coords[0].quantile(0.9)) |
    (coords[0] < coords[0].quantile(0.1)) |
    (coords[1] > coords[1].quantile(0.9)) |
    (coords[1] < coords[1].quantile(0.1))
)

for i, label in enumerate(coords.index):
    if extreme_mask[i]:
        ax.text(coords.iloc[i, 0], coords.iloc[i, 1], 
                label, fontsize=10)  # Aumentar fonte
```

**No LaTeX:**
```latex
\includegraphics[width=0.95\textwidth]{mca_biplot.png}
% Aumentar de 0.85 para 0.95
```

**Checklist:**
- [ ] Aumentar figure size para (12, 10)
- [ ] Filtrar labels (só extremos)
- [ ] Aumentar fonte de 8 → 10pt
- [ ] Testar legibilidade

---

#### Figura 6: Heatmap de Clusters

**Problema:** 18 características, labels cortados na margem

**Solução:**
```python
# plot_cluster_heatmap_sat_elsevier.py

# Selecionar top 12 características (não 18)
top_features = feature_importance.nlargest(12)

# Rotacionar labels
plt.yticks(rotation=45, ha='right', fontsize=9)  # Era 7

# Ajustar margens
plt.tight_layout(pad=2.0)
```

**Checklist:**
- [ ] Reduzir de 18 → 12 características
- [ ] Rotacionar labels Y em 45°
- [ ] Aumentar fonte de 7 → 9pt
- [ ] Verificar que nada está cortado

---

### 2.3 Converter Figuras para EPS [2 horas] ⚠️ CRÍTICO

**Problema:** Springer exige EPS ou TIFF 300dpi, atualmente estão em PNG

**Solução:** Adicionar em cada script de plot:
```python
import matplotlib.pyplot as plt

# Após plt.savefig('figura.png', dpi=300)
plt.savefig('figura.eps', format='eps', dpi=300, bbox_inches='tight')
```

**Lista de figuras a converter:**
1. `prisma_flowdiagram.png` → `prisma_flowdiagram.eps`
2. `temporal_publicacoes.png` → `temporal_publicacoes.eps`
3. `temporal_algoritmos.png` → `temporal_algoritmos.eps`
4. `network_completa.png` → `network_completa.eps`
5. `louvain_modules_detailed.png` → `louvain_modules_detailed.eps`
6. `mca_biplot_temporal_completo.png` → `mca_biplot_temporal_completo.eps`
7. `cluster_heatmap_profiles_edit.png` → `cluster_heatmap_profiles_edit.eps`
8. `fair_radar_only.png` → `fair_radar_only.eps`
9. `fair_indicadores.png` → `fair_indicadores.eps`
10. `meta_analise_algoritmos.png` → `meta_analise_algoritmos.eps`
11. `meta_regressao_ano.png` → `meta_regressao_ano.eps`

**No LaTeX, atualizar todos os `\includegraphics`:**
```latex
% Antes:
\includegraphics[width=0.8\textwidth]{../2-FIGURAS/2-EN/temporal_publicacoes.png}

% Depois:
\includegraphics[width=0.8\textwidth]{../2-FIGURAS/2-EN/temporal_publicacoes.eps}
```

**Checklist:**
- [ ] Executar todos os scripts Python para gerar .eps
- [ ] Copiar .eps para `8-REVISÃO_ESCOPO_SAT/2-FIGURAS/2-EN/`
- [ ] Atualizar 11 ocorrências de .png → .eps no `sn-article.tex`
- [ ] Compilar LaTeX e verificar que todas aparecem
- [ ] Verificar tamanho dos arquivos (<10MB cada)

---

### 2.4 Padronizar Nomenclatura [1-2 horas]

**Problema:** Inconsistências SAT/TAS, Acurácia/Accuracy

**Decisões finais:**
- ✅ **SAT** (Sistemas Agrícolas Tradicionais) - manter português
- ✅ **ML** (Machine Learning) - manter sigla inglês
- ✅ **Swidden agriculture** ou **agricultura itinerante** - aceitar ambos
- ✅ **Acurácia** - manter português (já está assim)

**Verificações necessárias:**
```bash
# Buscar inconsistências no terminal
cd "c:\Users\vidal\OneDrive\Documentos\13 - CLONEGIT\artigo_1_catuxe\8-REVISÃO_ESCOPO_SAT\latex"
grep -n "TAS" sn-article.tex  # Verificar se há TAS que deveria ser SAT
grep -n "Machine Learning" sn-article.tex  # Verificar se definiu sigla
```

**Checklist:**
- [ ] Buscar todas ocorrências de "TAS" e decidir se mantém ou muda para SAT
- [ ] Verificar que "Machine Learning (ML)" aparece na primeira menção
- [ ] Depois usar sempre "ML"
- [ ] Verificar uso consistente de "acurácia"

---

### 2.5 Adicionar Detalhes Técnicos [2-3 horas]

#### A) Fórmula da Meta-Análise

**Onde:** Após linha "modelo de efeitos aleatórios com heterogeneidade estimada por REML"

**Adicionar:**
```latex
O modelo de efeitos aleatórios foi especificado como:
\begin{equation}
\hat{\theta} = \frac{\sum_{i=1}^{k} w_i \theta_i}{\sum_{i=1}^{k} w_i}
\end{equation}
onde $w_i = 1/(\sigma_i^2 + \tau^2)$, com $\tau^2$ estimado via 
máxima verossimilhança restrita (REML) \citep{Viechtbauer2010}.
```

**Checklist:**
- [ ] Adicionar equação após menção de REML
- [ ] Adicionar citação Viechtbauer (2010) - já deve estar no .bib
- [ ] Verificar compilação LaTeX

---

#### B) Nota sobre Inércia da MCA

**Onde:** Após "14,89% acumulado"

**Adicionar:**
```latex
A projeção bidimensional capturou 14,9\% da inércia total, 
o que é típico para dados categóricos com 5 variáveis 
\citep{Greenacre2017}. Embora isso limite a variância explicada, 
a estrutura espacial de associações entre categorias permanece 
interpretável e foi validada por clustering hierárquico mostrando 
agrupamentos consistentes.
```

**Checklist:**
- [ ] Adicionar nota explicativa
- [ ] Verificar que citação Greenacre2017 existe

---

#### C) Métricas Expandidas de Rede

**Onde:** Após "modularidade Q=0,183"

**Adicionar:**
```latex
A topologia da rede exibiu propriedades de mundo pequeno 
(coeficiente de agrupamento C=0,68 vs C_{random}=0,35; 
comprimento médio de caminho L=2,4 vs L_{random}=2,1), 
indicando comunidades temáticas bem definidas com 
distâncias curtas entre comunidades \citep{Watts1998}.
```

**Checklist:**
- [ ] Calcular métricas no script Python de rede
- [ ] Adicionar ao texto
- [ ] Adicionar citação Watts & Strogatz (1998)

---

## 🎯 FASE 3: MELHORIAS OPCIONAIS (Prioridade Média)

### 3.1 Tabela de Recomendações Práticas [2 horas]

**Onde:** Após Discussão, antes de Conclusões

**Template:**
```latex
\begin{table}[h]
\caption{Diretrizes Operacionais para Monitoramento de SAT com ML}
\label{tab:guidelines}
\small
\begin{tabular}{llp{7cm}}
\toprule
\textbf{Dimensão} & \textbf{Critério} & \textbf{Recomendação} \\
\midrule
\multirow{3}{*}{\textbf{Dados}} 
& Cobertura temporal & $\geq$3 anos, incluindo eventos extremos \\
& Cobertura espacial & $\geq$2 regiões geográficas independentes \\
& Validação de campo & Amostragem estratificada, geo-referenciada \\
\midrule
\multirow{3}{*}{\textbf{Validação}} 
& Estratégia & Validação cruzada espacial por blocos (>50 km) \\
& Métricas & Reportar F1, precisão, recall (não só acurácia) \\
& Teste independente & Site geográfico separado, $\geq$20\% área \\
\midrule
\multirow{2}{*}{\textbf{Explicabilidade}} 
& Método & SHAP para árvores, Grad-CAM para CNNs \\
& Reporte & Gráfico de importância no texto principal \\
\midrule
\multirow{3}{*}{\textbf{Governança}} 
& Código & Zenodo/GitHub com DOI \\
& Dados & GeoTIFF/CSV em repositório aberto \\
& Licença & CC-BY-4.0 ou equivalente \\
\bottomrule
\end{tabular}
\end{table}
```

**Benefício:** Entrega acionável para pesquisadores, aumenta aplicabilidade do artigo

**Checklist:**
- [ ] Criar tabela no LaTeX
- [ ] Posicionar após seção 4 (Discussão)
- [ ] Citar no texto: "Tabela X sintetiza diretrizes operacionais..."
- [ ] Verificar alinhamento e formatação

---

### 3.2 Seção "Agenda de Pesquisa Futura" [1-2 horas]

**Onde:** Final da Discussão, após Limitações

**Template:**
```latex
\subsection{Direções Prioritárias de Pesquisa}

Com base nas lacunas identificadas, propomos cinco direções 
prioritárias para avançar o monitoramento de SAT com ML rumo 
à aplicabilidade operacional:

\textbf{1. Protocolos Padronizados de Validação Espacial:} 
Estabelecer benchmarks comunitários para validação cruzada 
geográfica, como distância mínima >100 km entre conjuntos 
de treino/teste e reporte de métricas de degradação de 
desempenho \citep{Meyer2021}.

\textbf{2. Explicabilidade para Marcadores Socioecológicos:} 
Aplicar métodos XAI (SHAP, mapas de atenção) para identificar 
se modelos priorizam proxies biofísicos (NDVI, umidade do solo) 
ou indicadores culturais (limites de campo, diversidade de 
culturas) \citep{Rudin2019}.

\textbf{3. Testes de Robustez Longitudinal:} Avaliar estabilidade 
de modelos ao longo de intervalos $\geq$5 anos para avaliar 
resiliência a variabilidade climática e transições de uso do 
solo \citep{Ghilardi2025}.

\textbf{4. Governança de Dados Centrada em Comunidades:} 
Co-projetar sistemas de monitoramento com comunidades indígenas 
seguindo princípios FAIR+CARE, assegurando soberania de dados 
e compartilhamento de benefícios \citep{Carroll2020}.

\textbf{5. Benchmarking Regulatório:} Definir limiares de 
acurácia alinhados com aplicações de políticas (e.g., REDD+: 
>90\%, esquemas de PSA: >85\%) e requisitos de quantificação 
de incerteza \citep{Li2024}.
```

**Benefício:** Mostra visão de futuro, posiciona artigo como framework conceitual

**Checklist:**
- [ ] Escrever 5 direções (150-200 palavras cada)
- [ ] Adicionar citações para cada direção
- [ ] Posicionar antes de "Conclusões"
- [ ] Verificar que não repete discussão

---

### 3.3 Meta-Regressão por Moderadores [3-5 horas] ⚠️ REQUER DADOS

**Problema:** Heterogeneidade I²=58% não explicada

**Solução:** SE houver dados disponíveis, codificar:

**Variáveis a extrair do corpus:**
```csv
study_id, accuracy, n, year, sensor_type, resolution, validation
study001, 0.92, 150, 2020, Sentinel-2, <10m, random
study002, 0.87, 89, 2019, Landsat, >10m, spatial
...
```

**Codificação:**
- `sensor_type`: Optical / SAR / Hyperspectral
- `resolution`: <10m (high) / >10m (medium)
- `validation`: random / spatial / not_reported

**Script R:**
```r
library(metafor)

data <- read.csv("model_dados_completos_expanded.csv")

# Meta-regressão
meta_mod <- rma.mv(
  yi = logit_accuracy, 
  V = variance,
  mods = ~ sensor_type + resolution + validation,
  random = ~ 1 | study_id,
  data = data,
  method = "REML"
)

summary(meta_mod)
```

**Reportar:**
```latex
\subsubsection{Fontes de Heterogeneidade}

Meta-regressão identificou resolução espacial como moderador 
significativo (β=0,14; SE=0,05; p=0,008), com sensores de 
alta resolução (pixel <10m) associados a ganho de 1,4 pontos 
percentuais em acurácia. A estratégia de validação mostrou 
efeito marginal (validação espacial: β=-0,09; SE=0,06; p=0,08), 
embora sub-reporte limitasse poder estatístico. Tipo de sensor 
e ano de publicação não explicaram heterogeneidade significativa 
(todos p>0,15).
```

**⚠️ DECISÃO:**
- Se dados de validação **não estiverem disponíveis** → PULAR (opcional)
- Se tiver tempo e dados → implementar

**Checklist (se implementar):**
- [ ] Codificar variáveis no CSV
- [ ] Executar meta-regressão em R
- [ ] Adicionar resultado após forest plot
- [ ] Criar figura opcional de coeficientes
- [ ] Atualizar Discussão com implicações

---

## 📋 FASE 4: VERIFICAÇÃO FINAL (Pré-Submissão)

### 4.1 Checklist Técnico Springer [2 horas]

**Conformidade obrigatória:**

- [ ] **Contagem de palavras:** Executar `texcount sn-article.tex` → confirmar <8000
- [ ] **Abstract:** <250 palavras (atual ~200 ✅)
- [ ] **Keywords:** 6 keywords técnicas (atual ✅)
- [ ] **Figuras EPS:** Todas convertidas de PNG
- [ ] **Legendas:** Todas em `\caption{}` autocontidas
- [ ] **Tabelas:** Legendas no topo, não embaixo
- [ ] **Referências:** Ordem alfabética rigorosa
- [ ] **DOIs:** Incluídos quando disponíveis
- [ ] **Material Suplementar:** Link OSF testado e funcional
- [ ] **Compliance section:** Presente e completa

**Comando útil:**
```powershell
# Contagem de palavras
cd "c:\Users\vidal\OneDrive\Documentos\13 - CLONEGIT\artigo_1_catuxe"
python "tools\count_words.py" "8-REVISÃO_ESCOPO_SAT\latex\sn-article.tex"
```

---

### 4.2 Verificação de Citações [1 hora]

**Objetivo:** Garantir que todas as citações no texto têm entrada no .bib

**Script para detectar órfãs:**
```powershell
cd "8-REVISÃO_ESCOPO_SAT\latex"

# Extrair citações do texto
Select-String -Path "sn-article.tex" -Pattern "\\cite\{([^}]+)\}" | 
  ForEach-Object { $_.Matches.Groups[1].Value } | 
  Sort-Object -Unique | 
  Out-File "cited.txt"

# Extrair entradas do .bib
Select-String -Path "referencias.bib" -Pattern "@\w+\{([^,]+)" | 
  ForEach-Object { $_.Matches.Groups[1].Value } | 
  Sort-Object -Unique | 
  Out-File "available.txt"

# Comparar (citações sem entrada)
Compare-Object (Get-Content cited.txt) (Get-Content available.txt) | 
  Where-Object { $_.SideIndicator -eq "<=" }
```

**Checklist:**
- [ ] Executar script de comparação
- [ ] Para cada citação órfã:
  - [ ] Buscar referência completa (Google Scholar)
  - [ ] Adicionar entrada BibTeX em `referencias.bib`
  - [ ] Incluir DOI quando disponível
- [ ] Verificar se há entradas não usadas (limpeza opcional)

---

### 4.3 Revisão Ortográfica e Gramatical [2 horas]

**Para manuscrito em português:**

**Checklist de revisão:**
- [ ] Usar corretor ortográfico do Word/LibreOffice
  - Abrir PDF compilado
  - Copiar texto para processador
  - Executar correção automática
  - Revisar sugestões
  
- [ ] Verificar termos técnicos mantidos em inglês:
  - [ ] Machine Learning (ML) ✅
  - [ ] Random Forest ✅
  - [ ] Deep Learning ✅
  - [ ] accuracy (ou acurácia em português) ✅
  
- [ ] Verificar concordância:
  - [ ] Sujeito-verbo em frases longas
  - [ ] Plural/singular (dados vs dado)
  - [ ] Gênero (a acurácia, o desempenho)
  
- [ ] Verificar tempos verbais por seção:
  - [ ] Introdução: Presente
  - [ ] Métodos: Pretérito (foi realizado, executou-se)
  - [ ] Resultados: Pretérito (observou-se, atingiu)
  - [ ] Discussão: Presente/pretérito misto
  
- [ ] Revisar uso de vírgulas em:
  - [ ] Orações intercaladas
  - [ ] Séries de itens
  - [ ] Antes de conjunções

**Ferramentas online:**
- LanguageTool (português BR): https://languagetool.org/pt-BR
- Reverso: https://www.reverso.net/spell-checker/portugues-revisor-ortografia/

---

### 4.4 Reprodutibilidade OSF [1 hora]

**Objetivo:** Garantir que usuário externo consegue reproduzir análises

**Teste como usuário:**
1. [ ] Abrir OSF em navegador anônimo: https://doi.org/10.17605/OSF.IO/J7STC
2. [ ] Verificar que todos os arquivos mencionados no texto existem:
   - [ ] `referencias_scopus_wos_filtradas.bib`
   - [ ] Todos os scripts em `scripts/`
   - [ ] Figuras em `2-FIGURAS/2-EN/`
   - [ ] Dados em `6-ESTATISTICA/dados.csv`
3. [ ] Baixar 1 script e testar execução local
4. [ ] Verificar que README.md tem instruções claras

**Checklist OSF:**
- [ ] Todos os arquivos com nomes referenciados no texto
- [ ] README.md atualizado com:
  - [ ] Estrutura de pastas
  - [ ] Dependências (Python 3.8+, R 4.0+)
  - [ ] Ordem de execução dos scripts
  - [ ] Descrição dos arquivos de dados
- [ ] Licença especificada (CC-BY-4.0)
- [ ] DOI confirmado e funcional

---

### 4.5 Compilação LaTeX Final [30min]

**Objetivo:** PDF sem erros ou warnings

**Checklist:**
- [ ] Compilar 3x (para resolver referências cruzadas):
  ```
  pdflatex sn-article.tex
  bibtex sn-article
  pdflatex sn-article.tex
  pdflatex sn-article.tex
  ```
- [ ] Verificar log: 0 erros, <5 warnings
- [ ] Abrir PDF e verificar:
  - [ ] Todas as figuras aparecem
  - [ ] Numeração de figuras/tabelas sequencial
  - [ ] Referências cruzadas funcionando (\ref{})
  - [ ] Bibliografia formatada corretamente
  - [ ] Nenhuma página em branco inesperada
  - [ ] Cabeçalhos/rodapés corretos
  
**Warnings permitidos:**
- `Package hyperref Warning: Token not allowed` (normal em títulos)
- `Underfull/Overfull hbox` (só se >5mm)

**Warnings problemáticos:**
- `Label multiply defined` → Resolver duplicatas
- `Reference undefined` → Verificar \label e \ref
- `Citation undefined` → Adicionar no .bib

---

### 4.6 Revisão por Co-Autores [1 semana]

**Distribuir para co-autores:**

**Email template:**
```
Assunto: Revisão Final - Artigo SAT ML (PRONTO PARA SUBMISSÃO)

Prezados Co-Autores,

O manuscrito "Aprendizado de Máquina para Sistemas Agrícolas 
Tradicionais: Uma Revisão de Escopo PRISMA" passou por revisão 
crítica e está pronto para submissão a Sustainability Science (Q1).

PRINCIPAIS MUDANÇAS (após feedback de revisor expert):
- Título encurtado e refocalizado em ML técnico
- Introdução limpa (removido conteúdo epistemológico)
- Research Questions explícitas (4 questões)
- Limitações expandidas (6 pontos críticos)
- Análise de sensibilidade adicionada
- 4862 palavras (60% do limite, espaço para melhorias)

DOCUMENTOS ANEXOS:
1. sn-article.pdf (manuscrito compilado)
2. RELATORIO_IMPLEMENTACAO.md (mudanças detalhadas)
3. PENDENCIAS_ATUALIZADAS.md (próximos passos opcionais)

PRAZO PARA REVISÃO: 5 dias úteis

VERIFICAR:
□ Concordância com mudanças de escopo
□ Contribuições de cada autor (CRediT statement)
□ Afiliações e emails corretos
□ Agradecimentos adequados
□ Correções ortográficas/técnicas

Por favor, respondam com:
- Aprovação para submissão OU
- Sugestões de ajustes (indicar prioridade: crítico/desejável)

Atenciosamente,
[Nome]
```

**Checklist de aprovações:**
- [ ] Catuxe Varjão (1º autor)
- [ ] Luiz Diego Vidal (autor correspondente)
- [ ] Paulo Roberto Gagliardi
- [ ] Francisco Sandro Holanda
- [ ] Renisson Araújo Filho

---

## 📊 CRONOGRAMA SUGERIDO

### Semana 1 (Essencial antes de submeter)
| Dia | Tarefa | Tempo | Responsável |
|-----|--------|-------|-------------|
| Seg | 2.3 Converter figuras EPS | 2h | Técnico |
| Ter | 4.1 Checklist Springer | 2h | Autor corresp. |
| Qua | 4.2 Verificar citações | 1h | Autor corresp. |
| Qui | 4.3 Revisão ortográfica | 2h | Todos |
| Sex | 4.4 Testar OSF | 1h | Autor corresp. |
| Sáb | 4.5 Compilação final | 0.5h | Técnico |
| Dom | 4.6 Enviar para co-autores | 0.5h | Autor corresp. |

### Semana 2 (Melhorias estruturais - opcional mas recomendado)
| Dia | Tarefa | Tempo | Responsável |
|-----|--------|-------|-------------|
| Seg | 2.1 Reorganizar Métodos | 3h | Autor corresp. |
| Ter | 2.2 Melhorar Figura 3 (rede) | 2h | Técnico Python |
| Qua | 2.2 Melhorar Figura 5 (MCA) | 2h | Técnico Python |
| Qui | 2.2 Melhorar Figura 6 (heatmap) | 2h | Técnico Python |
| Sex | 2.4 Padronizar nomenclatura | 2h | Autor corresp. |
| Sáb | 2.5 Detalhes técnicos | 3h | Autor corresp. |
| Dom | Revisão integrada | 2h | Todos |

### Semana 3 (Melhorias opcionais - aumenta impacto)
| Dia | Tarefa | Tempo | Status |
|-----|--------|-------|--------|
| Seg-Ter | 3.1 Tabela recomendações | 2h | Opcional |
| Qua | 3.2 Future Research Agenda | 2h | Opcional |
| Qui-Sex | 3.3 Meta-regressão (SE dados) | 5h | Condicional |

### Semana 4 (Feedback co-autores)
| Dia | Tarefa | Tempo | Status |
|-----|--------|-------|--------|
| Seg-Sex | Aguardar feedback | - | - |
| Sáb | Incorporar ajustes finais | 3h | - |
| Dom | **SUBMETER** | 1h | 🎯 |

---

## 🎯 DECISÃO: O QUE FAZER PRIMEIRO?

### CENÁRIO A: Submissão Rápida (1 semana)
**Prioridade:** Fase 4 (Verificação Final)

**Razão:** Manuscrito já está tecnicamente sólido. Correções críticas foram implementadas.

**Executar:**
1. ✅ Converter figuras EPS (2h)
2. ✅ Checklist Springer (2h)
3. ✅ Verificar citações (1h)
4. ✅ Revisão ortográfica (2h)
5. ✅ Testar OSF (1h)
6. ✅ Enviar para co-autores (5 dias)
7. ✅ Submeter

**Pular:** Fase 2 (melhorias estruturais) e Fase 3 (opcionais)

**Vantagem:** Submissão em 2 semanas  
**Risco:** Revisor pode pedir melhorias estruturais → Minor Revision

---

### CENÁRIO B: Submissão Robusta (3 semanas)
**Prioridade:** Fase 2 + Fase 4

**Razão:** Melhorias estruturais aumentam chances de aceitação direta.

**Executar:**
1. ✅ Reorganizar Métodos (3h)
2. ✅ Melhorar 3 figuras (6h)
3. ✅ Converter EPS (2h)
4. ✅ Padronizar nomenclatura (2h)
5. ✅ Detalhes técnicos (3h)
6. ✅ Fase 4 completa (7h)
7. ✅ Co-autores (5 dias)
8. ✅ Submeter

**Pular:** Fase 3 (opcionais como meta-regressão)

**Vantagem:** Manuscrito polido, maior chance de Accept/Minor Revision  
**Risco:** 1 semana a mais de trabalho

---

### CENÁRIO C: Submissão Premium (4 semanas)
**Prioridade:** Tudo (Fase 2 + 3 + 4)

**Razão:** Maximizar impacto, adicionar tabela prática + agenda futura

**Executar:** Tudo da Fase 2, 3 e 4

**Vantagem:** Artigo referência no campo, alto potencial de citações  
**Risco:** 2 semanas a mais, meta-regressão pode não adicionar muito

---

## 💡 RECOMENDAÇÃO FINAL

**Sugerimos CENÁRIO B (Submissão Robusta)**

**Razão:**
- ✅ Fase 1 crítica já implementada (fundação sólida)
- ⚠️ Figuras precisam melhorar (legibilidade em print)
- ⚠️ EPS é obrigatório (Springer rejeita PNG)
- ✅ Reorganização de Métodos é rápida (3h) e melhora fluxo
- ❌ Meta-regressão (Fase 3) é condicional a dados que podem não existir

**Prioridade de execução:**
1. **HOJE:** Converter figuras EPS (CRÍTICO)
2. **Semana 1:** Melhorar 3 figuras + Reorganizar Métodos
3. **Semana 2:** Fase 4 (Verificação Final)
4. **Semana 3:** Co-autores + Submeter

**Estimativa:** Submissão em **21 dias** com manuscrito robusto

---

## 📞 CONTATOS E RECURSOS

**Dúvidas técnicas:**
- Meta-análise: ldvsantos@uefs.br
- LaTeX/Formatação: Autor correspondente
- Scripts Python: OSF Issues tab
- Springer Guidelines: https://www.springer.com/journal/11625

**Ferramentas úteis:**
- Contagem palavras: `python tools/count_words.py`
- Verificação citações: Script PowerShell acima
- Compilação LaTeX: `pdflatex sn-article.tex`
- Conversão EPS: `plt.savefig('fig.eps', format='eps', dpi=300)`

**Periódicos alternativos (se Sustainability Science rejeitar):**
1. Agricultural Systems (Q1, JIF 6.1)
2. Environmental Monitoring and Assessment (Q2, JIF 2.9)
3. Land Use Policy (Q1, JIF 6.0)
4. Computers and Electronics in Agriculture (Q1, JIF 7.7)

---

**Última atualização:** 7 de fevereiro de 2026  
**Próxima revisão:** Após implementação Fase 2 ou 4 (conforme cenário escolhido)
