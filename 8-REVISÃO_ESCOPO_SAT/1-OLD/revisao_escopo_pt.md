---
title: "Terroir Digital e Auditabilidade de Serviços Ecossistêmicos via Aprendizado de Máquina em Indicações Geográficas <b>Digital Terroir and Ecosystem Service Auditability via Machine Learning in Geographical Indications</b>"
author: "Catuxe Varjão de Santana Oliveira, Paulo Roberto Gagliardi, Luiz Diego Vidal Santos, Gustavo da Silva Quirino, Ana Karla de Souza Abud, Cristiane Toniolo Dias"
bibliography: referencias.bib
csl: apa.csl
reference-doc: modelo_formatacao.docx
fig-align: center
table-align: center
lang: pt-BR
---

# Resumo

As Indicações Geográficas (IGs) operam como sistemas socioecológicos acoplados, onde a tipicidade emerge de interações dinâmicas entre solo, clima e biota, demandando mecanismos auditáveis de governança ambiental. O presente estudo analisa a maturidade técnica do estado da arte em Aprendizado de Máquina para operacionalizar o Terroir Digital concebido como um Gêmeo Digital Inferencial para auditoria de serviços ecossistêmicos. Sob diretrizes PRISMA-ScR, processou-se um corpus de 148 estudos (2010–2025) via triagem automatizada de pontuação ponderada (precisão 94,2%) e validação manual (CCI=0,87). A análise integrou meta-análise de efeitos aleatórios, estatística multivariada e avaliação de princípios FAIR. Os resultados revelam um paradoxo de generalização: embora os classificadores atinjam alta acurácia in vitro (80–100%), testes de robustez externa expõem degradação severa de desempenho (queda de 11,8% versus 5,6% em modelos espacialmente independentes; d=0,95). A fragmentação metodológica (Modularidade Q=0,62; Heterogeneidade I²=58%) e a incipiente conformidade FAIR (média 34,2/100) perpetuam assimetrias epistêmicas que inviabilizam a aplicação regulatória. Conclui-se que a efetivação do Terroir Digital exige a transição de classificadores estáticos para modelos adaptativos, condicionados a benchmarks de integridade: validação espacial com degradação ≤8%, explicabilidade (XAI) para marcadores territoriais e conformidade FAIR ≥60/100, requisitos sine qua non para converter IGs em sistemas verificáveis de sustentabilidade.
**Palavras‑chave:** Indicações Geográficas; Aprendizado de Máquina; Auditoria Ambiental; Greenwashing; Rastreabilidade; Serviços Ecossistêmicos.

![](2-FIGURAS/2-EN/abstract_grafico.png){#fig:abstract width="90%"}


# 1. Introdução

As Indicações Geográficas (IGs) transcendem sua função original como propriedade intelectual ao surgir como instrumentos estratégicos para a governança ambiental e a conservação da agrobiodiversidade no Antropoceno [@Belletti2017; @Vandecandelaere2009]. Em um cenário global marcado pela crise climática e pela erosão da biodiversidade, as IGs operam como sistemas socioecológicos que vinculam a qualidade do produto à integridade dos serviços ecossistêmicos do território [@Berkes2003; @Bramley2013]. Elas representam mecanismos para valorizar práticas agrícolas regenerativas e manter paisagens culturais, onde o *terroir* é redefinido não apenas como um atributo sensorial, mas como uma impressão digital do produto e da resiliência climática [@Giovannucci2010; @Fonzo2015].

A regulamentação internacional, fundamentada no Acordo TRIPS e no Regulamento (UE) n.º 1151/2012, estabelece a base jurídica, mas é a capacidade de auditoria ambiental que confere legitimidade contemporânea a esses ativos [@EU2012; @WTO1994]. A distinção entre Indicação Geográfica Protegida (IGP) e Denominação de Origem Protegida (DOP) reflete diferentes graus de dependência dos ciclos naturais, exigindo sistemas de verificação robustos para evitar o *greenwashing* e garantir que o prêmio de mercado financie efetivamente a conservação ambiental [@Locatelli2008; @WIPO2020]. A credibilidade desses selos depende, portanto, da capacidade de comprovar cientificamente que as características do produto derivam de interações ambientais específicas e não replicáveis.

O terroir pode ser compreendido como um sistema socioecológico intrinsecamente acoplado, no qual solo, clima, biota e cultura se articulam por meio de interações não lineares, feedbacks e forte heterogeneidade espacial e temporal, configurando um território onde processos biofísicos e práticas sociais são co-produzidos [@LeFloc2016S]. 

A complexidade sistêmica e a natureza difusa dos acoplamentos biogeoquímicos limitam a detecção dos serviços ecossistêmicos por métricas convencionais [@Levin1998ComplexAdaptiveSystems], fragilizando a governança de bens comuns e facilitando práticas de *greenwashing* [@Gale2023]. Diante da insuficiência do instrumental analítico clássico para o monitoramento em escala de paisagem [@Liao2023], este estudo propõe o Terroir Digital como um Gêmeo Digital Inferencial (*Inferential Digital Twin*). Esta abordagem fundamenta-se na reconstrução computacional dinâmica das interações entre o genótipo territorial (solo, clima e biota) e o fenótipo do produto, convertendo a incerteza ecológica em evidências auditáveis de conformidade ambiental [@Pylianidis2021; @Hensel2021; @Guerena2024].

A validação operacional desse sistema requer o atendimento a critérios de auditabilidade derivados das lacunas metodológicas identificadas na literatura. É imperativa a robustez inferencial, assegurada mediante validação espacialmente independente e estabilidade longitudinal frente à variabilidade climática [@Kuhn2013]. Simultaneamente, a transparência causal torna-se mandatória, exigindo métodos de Inteligência Artificial Explicável (XAI) para discriminar marcadores físico-químicos de correlações espúrias [@Rudin2019]. Por fim, a soberania de dados deve ser garantida pela adesão aos princípios FAIR e por trilhas de auditoria imutáveis, assegurando a reprodutibilidade e a rastreabilidade da inferência [@Wilkinson2021; @Kshetri2014]. Nesse contexto, o Aprendizado de Máquina atua como mecanismo analítico intrínseco para processar a não-linearidade de dados multiescalares, viabilizando a soberania epistêmica das comunidades produtoras [@Li2022KGML_ag; @Santos2007Epistemologies].

Em escalas geográficas amplas, o ML torna possível a auditabilidade de serviços ecossistêmicos, estabelecendo uma ligação verificável entre a conformidade ambiental e o prêmio de mercado, e mitigando as assimetrias informacionais que propiciam fraudes e apropriação indevida [@Kshetri2014DigitalDivide].

Contudo, a literatura carece de um framework conceitual unificado que integre as capacidades inferencias do ML com os requisitos regulatórios de certificação ambiental. Esta lacuna limita a tradução de avanços metodológicos em protocolos operacionais para sistemas de Indicação Geográfica, perpetuando a fragmentação entre pesquisa acadêmica e governança territorial.

Nesse contexto, o presente estudo analisa criticamente se o aparato metodológico atual de Aprendizado de Máquina reúne as condições de robustez inferencial, explicabilidade e governança de dados indispensáveis para fundamentar o Terroir Digital como sistema de auditoria de serviços ecossistêmicos. Postula-se que a modelagem dos acoplamentos não-lineares entre variáveis ambientais (genótipo territorial) e assinaturas quimiométricas (fenótipo do produto), quando sustentada por validação espaço-temporal rigorosa e mecanismos de segurança de dados, gera evidências auditáveis de conformidade ambiental. Essa abordagem converte alegações difusas de sustentabilidade em registros verificáveis e imutáveis, fundamentando políticas de conservação baseadas no mercado com garantias de integridade e robustez contra fraudes.

# 2. Materiais e Métodos

Esta revisão segue as diretrizes PRISMA-ScR ( Preferred Reporting Items for Systematic Reviews and Meta-Analyses extension for Scoping Reviews ) como uma estrutura de transparência para garantir clareza metodológica e reprodutibilidade. O protocolo está registrado no Open Science Framework para facilitar o acesso público e a replicabilidade.

## 2.1 Questão de Pesquisa

O estudo utiliza a estrutura PCC ( População, Conceito, Contexto ) para formular a seguinte questão de pesquisa: Como as técnicas de Aprendizado de Máquina têm sido aplicadas para autenticação, avaliação e apoio à decisão em sistemas de Indicações Geográficas?

**Tabela 1.** Estrutura da revisão de acordo com o modelo PCC.

| Elemento | Descrição |
|:----------------------|:------------------------------------------------|
| **P (População)** | Indicações Geográficas, Denominações de Origem e Indicações de Procedência reconhecidas nacional e internacionalmente, abrangendo produtos agroalimentares (vinhos, queijos, cafés, carnes, azeites), artesanato e outros produtos com identidade territorial. |
| **C (Conceito)** | Aprendizado de Máquina, Inteligência Artificial, algoritmos de classificação e predição, métodos quimiométricos, Mineração de Dados e Processamento de Linguagem Natural aplicados a contextos de Indicações Geográficas. |
| **C (Contexto)** | Autenticação de origem geográfica, avaliação do potencial de IG, identificação de determinantes territoriais (solo, clima, métodos de produção), classificação e discriminação de produtos, sistemas de apoio à decisão para certificação, controle de qualidade, rastreabilidade, detecção de fraudes e adulterações e estratégias de valorização territorial. |

Este estudo identifica e caracteriza aplicações de aprendizado de máquina (ML) relatadas na literatura, categorizando as técnicas por tipo de algoritmo, abordagem metodológica e métricas de desempenho. Além disso, analisa a distribuição das aplicações por tipo de produto, região geográfica e período, identificando lacunas metodológicas, limitações e direções para pesquisas futuras.

## 2.1.1 Fluxograma Metodológico PRISMA-ScR

A Figura 1 apresenta o fluxograma metodológico, estruturado em quatro fases sequenciais: (1) Estratégias principais de busca na base de dados, (2) Filtragem automatizada com um sistema de pontuação ponderada, (3) Avaliação manual da qualidade com avaliação multidisciplinar e (4) Análise bibliométrica e síntese qualitativa integrando metodologias quantitativas e documentais. O fluxograma detalha o caminho desde a identificação dos registros até a síntese final, oferecendo recomendações para a implementação de Aprendizado de Máquina em sistemas de Indicações Geográficas.

**Figura 1.** Fluxograma de triagem, elegibilidade e síntese para aplicações de aprendizado de máquina em Indicações Geográficas.

![](2-FIGURAS/2-EN/ml_indicacoes_geograficas.png){#fig:ml_indicacoes width="80%"}

## 2.2 Estratégia de Busca e Extração de Estudos

As buscas foram direcionadas ao Scopus (Elsevier) e ao Web of Science (Clarivate Analytics), cruzando três principais domínios temáticos: técnicas de aprendizado de máquina e inteligência artificial; sistemas de certificação geográfica; e Indicações Geográficas/Denominações de Origem.

Os descritores empregaram terminologia controlada em inglês e operadores booleanos (AND, OR, NOT), abrangendo publicações de 2010 a 2025 para capturar o estado da arte. A estratégia de busca seguiu esta lógica:

*("aprendizado de máquina" OU "inteligência artificial" OU "aprendizado profundo" OU "aprendizado supervisionado" OU "aprendizado não supervisionado" OU "métodos de conjunto") E ("indicações geográficas" OU "denominações de origem" OU "denominações de origem protegidas") E ("autenticação" OU "rastreabilidade" OU "controle de qualidade" OU "detecção de fraude" OU "análise geoespacial")* .

Os critérios de inclusão compreenderam artigos revisados por pares em inglês, português ou espanhol que apresentassem aplicações de aprendizado de máquina em contextos de IG (Informação Geográfica), autenticação de origem ou controle de qualidade territorial. Descritores primários eram obrigatórios no título, resumo ou palavras-chave. Trabalhos não revisados por pares, estudos sem aplicação prática de aprendizado de máquina e aqueles focados exclusivamente em aspectos não territoriais foram excluídos.

Embora a busca inicial tenha sido ampla, a síntese qualitativa priorizou estudos que estabeleceram ligações explícitas entre marcadores analíticos e variáveis ambientais (por exemplo, composição do solo, padrões de precipitação, altitude), filtrando estudos estritamente focados em processamento industrial. Isso garantiu que a revisão abordasse a auditabilidade dos serviços ecossistêmicos e a validade do conceito de terroir, em vez de se concentrar exclusivamente no controle de qualidade da produção.

A extração de dados utilizou um formulário padronizado para registrar metadados bibliográficos (autor, ano, título), características geográficas (país de origem, região, tipo de IG), detalhes do produto (categoria, denominação específica), abordagem metodológica (algoritmos de aprendizado de máquina, técnicas analíticas/instrumentais, tamanho da amostra) e métricas de desempenho (precisão, sensibilidade, especificidade, RMSE).

## 2.3 Primeira Fase: Sistema Automatizado de Filtragem por Relevância Temática

### 2.3.1 Algoritmo de Pontuação Ponderada

Complementando a triagem manual, um sistema de filtragem automatizado atribui pontuações de relevância temática com base na presença e localização dos descritores no título, resumo e palavras-chave. Implementado em Python (NLTK, spaCy), o algoritmo aplica um esquema de ponderação hierárquica a cada termo identificado. O sistema de pontuação segue os princípios do Processo Analítico Hierárquico (AHP). A Equação (1) organiza os descritores em cinco categorias com pesos diferenciados [@SAATY1991].

$$
S_i = \sum_{j=1}^{n} w_j \cdot l_i \cdot f_{ij}
$$

onde:

-   $S_i$ = pontuação total do artigo $i$
-   $w_j$ = peso associado ao termo $j$ (categorizado em 5 níveis: 5, 3, 2, 1 ou -5/-3/-2 pontos)
-   $l_i$ = multiplicador de localização (1,5 para título, 1,2 para palavras-chave, 1,0 para resumo)
-   $f_{ij}$ = frequência de ocorrência do termo $j$ no artigo $i$
-   $n$ = número total de termos avaliados

Os termos prioritários (5 pontos) representam a revisão conceitual central (por exemplo, *indicações geográficas, rastreabilidade, autenticação* ). Os termos de alta relevância (3 pontos) abrangem conceitos metodológicos centrais (por exemplo, *aprendizado de máquina, aprendizado profundo, redes neurais* ). Os termos de relevância média (2 pontos) cobrem temas complementares (por exemplo, *quimiometria, mineração de dados* ), enquanto os termos de contexto (1 ponto) indicam ambientes potenciais (por exemplo, *produtos regionais, certificação* ). Os termos de exclusão recebem pesos negativos para penalizar registros fora do escopo, particularmente nos domínios *médico/clínico* (−5), *planejamento urbano* (−3) e *financeiro* (−2) [@MUNN2018; @tricco2018].

### 2.3.2 Implementação e Validação do Algoritmo

Para cada registro, o algoritmo examina o título, o resumo e as palavras-chave, aplica os pesos das categorias e multiplica cada ocorrência pelo fator de localização. A pontuação final soma esses produtos para todos os termos identificados.

A distribuição empírica dos escores definiu o limiar mínimo de inclusão, identificando o ponto de inflexão na curva cumulativa (critério de Pareto/cotovelo) e ajustando-o por meio de validação manual com amostragem estratificada. O valor final representa o equilíbrio ideal entre sensibilidade e especificidade, estabilizando a concordância entre avaliadores em casos limítrofes.

### 2.3.3 Validação Participativa e Refinamento de Algoritmos

Para garantir a validade científica, foi implementado um protocolo de validação envolvendo três revisores independentes especializados em aprendizado de máquina e sistemas GI. O protocolo incluiu uma revisão manual sistemática de 272 estudos para verificar a adesão aos critérios de inclusão. Um teste de concordância interavaliadores verificou a consistência da classificação [@Tricco2018].

O processo envolveu a investigação qualitativa de casos limítrofes e o refinamento iterativo dos critérios de elegibilidade. A validação resultou numa taxa de concordância de 90,2% entre o sistema automatizado e a avaliação manual, indicando elevada eficácia algorítmica na triagem temática.

### 2.3.4 Verificação de Cobertura e Categorização Automatizada

Um sistema automatizado verificou a abrangência bibliográfica, garantindo a integridade e a consistência entre as citações textuais e os arquivos bibliográficos.

O corpus consolidado foi submetido à categorização automatizada usando Processamento de Linguagem Natural (PLN). Um pipeline computacional extraiu, tokenizou e vetorizou metadados e resumos de referência, usando modelos supervisionados e regras semânticas para reconhecimento de padrões [@Young2019; @Casey2021]. As referências foram classificadas em categorias metodológicas predefinidas, incluindo técnicas de aprendizado de máquina e sistemas de informação geográfica.

Para quantificar a abrangência e a adequação dos estudos, foram aplicadas métricas de cobertura de citações e taxas de utilização bibliográfica do corpus [@tranfield2003; @webster2002]. Essas métricas permitem a avaliação quantitativa da utilização da base de referências, garantindo que os estudos selecionados reflitam adequadamente o escopo temático da revisão.

## 2.4 Segunda Fase: Avaliação Manual da Qualidade Metodológica

Na segunda fase, três revisores independentes avaliaram a qualidade metodológica dos estudos selecionados, garantindo uma análise multidisciplinar e reduzindo o viés interpretativo. A escala MMAT [@pluye2009; @hong2018] foi adaptada para estudos interdisciplinares envolvendo aprendizado de máquina e sistemas gastrointestinais, estruturando oito indicadores em uma escala Likert de 3 pontos. Os indicadores incluíram rigor metodológico, validação do algoritmo, adesão ao protocolo ético, reprodutibilidade, integração quantitativa-qualitativa, impacto nos sistemas gastrointestinais, completude da documentação e generalização do método (Tabela 2).

Cada indicador recebeu uma pontuação de 0 a 2: zero para critérios não atendidos ou deficiências substanciais; um para atendimento parcial com limitações; e dois para atendimento completo com evidências claras. Uma escala de 3 pontos foi selecionada porque avaliações dicotômicas não conseguem capturar a complexidade interdisciplinar, enquanto escalas maiores geram inconsistência entre avaliadores [@Likert3vs5_2025].

**Tabela 2.** Indicadores de qualidade metodológica para estudos de ML-GI.

| Código | Indicador | Domínio |
|:------:|:----------|:----------|
| RIG | Rigor metodológico na coleta e processamento de dados territoriais | Qualidade Territorial |
| VAL | Validação técnica de algoritmos com métricas apropriadas | Qualidade Computacional |
| ETI | Adesão a protocolos éticos para pesquisa com comunidades produtoras | Qualidade Ética |
| REP | Reprodutibilidade de experimentos computacionais | Qualidade técnica |
| INT | Integração eficaz entre métodos territoriais quantitativos e qualitativos | Qualidade Metodológica |
| IMP | Impacto e aplicabilidade dos resultados para sistemas gastrointestinais | Qualidade Social |
| DOC | Documentação completa de algoritmos e procedimentos de certificação | Qualidade Documental |
| GEN | Generalização e transferibilidade dos métodos propostos | Qualidade Científica |

### 2.4.1 Procedimentos de Consenso e Validação entre Avaliadores

A avaliação manual incluiu um protocolo de consenso. Inicialmente, os revisores avaliaram independentemente uma amostra piloto de 30 estudos (aproximadamente 11% do corpus) para calibrar os critérios. Para o corpus completo, os casos de discordância (diferença ≥ 2 pontos) foram submetidos a reavaliação cega e discussão para se chegar a um consenso. O coeficiente de correlação intraclasse (CCI) foi calculado de acordo com @shrout1979, obtendo-se um valor de 0,87 (IC 95%: 0,84–0,91), indicando boa concordância.

### 2.4.2 Critérios Específicos para Estudos Interdisciplinares

Dada a natureza interdisciplinar dos estudos, os critérios de qualidade examinaram a coerência da integração quantitativa-qualitativa, a validação em múltiplos contextos geográficos, a transparência algorítmica, a adesão ética e a aplicabilidade prática para certificação.

Esta fase resultou na seleção de 25 estudos com qualidade metodológica adequada (pontuação ≥ 20 pontos) dentre os 272 artigos iniciais. Estes constituíram a base para as análises subsequentes. A distribuição incluiu 1 artigo de excelência (≥40 pontos), 2 de alta relevância (≥30 pontos) e 22 adequados (≥20 pontos).

## 2.5 Terceira Fase: Análise Bibliométrica

A Lei de Lotka [@lotka1926] analisou a produtividade científica, descrevendo a distribuição não linear da produtividade dos autores para identificar padrões de concentração ou dispersão. Análises de acoplamento bibliográfico e co-citação não foram realizadas devido à ausência de campos de referência citados nos arquivos bibliográficos disponíveis.

## 2.6 Quarta Fase: Síntese Qualitativa e Integração com Análise Documental

A quarta fase integrou sistematicamente as conclusões com a análise documental dos quadros regulamentares para fundamentar as recomendações metodológicas.

A síntese final combinou a análise temática qualitativa com a seleção baseada no princípio de Pareto (80/20), priorizando os 20% melhores artigos pela pontuação combinada (40% qualidade metodológica, 35% relevância temática, 25% impacto bibliométrico).

A pontuação combinada final foi calculada usando a Equação (2):

$$
P_{final} = (0,40 \cdot Q_{met}) + (0,35 \cdot Q_{tem}) + (0,25 \cdot Q_{biblio})
$$

Onde:

-   $P_{final}$ = pontuação final de seleção
-   $Q_{met}$ = qualidade metodológica normalizada (0-1)
-   $Q_{tem}$ = relevância temática normalizada (0-1)
-   $Q_{biblio}$ = impacto bibliométrico normalizado (0-1)

## 2.7 Análises Estatísticas

O corpus de 148 estudos foi submetido a duas classes de análises estatísticas, sendo elas, análises descritivas e exploratórias para caracterizar padrões estruturais da literatura, e análises inferenciais para quantificar empiricamente as lacunas metodológicas identificadas qualitativamente.

### 2.7.1 Análises Descritivas e Exploratórias do Corpus

A Análise de Correspondência Múltipla (ACM) [@Le2008; @Greenacre2017] foi empregada para investigar associações entre variáveis categóricas (algoritmos, produtos, regiões, técnicas analíticas) mediante decomposição de tabelas de contingência. Implementada com o pacote `FactoMineR`, a ACM permite extrair dimensões latentes que explicam a variância nas associações entre categorias. Complementarmente, aplicou-se Análise de Cluster (k-means e hierárquica) com o pacote `factoextra` para identificar agrupamentos recorrentes entre combinações produto-instrumento-algoritmo.

A análise de rede [@Csardi2006; @Schoch2020] foi empregada para mapear coocorrências mediante construção de grafo não direcionado ponderado com os pacotes `igraph` e `ggraph`, onde nós representam entidades (algoritmos, produtos, regiões) e arestas indicam coocorrência nos estudos. Calcularam-se métricas de centralidade (grau, autovetor, intermediação) para identificar elementos estruturalmente centrais no campo de pesquisa. A detecção de comunidades foi realizada via algoritmo de Louvain [@Blondel2008] para identificar módulos tecnológicos e padrões de especialização por produto-instrumento-algoritmo. Séries temporais (2010–2025) empregaram correlação de Spearman [@Spearman1904] para detectar tendências no volume de publicações e adoção algorítmica.

### 2.7.2 Análises Inferenciais de Validação dos Critérios Operacionais

Para quantificar empiricamente as lacunas metodológicas e fundamentar os critérios operacionais do Terroir Digital, conduziram-se quatro análises inferenciais complementares. Buscando analisar o impacto da validação espacial no desempenho preditivo, compararam-se modelos com particionamento geograficamente independente ($n = 70$) versus aleatório convencional ($n = 78$), calculando degradação percentual de desempenho entre validação interna e testes externos. Diferenças foram avaliadas por Mann-Whitney U [@Mann1947], com tamanho de efeito quantificado pelo $d$ de Cohen [@Cohen1988]: pequeno ($d = 0,2$), médio ($d = 0,5$) ou grande ($d = 0,8$) conforme @Sawilowsky2009. Regressão logística [@Hosmer2013] estimou a razão de chances (*odds ratio*) de alta performance ($\text{acurácia} \geq 85\%$) em função da validação espacial, controlando por algoritmo e produto, seguindo @Kuhn2013.

Para investigar o trade-off entre explicabilidade e desempenho algorítmico, analisou-se a relação entre explicabilidade algorítmica (escala ordinal 0–10 baseada em @Rudin2019) e acurácia mediante correlação de Spearman [@Spearman1904]. Diferenças em acurácia entre modelos com XAI ($n = 20$) e sem XAI ($n = 128$) foram avaliadas por teste $t$ de Student [@Student1908], verificando normalidade via Shapiro-Wilk [@Shapiro1965]. Overhead computacional foi comparado por Mann-Whitney. Análise de Pareto [@Pareto1896; @Deb2001] identificou algoritmos ótimos sob função de utilidade ponderada: $U = 0,4 \times \text{acurácia} + 0,4 \times \text{explicabilidade} + 0,2 \times (1 - \text{tempo normalizado})$.

Visando avaliar a acurácia reportada nos estudos e detectar potencial viés de publicação, conduziu-se meta-análise de efeitos aleatórios [@Borenstein2009] com o pacote `metafor` [@Viechtbauer2010], transformando acurácias via logit para estabilizar variâncias [@Barendregt2013]: $\text{logit}(p) = \ln[p/(1-p)]$. Estimou-se acurácia pooled por modelo REML [@DerSimonian1986] com IC 95%. Heterogeneidade foi quantificada pela estatística $I^2$ [@Higgins2003]: baixa ($< 25\%$), moderada ($25\%$–$75\%$) ou alta ($> 75\%$). Teste Q de Cochran [@Cochran1954] avaliou significância da heterogeneidade ($\alpha = 0,05$). Meta-regressão [@Thompson2002] investigou efeitos de ano de publicação e tamanho amostral. Viés de publicação foi detectado por teste de Egger [@Egger1997] e método trim-and-fill [@Duval2000]. Forest plots estratificados foram gerados seguindo @Balduzzi2019.

Por fim, para avaliar a conformidade com princípios de governança de dados abertos, quantificou-se conformidade FAIR mediante score padronizado (0–100 pontos) baseado em 12 indicadores binários de @Wilkinson2016: DOI (F1), metadados ricos (F2), repositório público (A1), protocolo de acesso (A2), licença (R1.1), código-fonte (R1.2), formato interoperável (I1), vocabulário controlado (I2), proveniência (R1.3), padrão comunitário (I3), API acessível (A1.1) e versionamento (R1.2). Cada indicador contribuiu $100/12 \approx 8,33$ pontos. Scores foram agregados nas quatro dimensões FAIR por média aritmética. Análise temporal empregou correlação de Spearman [@Spearman1904]. Comparações entre estudos com/sem blockchain usaram Mann-Whitney. Gráficos radar multidimensionais visualizaram perfis FAIR com benchmark da Comissão Europeia (75/100) [@EC2018].

Todas as análises foram implementadas em R [@RCoreTeam2024] utilizando os pacotes `ggplot2` para visualizações [@Wickham2016], `metafor` para meta-análise [@Viechtbauer2010], `effsize` para cálculo de tamanhos de efeito [@Torchiano2020] e rotinas customizadas para conformidade FAIR. Empregou-se $\alpha = 0,05$ como nível de significância, aplicando correção de Bonferroni [@Bonferroni1936] quando pertinente para múltiplas comparações. Códigos e dados processados foram depositados no repositório OSF (DOI: 10.17605/OSF.IO/2EKYQ) para assegurar reprodutibilidade [@Nosek2015].

## 2.8 Terroir Digital como Sistema de Auditoria Inferencial

A partir da análise sistemática do corpus bibliográfico, identificou-se que as aplicações de ML em IGs carecem de um framework conceitual que integre capacidades computacionais com requisitos regulatórios de auditoria ambiental. Para preencher essa lacuna, propõe-se o conceito de **Terroir Digital** como sistema de auditoria inferencial derivado empiricamente da revisão.

### 2.8.1 Aplicação Analítica do Framework

Por fim o framework Terroir Digital foi empregado nesta revisão como lente analítica para avaliar a maturidade metodológica dos estudos. Cada publicação foi examinada quanto à conformidade com os critérios operacionais, permitindo identificar a proporção de estudos com validação espacial e temporal adequada, a adoção de métodos XAI para interpretabilidade, a disponibilidade de dados e protocolos em repositórios abertos e a implementação de sistemas de auditoria contínua (Figura 2). Essa abordagem possibilitou quantificar as lacunas entre o estado atual da literatura e os requisitos para operacionalização do terroir digital, fundamentando as recomendações metodológicas apresentadas nas conclusões.

**Figura 2.** Diagrama de fluxo do estudo.

![](2-FIGURAS/2-EN/prisma_flowdiagram.png){#fig:prisma2020 width="80%"}

A filtragem automatizada por meio de análise semântica e pontuação alcançou uma precisão temática de 94,2%, superando o limite estabelecido de 85%. Essa abordagem de triagem computacional mostrou-se eficaz para revisões envolvendo grandes volumes bibliográficos, sugerindo que sistemas automatizados calibrados reduzem o viés de seleção e aumentam a reprodutibilidade [@OforiBoateng2024]. A reprodutibilidade de 100% em múltiplas execuções do algoritmo, combinada com uma concordância interavaliadores de κ = 0,89, garante que esses resultados reflitam de forma confiável o estado atual da literatura científica nessa área.

A avaliação manual da qualidade metodológica resultou em um coeficiente de correlação intraclasse (CCI) de 0,87 (IC 95%: 0,84–0,91), confirmando uma robusta confiabilidade interavaliadores e validando os critérios de inclusão [@streiner2008health]. Essa validação confirma que os estudos selecionados para a síntese atendem a padrões metodológicos rigorosos.

# 3. Resultados e Discussão


## 3.1 Panorama das aplicações de aprendizado de máquina em indicações geográficas

A análise de 148 estudos revisados por pares (2010–2025) avaliam em que medida o estado da arte atual em Machine Learning aplicado a Indicações Geográficas atende aos critérios de validação, transparência, governança de dados e auditabilidade propostos no Terroir Digital. Os dados demosntraram que algoritmos de aprendizado supervisionado constituíram a abordagem predominante para autenticação de origem em sistemas de Indicação Geográfica. Random Forest e Support Vector Machines apresentaram aplicação consolidada em espectroscopia e cromatografia para vinhos, carnes e chás, alcançando acurácias de 80–100% em ambientes controlados [@Xu2021; @Mohammadi2024].

Essa predominância de arquiteturas supervisionadas sobre métodos não supervisionados reflete a disponibilidade de conjuntos de dados rotulados e a pressão por métricas de acurácia quantificáveis, conforme documentado por @Liakos2018 em análise sobre tendências de Machine Learning na agricultura de precisão. Redes Neurais Convolucionais consolidaram-se especificamente para processamento de dados hiperespectrais, enquanto PLS-DA manteve relevância no pré-processamento quimiométrico [@Peng2025; @Feng2025; @Rebiai2022], estabelecendo um paradigma instrumental que favorece produtos de alto valor agregado (vinhos, azeites) em detrimento de matrizes alimentares complexas.

A distribuição geográfica dos estudos analisados evidencia um desequilíbrio na representatividade amostral, com 72% do corpus concentrado em produtos europeus e asiáticos, predominantemente vinhos (34%), chás (18%) e azeites (8%). Tal concentração indica que a infraestrutura de autenticação digital avança prioritariamente em sistemas de IGs consolidados, enquanto regiões do Sul Global apresentam menor volume de publicações, refletindo disparidades no acesso a tecnologias de caracterização analítica [@Belletti2017GeographicalIndications].

A análise temporal indica correlação positiva entre a produção acadêmica e a complexidade algorítmica ($\rho$ de Spearman = 0,89; $p < 0,001$), observando-se um aumento na adoção de *Deep Learning* de 5% (2010–2015) para 28% (2020–2025). Entretanto, a validação desses modelos apresenta limitações estruturais: a ausência de testes longitudinais em 94% dos trabalhos sugere que os algoritmos são calibrados para condições sazonais específicas. Essa característica restringe a capacidade de generalização dos modelos frente à variabilidade climática interanual, fator limitante para a implementação de auditorias ambientais contínuas [@Iranzad2025].

Quanto à robustez espacial, apenas 23% dos estudos aplicaram validação independente geograficamente, registrando-se decréscimos de acurácia entre 2% e 15% quando os modelos são expostos a novos conjuntos de dados [@Effrosynidis2021]. Esses resultados corroboram a hipótese de sobreajuste (*overfitting*) a contextos locais, conforme discutido por @Kuhn2013. Adicionalmente, a baixa taxa de implementação de métricas de explicabilidade (XAI), presentes em 14% das pesquisas, dificulta a adequação aos requisitos de auditabilidade regulatória, uma vez que modelos do tipo "caixa-preta" não oferecem a rastreabilidade decisória exigida por órgãos de certificação [@Lundberg2017].

Já para a detecção de fraudes, prevalecem abordagens de classificação binária via SVM e KNN para matrizes como mel e azeite. A modelagem dicotômica (autêntico *versus* fraudulento) tende a não contabilizar gradientes de adulteração ou zonas de transição biogeográfica. Paralelamente, a integração de *Blockchain* e *Machine Learning*, observada em 21% dos estudos de rastreabilidade, enfrenta desafios de validação na entrada de dados. Embora o registro distribuído assegure a imutabilidade da informação, a veracidade da correspondência físico-digital depende da precisão dos "oráculos" (sensores ou modelos preditivos), cuja interoperabilidade técnica ainda é incipiente [@Wang2025].

A análise de redes confirma a formação de agrupamentos metodológicos distintos (modularidade $Q = 0,62$), com alta densidade interna (0,53–0,68). A correlação entre algoritmos específicos e técnicas instrumentais (como Redes Neurais associadas a dados espectrais) sugere uma compartimentalização do desenvolvimento técnico. Essa estrutura modular indica que a transferência de parâmetros entre diferentes classes de produtos e instrumentos analíticos permanece limitada, dificultando a padronização de protocolos universais para a certificação digital de origem.

## 3.2 Evolução temporal de produtos e algoritmos

A análise temporal dos produtos registrados apresentou padrões distintos entre categorias de IG. Vinhos mantiveram representação constante com 14 produtos (2010–2025), apresentando picos em 2021 e 2023 (3 registros cada). Mel demonstrou crescimento concentrado em 2021–2024 (12 registros), enquanto produtos à base de azeitona apresentaram distribuição esporádica (6 no total). Queijo e café permaneceram sub-representados (4 e 1 registros, respectivamente).

A correlação de Spearman confirmou tendência ascendente para vinhos (ρ = 0,615, p = 0,011), indicando expansão sistemática após 2020 [@Liakos2018]. Essa consolidação de vinhos como categoria dominante reflete tanto a maturidade dos sistemas de IG europeus quanto a disponibilidade de dados espectrais padronizados, contrastando com a fragmentação observada em categorias em ascensão como café, onde a heterogeneidade de métodos de processamento dificulta a criação de assinaturas químicas universais.

A adoção algorítmica apresentou transição mensurável. PLS-DA, dominante até 2018, foi progressivamente substituída por Random Forest e SVM a partir de 2019, acompanhando a disponibilidade de bibliotecas de ML de código aberto (scikit-learn, caret) e o aumento da capacidade computacional [@Lavine2005]. A análise de correlação temporal demonstrou mudanças significativas para SVM (ρ = 0,788, p \< 0,001) e Random Forest (ρ = 0,677, p = 0,004).

Redes Neurais constituíram a técnica mais adotada em 2020–2025 (33 aplicações), seguidas por SVM (32) e Random Forest (21). Deep Learning e CNNs difundiram-se após 2022 especificamente para processamento de dados hiperespectrais [@Shah2019], embora sua opacidade interpretativa limite a adoção em contextos regulatórios. 

A distribuição regional manteve estabilidade, com 72% dos estudos concentrados em Europa e Ásia. Quanto a representação do Sul Global, aumentou marginalmente de 18% para 22% no período analisado, sugerindo barreiras persistentes relacionadas a infraestrutura laboratorial e acesso a financiamento científico.

**Figura 3.** Evolução temporal de (a) produtos com Indicação Geográfica (IG) registrados por categoria e (b) adoção dos principais algoritmos de Aprendizado de Máquina em estudos de IG.
![](2-FIGURAS/2-EN/evolucao_temporal.png){#fig:temporal_evolution width="90%"}

## 3.3 Famílias Tecnológicas e Aplicações

A fragmentação metodológica vigente constitui um obstáculo estrutural à implementação de um Terroir Digital adaptativo, na medida em que substitui a fluidez de um ecossistema inferencial interoperável por módulos analíticos estanques. Essa desconexão é quantificada pela Análise de Correspondência Múltipla, que explica 45,2% da inércia total ao mapear uma polarização simultânea entre vetores biogeográficos, instrumentais e estratégicos.

Observa-se uma dicotomia onde matrizes europeias de vinhos e queijos se dissociam sistematicamente das cadeias asiáticas de chás e carnes, replicando a segregação técnica entre abordagens espectroscópicas e cromatográficas. Tal configuração denota a rigidificação de rotinas laboratoriais regionais que, ao operarem isoladamente, restringem a capacidade de generalização dos modelos e impedem a constituição de uma governança global baseada em evidências auditáveis [@Kharbach2023].

Esse padrão resulta da sedimentação cumulativa de protocolos e rotinas de publicação, não de preferências casuais [@Spyros2023FoodAuth; @Kharbach2023]. Redes de coocorrência revelam retenção de parâmetros em tríades estáveis (Vinhos–Random Forest–NIR; Chás–SVM–GC-MS) com baixa entropia exploratória, bloqueando reutilização inferencial cruzada [@Blondel2008; @Salam2021; @Wang2025]. No grafo de comunidades Louvain (Figura 4) a modularidade $Q = 0,62$ e densidades internas 0,53–0,68 indicam coerência intra-módulo mas ausência de nós de intermediação (betweenness elevada) capazes de atuar como pontes.

Algoritmos espectroscópicos de alto grau exibem centralidade de autovetor elevada concentrando fluxo informacional, enquanto técnicas cromatográficas formam módulo periférico com baixa conectividade transversal [@GODAN2024]. Tal distribuição de grau e autovetor gera assimetria epistêmica, como produtos dotados de infraestrutura analítica acumulam vantagem cumulativa, enquanto matrizes biodiversas do Sul Global permanecem sub-representadas, limitando capacidade de modelar acoplamentos não-lineares inter-biomas exigidos para auditoria de serviços ecossistêmicos [@Urioste].

Ausência de arestas ponte e de nós articuladores (structural holes não preenchidos) implica aumento do custo marginal de generalização: cada expansão territorial demanda calibragem independente sem reaproveitamento de representações latentes. A resposta tecnológica corrente, fusão multimodal (28%) e integração *blockchain* (9%), não elimina o gargalo estrutural, pois compressão para dispositivos *field-deployable* sacrifica 10–15% de acurácia frente a condições laboratoriais [@Meena2024; @Effrosynidis2021] antes de resolver lacunas de conectividade cognitiva. A Superação requer arquitetura multimodal transparente com validação espacial/temporal federada e inserção de nós ponte (modelos explicáveis de alta intermediação) como pré-condição à otimização embarcada, sem isso mantém-se fragmentação que inviabiliza auditoria inferencial contínua e soberania epistêmica.

**Figura 4.** Comunidades Louvain na rede algoritmo–produto–técnica. 
![](2-FIGURAS/2-EN/louvain_modules_detailed.png){#fig:louvain width="85%"}
*Nota: Nós dimensionados por grau ponderado; cores representam módulos (modularidade $Q = 0,62$). Ausência de arestas ponte entre clusters espectroscópicos e cromatográficos evidencia ruptura de transferibilidade e necessidade de arquitetura multimodal para generalização adaptativa.*

A análise de comunidades Louvain e a análise de clusters hierárquicos revelaram padrões tecnológicos distintos, sintetizados na Tabela 3. O Módulo M1, predominante em vinhos e mel das regiões africanas e europeias, concentra-se em técnicas espectroscópicas (NIR) associadas a algoritmos de ensemble (Random Forest, Gradient Boosting). O Módulo M2, focado em carnes e produtos regionais asiáticos, utiliza predominantemente cromatografia (GC-MS, LC-MS) combinada com SVM e KNN. Já o Módulo M3 integra técnicas avançadas de Deep Learning e CNNs para processamento de dados espectrais e sensoriais em azeites, queijos e chás, refletindo a complexidade analítica das matrizes europeias e asiáticas. Essa compartimentalização tecnológica evidencia a especialização regional, mas também expõe a falta de protocolos universais que dificulta a transferência de conhecimento entre contextos biogeográficos distintos.

**Tabela 3.** Síntese dos Padrões Tecnológicos Identificados por Análise de Redes (Louvain) e Agrupamento (Cluster).

| **Padrão Tecnológico** | **Algoritmos Principais** | **Técnicas Analíticas** | **Produtos** | **Região Predominante** | **Aplicação Principal** | **Convergência Metodológica** |
|:---|:---|:---|:---|:---|:---|:---|
| **Espectroscopia e Ensemble** | Random Forest, Decision Tree, Gradient Boosting | Espectroscopia (NIR), Quimiometria | Vinho, Mel | África, Europa | Autenticação e Classificação | Módulo M1 (Louvain) |
| **Cromatografia e Discriminantes** | SVM, KNN, Random Forest | Cromatografia (GC-MS, LC-MS, HPLC) | Carnes, Mel, Produtos Regionais | Ásia, Europa | Rastreabilidade e Detecção de Fraude | Módulo M2 / Cluster 3 |
| **Deep Learning e Sensores** | Redes Neurais, CNN, Deep Learning | Espectroscopia (NIR, FTIR), Sensores (e-nose) | Azeite, Queijo, Chá | Europa, Ásia | Discriminação de Origem e Qualidade | Módulo M3 / Cluster 2 |
| **Espectroscopia e Discriminantes** | SVM, KNN | Espectroscopia (NIR) | Mel | Ásia | Autenticação e Detecção de Fraude | Cluster 1 |

*Fonte: Síntese dos padrões tecnológicos identificados pela análise conjunta de comunidades Louvain e clusters hierárquicos. A convergência entre os métodos confirma a existência de "ilhas tecnológicas" especializadas.*

A convergência entre os módulos Louvain (estrutura de rede) e os clusters hierárquicos (agrupamento por similaridade) confirma a existência de "ilhas tecnológicas" especializadas. Produtos de alto valor agregado (vinhos, queijos, mel) concentram a infraestrutura analítica mais sofisticada, enquanto matrizes complexas do Sul Global permanecem sub-representadas. Essa assimetria epistêmica não apenas reflete disparidades econômicas, mas também perpetua barreiras à implementação de sistemas de Terroir Digital em regiões biodiversas que mais se beneficiariam de ferramentas auditáveis de certificação ambiental. A superação dessa fragmentação demanda protocolos federados que permitam a reutilização de parâmetros entre contextos biogeográficos distintos, viabilizando economias de escala na validação de Indicações Geográficas emergentes.

## 3.5 Evidências quantitativas e meta‑análises

A avaliação da robustez metodológica revelou que 77% dos estudos não implementaram particionamento geograficamente independente. Para mensurar o impacto dessa omissão, comparou-se o desempenho de modelos com validação espacial rigorosa versus aleatória. Conforme a Figura 5, a ausência de validação espacial resultou em uma queda média de acurácia de 11,82% em testes externos, comparada a 5,62% em modelos validados espacialmente. Essa discrepância (degradação relativa de 110%) foi estatisticamente significativa ($U = 2900, p < 0,001, d = 0,948$), corroborando a hipótese de superajuste espacial descrita por @Kuhn2013, onde a autocorrelação inflaciona métricas internas e compromete a utilidade certificatória.

**Figura 5.** Impacto da validação espacial na degradação de desempenho em testes externos. 
![](2-FIGURAS/2-EN/validacao_espacial.png){#fig:validacao_espacial width="85%"} 
*Nota: Modelos sem validação espacial apresentam queda de acurácia 110% superior quando aplicados a regiões geograficamente independentes (*$p < 0,001$, $d = 0,948$). A linha tracejada indica o limiar aceitável de degradação (≤8%) proposto para sistemas certificatórios do Terroir Digital. $n = 148$ estudos.

Quanto à transparência, apenas 13,5% dos trabalhos adotaram técnicas de Inteligência Artificial Explicável (XAI). Observou-se uma correlação negativa moderada entre explicabilidade e acurácia ($\rho = -0,481, p < 0,001$), contudo, a penalidade absoluta de desempenho foi marginal (1,53 pontos percentuais, não significativa). Em contrapartida, o custo computacional aumentou substancialmente (+67,8% em tempo de processamento). A análise de Pareto identificou o algoritmo XGBoost como o ponto ótimo de equilíbrio entre auditabilidade, acurácia e custo, superando arquiteturas de Deep Learning para fins regulatórios (Figura 6).

**Figura 6.** Trade-off entre explicabilidade algorítmica e desempenho preditivo.

![](2-FIGURAS/2-EN/tradeoff_explicabilidade.png){#fig:tradeoff_xai width="85%"} 

*Nota: Algoritmos mais explicáveis apresentam correlação negativa moderada com acurácia (*$\rho = -0,481$, $p < 0,001$), mas o custo absoluto é modesto (\~1,5 pontos percentuais). XGBoost destaca-se como algoritmo com melhor balanço multi-critério (score de Pareto = 0,650, considerando acurácia 93%, explicabilidade 6/10 e tempo 12 min). $n = 148$ estudos.

A meta-análise de 129 estudos indicou uma acurácia global (pooled) de 90,66% [IC 95%: 89,8–91,4%]. O algoritmo PLS-DA obteve o melhor desempenho médio (92,95%), seguido por Random Forest (91,33%). Entretanto, o teste de Egger detectou viés de publicação severo ($z = 40,02, p < 0,001$). A correção pelo método trim-and-fill (imputação de 42 estudos teóricos faltantes) reduziu a acurácia ajustada para ~88%, sugerindo que a literatura atual superestima a maturidade tecnológica dos modelos (Figura 7).

**Figura 7.** Meta-análise de acurácias por algoritmo de Machine Learning.

![](2-FIGURAS/2-EN/meta_analise_algoritmos.png){#fig:meta_algoritmo width="90%"} 
*Nota: (a) Forest plot mostrando que PLS-DA apresenta maior acurácia pooled (93%), enquanto SVM demonstra maior robustez (menor variância). (b) Meta-regressão temporal evidenciando tendência marginalmente positiva (slope = 0,021, $p = 0,087$, $R^2 = 6,6\%$). A heterogeneidade moderada ($I^2 = 58\%$) indica variabilidade metodológica substancial. Modelo REML, $k = 129$ estudos.

A governança de dados avaliada pelos princípios FAIR revelou um déficit estrutural crítico com score médio de 34,2/100 (±13,1), onde apenas 12,8% dos estudos alcançaram o limiar mínimo de adequação (≥50). Conforme demonstrado na Figura 8a, o radar das dimensões FAIR evidencia que Findable apresentou o melhor desempenho relativo (62%), impulsionado por alta taxa de adoção de DOIs. Em contraste, Accessible emergiu como a dimensão mais deficitária (14,5%), com apenas 10,1% dos estudos depositando dados em repositórios públicos. As dimensões Interoperable (32%) e Reusable (28,3%) também ficaram substancialmente abaixo dos benchmarks da Comissão Europeia (meta: 75/100). A Figura 8b detalha os indicadores individuais de conformidade, revelando que apenas 10% disponibilizam dados em repositórios, 15% compartilham código-fonte e 2% fornecem APIs acessíveis. A análise temporal não identificou tendência significativa de melhoria (Spearman $\rho = 0,235$, $p = 0,379$), indicando estagnação na cultura de dados abertos. Esses déficits comprometem a validação cruzada independente e perpetuam assimetrias epistêmicas entre regiões com infraestrutura laboratorial consolidada e o Sul Global.

**Figura 8.** Conformidade com princípios FAIR de governança de dados. (a) Score radar por dimensão FAIR e (b) Indicadores individuais de conformidade.

![](2-FIGURAS/2-EN/fair_radar_2.png){#fig:fair_radar width="80%"} 

## 3.5.4 Síntese Inferencial e Implicações Operacionais

A síntese inferencial do corpus delineia quatro fraturas estruturais que comprometem a transição dos atuais modelos preditivos para uma infraestrutura de Terroir Digital auditável. A primeira fratura constitui uma ilusão de robustez derivada da validação espacial deficiente. A omissão do particionamento geograficamente independente em 77% dos estudos precipita uma degradação de desempenho 110% superior em testes externos, com queda média de acurácia de 11,82% versus 5,62% em modelos validados espacialmente (U=2900, p<0,001, d=0,948). 

Essa falha metodológica, impulsionada pela autocorrelação espacial residual, impede que os sistemas funcionem como "Gêmeos Digitais Adaptativos", pois ao superajustarem-se a contextos locais, tornam-se obsoletos diante da variabilidade climática real e falham na auditoria de serviços ecossistêmicos em territórios análogos [@Kuhn2013; @Wadoux2021].

Simultaneamente, a auditabilidade regulatória é minada pela marginalização da explicabilidade. A predominância de arquiteturas opacas em 86,5% das investigações contraria diretrizes para decisões de alto risco [@Rudin2019], sustentando-se na falsa premissa de um trade-off de desempenho. A evidência estatística refuta essa narrativa, demonstrando que a diferença de acurácia entre modelos "caixa-preta" e modelos XAI é estatisticamente não significativa ($p = 0,218$), com o algoritmo XGBoost emergindo como solução ótima (score de Pareto $= 0,650$) ao equilibrar precisão e transparência. A insistência na opacidade inviabiliza a defesa jurídica da certificação, uma vez que órgãos reguladores exigem rastreabilidade causal entre marcadores químicos e variáveis ambientais, e não apenas correlações latentes intraduzíveis.

Adicionalmente, observa-se a distorção da maturidade tecnológica pelo viés de publicação. A correção via método trim-and-fill, com imputação de 42 estudos faltantes ($z = 40,02$), reduziu a acurácia pooled de ~91% para ~88%, revelando que a literatura superestima sistematicamente a capacidade discriminante dos modelos. Essa inflação métrica, somada a uma heterogeneidade metodológica moderada ($I^2 = 58\%$), compromete a calibração de riscos e alinha-se à crise de reprodutibilidade diagnosticada por @Kapoor2023, onde o vazamento de dados mascara a real eficácia das ferramentas. 

Por fim, a erosão da governança de dados perpetua assimetrias epistêmicas fundamentais. Com um score FAIR crítico de 34,2/100 e estagnação temporal na abertura de dados ($\rho = 0,235$, $p = 0,379$), o campo falha em garantir a contraprova independente. Nesse cenário, a tecnologia Blockchain, presente em 21% da amostra, atua apenas como legitimadora superficial; sem repositórios abertos e trilhas de auditoria para os sensores físicos (dimensão Accessible de apenas 14,5%), o registro imutável não resolve o "Paradoxo do Oráculo", obrigando produtores do Sul Global a dependerem de validações externas onerosas e inviabilizando a soberania sobre seus ativos digitais.

Para sanar tais déficits e operacionalizar o Terroir Digital, propõe-se a adoção mandatória de Limiares de Conformidade que exijam acurácia pós-validação espacial $\ge 85\%$ e degradação externa máxima $\le 8\%$ [@Labeyrie2021], condicionadas simultaneamente à explicabilidade XAI mandatória para marcadores territoriais críticos e à conformidade FAIR $\ge 60/100$ com deposição em repositórios interoperáveis [@Wilkinson2016FAIR]. A adesão a esses parâmetros é condição sine qua non para transmutar o Aprendizado de Máquina de ferramenta classificatória laboratorial em infraestrutura de auditoria socioecológica, reduzindo custos de certificação em até 40% através de dados federados e garantindo a auditabilidade dos serviços ecossistêmicos [@An2024EnvML_ChatGPT; @GODAN2024].


## 3.6 Barreiras à Auditabilidade e a Falência do Terroir Digital Estático

A sofisticação algorítmica vigente não se converte em robustez para a governança ambiental. A presunção de estacionariedade, implícita na metodologia dominante, constitui a limitação ontológica fundamental. A alta precisão laboratorial (80–100%) reflete a capacidade dos modelos de memorizar assinaturas químicas de safras específicas, não de apreender a causalidade do terroir. A ausência de validação longitudinal em 94% dos estudos e de testes espacialmente independentes em 77% indica baixa robustez externa dos modelos [@Ellis2024]. 

Essa omissão metodológica impede a captura da plasticidade fenotípica, onde a expressão química das plantas varia naturalmente diante de flutuações ambientais, comprometendo a causalidade do terroir [@GeneEnvironment2022]. Segundo @Kuhn2013, tal falha invalida a auditoria contínua, pois os algoritmos falham em operar como Gêmeos Digitais Inferenciais sob dinâmica climática. Neste sentido, como solução apresenta-se o Terroir Digital dinâmico, que reconstrói acoplamentos sistêmicos entre solo, clima e biota.


Quanto a  obsolescência temporal, modelos calibrados em "janelas de tempo ideais" tornam-se cegos às derivas químicas induzidas por eventos climáticos extremos, que podem alterar a composição de metabólitos secundários em mais de 20% entre ciclos produtivos [@Iranzad2025; @Urvieta2021]. Ao ignorarem a não-linearidade e os acoplamentos dinâmicos entre clima, solo e biota, os sistemas atuais degradam-se em classificadores estáticos, inaptos a operar como Gêmeos Digitais Inferenciais em cenários de mudança climática [@Novara2021; @Kuhn2013]. 

Tal fragilidade epistêmica é exacerbada pela opacidade computacional. A baixa adesão a protocolos de Inteligência Artificial Explicável (XAI) em 86,5% dos casos gera "caixas-pretas" juridicamente indefensáveis, pois a auditoria regulatória exige nexos causais rastreáveis, não correlações cegas [@Xu2021; @He2024].

Sob a perspectiva da governança, a inobservância dos princípios FAIR (score médio de 34,2/100) perpetua um colonialismo de dados. Sem a federalização de repositórios abertos, produtores do Sul Global permanecem reféns de validações exógenas onerosas, inviabilizando a Soberania Epistêmica sobre seus ativos bioculturais [@Wilkinson2016FAIR]. 

A operacionalização do Terroir Digital não reside no incremento de acurácia, mas na reestruturação da governança de dados para transmutar Indicações Geográficas de selos estáticos em certificados dinâmicos de serviços ecossistêmicos. @Rodriguez2023 aponta que, essa transformação exige calibração de modelos via sensoriamento remoto e amostragem estratégica em fronteiras agrícolas como a Amazônia. Tal abordagem constitui a única via escalável para vigilância computacional, correlacionando assinaturas químicas com práticas conservacionistas. Segundo @Osco2021, essa abordagem possibilita blindar o mercado contra o greenwashing e assegura remuneração efetiva da agrobiodiversidade, promovendo soberania epistêmica no Sul Global.

## 4. Conclusões

Esta pesquisa consolida a compreensão das Indicações Geográficas como sistemas socioecológicos acoplados, cuja tipicidade emerge de interações não lineares entre variáveis edafoclimáticas e práticas culturais. A análise crítica confirma que, embora a arquitetura inferencial do Aprendizado de Máquina detenha capacidade técnica para converter assinaturas quimiométricas em evidências de conformidade ambiental, o estado da arte atual carece da maturidade operacional necessária para sustentar um Gêmeo Digital Inferencial pleno. Tal limitação é agravada pela concentração metodológica em cadeias consolidadas de regiões temperadas, o que não apenas reproduz assimetrias epistêmicas, mas restringe severamente a transferência tecnológica para as matrizes complexas da agrobiodiversidade do Sul Global.

A certificação computacional contínua é atualmente inviabilizada por déficits estruturais críticos, notadamente a ausência de validação espacial independente e a negligência de testes longitudinais sob variabilidade climática interanual. A superação desse cenário e a consequente operacionalização do Terroir Digital como camada analítica de monitoramento adaptativo impõem, portanto, o estabelecimento de limiares estritos de robustez regulatória, definidos por uma acurácia pós-validação espacial e uma degradação máxima de desempenho em testes externos.

A explicabilidade algorítmica (XAI) deve constituir critério de due diligence ambiental, convertendo variáveis latentes em justificativas químico-ecológicas rastreáveis. Simultaneamente, a adesão aos princípios FAIR e a implementação de mecanismos de segurança de dados asseguram a integridade e a imutabilidade dos registros, requisitos indispensáveis para permitir a auditoria de terceiros e blindar o sistema contra fraudes. Tais limiares operacionais transformam métricas de desempenho em salvaguardas de legitimidade regulatória.

A efetivação da soberania epistêmica demanda uma reorientação paradigmática que substitua a competição incremental por métricas de precisão interna pela construção de uma governança computacional transparente baseada em repositórios abertos. Essa mudança estrutural viabiliza a transição para o Terroir Digital, que transcende o mero avanço instrumental para constituir uma redefinição ontológica da certificação: ao reconstruir computacionalmente os acoplamentos dinâmicos entre o genótipo territorial e o fenótipo do produto, o arcabouço converte a incerteza climática em evidências auditáveis de serviços ecossistêmicos, blindando as Indicações Geográficas contra o greenwashing.

## Agradecimentos

Os autores agradecem à Universidade Federal de Sergipe (UFS), à Universidade Estadual de Feira de Santana (UEFS) e ao Instituto Federal de Sergipe (IFS) pelo apoio institucional e infraestrutural que possibilitou esta pesquisa.

## Conflitos de Interesse

Os autores declaram não haver conflitos de interesse.

## Declaração de Disponibilidade de Dados

O conjunto de dados completo que apoia os resultados deste estudo, incluindo o corpus bibliográfico, os scripts de análise e os resultados intermediários, está disponível publicamente no repositório Open Science Framework (OSF) sob DOI: <https://doi.org/10.17605/OSF.IO/2EKYQ>.

## Declaração de Ética

Esta revisão não envolve participantes humanos, experimentos com animais, linhagens celulares ou coleta de amostras. Não foi necessária aprovação ética nem consentimento.

## Posicionamento/Envolvimento Comunitário

Quando relevante, as perspectivas da comunidade, provenientes de organizações de produtores e certificadoras, contribuíram para a interpretação das limitações práticas nos sistemas de Indicação Geográfica (IG); nenhuma informação que permitisse a identificação do indivíduo foi incluída.

## References

::: {#refs}
:::