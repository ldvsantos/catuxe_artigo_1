#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script COMPLETO para corrigir TODAS as traduções parciais
Versão 2 - Mais abrangente e sistemática
"""

import re

def corrigir_traducao_v2(arquivo):
    with open(arquivo, 'r', encoding='utf-8') as f:
        conteudo = f.read()
    
    # Substituições de frases longas primeiro (ordem específica importa)
    subs_longas = [
        # Introdução completa
        (r'Em um cenário global marcado pela crise climática e pela erosão da biodiversidade, as IGs operam como socioecological systems que vinculam a qualidade do produto à integridade dos ecosystem services do territory',
         'In a global scenario marked by climate crisis and biodiversity erosion, GIs operate as socioecological systems linking product quality to territory ecosystem services integrity'),
        
        (r'A regulamentação internacional, fundamentada no Acordo TRIPS e no Regulamento \(UE\) n\.º 1151/2012, estabelece a base jurídica, mas é a capacidade de environmental auditing que confere legitimidade contemporânea a esses ativos',
         'International regulation, grounded in the TRIPS Agreement and Regulation (EU) No 1151/2012, establishes the legal basis, but it is environmental auditing capacity that confers contemporary legitimacy to these assets'),
        
        (r', exigindo sistemas de verificação robustos para evitar o \*greenwashing\* e garantir que o prêmio de mercado financie efetivamente a conservação ambiental',
         ', requiring robust verification systems to avoid greenwashing and ensure that market premium effectively finances environmental conservation'),
        
        (r'A credibilidade desses selos depende, portanto, da capacidade de comprovar cientificamente que as características do produto derivam de interações ambientais específicas e não replicáveis\.',
         'These seals\' credibility therefore depends on the capacity to scientifically prove that product characteristics derive from specific, non-replicable environmental interactions.'),
        
        (r'O terroir pode ser compreendido como um sistema socioecológico intrinsecamente acoplado, no qual solo, clima, biota e cultura se articulam por meio de interações não lineares, feedbacks e forte heterogeneity espacial e temporal, configurando um territory onde processos biofísicos e práticas sociais são co-produzidos',
         'Terroir can be understood as an intrinsically coupled socioecological system, wherein soil, climate, biota, and culture articulate through non-linear interactions, feedbacks, and strong spatial-temporal heterogeneity, configuring a territory where biophysical processes and social practices are co-produced'),
        
        (r', impactando a sustentabilidade em escala global',
         ', impacting sustainability on a global scale'),
        
        (r'Ao processar padrões e relações não-lineares em dados multiescalares, que incluem informações espectrais, isotópicas e metabolômicas, o ML converte a incerteza intrínseca desses sistemas em evidência auditável',
         'By processing non-linear patterns and relationships in multiscalar data, including spectral, isotopic, and metabolomic information, ML converts these systems\' intrinsic uncertainty into auditable evidence'),
        
        (r'Essa capacidade é fundamental para a environmental governance e a preservação da epistemic sovereignty das comunidades',
         'This capacity is fundamental for environmental governance and preserving communities\' epistemic sovereignty'),
        
        (r'Em escalas geográficas amplas, o ML torna possível a auditabilidade de ecosystem services, estabelecendo uma ligação verificável entre a environmental compliance e o prêmio de mercado, e mitigando as assimetrias informacionais que propiciam fraudes e apropriação indevida',
         'At broad geographical scales, ML enables ecosystem services auditability, establishing a verifiable link between environmental compliance and market premium, and mitigating informational asymmetries that facilitate fraud and misappropriation'),
        
        (r'que integre as capacidades inferencias do ML com os requisitos regulatórios de certificação ambiental\. Esta lacuna limita a tradução de avanços metodológicos em protocolos operacionais para sistemas de Indicação Geográfica, perpetuando a fragmentação entre pesquisa acadêmica e governança territorial\.',
         'that integrates ML\'s inferential capabilities with environmental certification regulatory requirements. This gap limits translating methodological advances into operational protocols for Geographical Indication systems, perpetuating fragmentation between academic research and territorial governance.'),
        
        (r'as aplicações de Machine Learning em Geographical Indications, com foco em seu potencial para autenticação ambiental e prevenção de fraudes\. A partir da síntese de 148 estudos revisados por pares \(2010–2025\),',
         'Machine Learning applications in Geographical Indications, focusing on their potential for environmental authentication and fraud prevention. From synthesizing 148 peer-reviewed studies (2010–2025),'),
        
        (r'para operacionalizar a inferential auditing de ecosystem services\. Postula-se que a modelagem dos acoplamentos não-lineares entre environmental variables \(territorial genotype\) e chemometric signatures \(product phenotype\) pode gerar evidências auditáveis de environmental compliance, convertendo alegações difusas de sustentabilidade em dados verificáveis e fundamentando políticas de conservação baseadas no mercado\.',
         'to operationalize ecosystem services inferential auditing. It is postulated that modeling non-linear couplings between environmental variables (territorial genotype) and chemometric signatures (product phenotype) can generate auditable environmental compliance evidence, converting diffuse sustainability claims into verifiable data and grounding market-based conservation policies.'),
        
        # Seção Metodologia
        (r'foram aplicadas métricas de cobertura de citações e taxas de utilização bibliográfica do corpus',
         'citation coverage metrics and corpus bibliographic utilization rates were applied'),
        
        (r'garantindo que os estudos selecionados reflitam adequadamente o escopo temático da revisão\.',
         'ensuring selected studies adequately reflect the review\'s thematic scope.'),
        
        (r'Implementada com o pacote `FactoMineR`,',
         'Implemented with the `FactoMineR` package,'),
        
        (r'que explicam a variância nas associações entre categorias\. Complementarmente, aplicou-se Análise de Cluster \(k-means e hierárquica\) com o pacote `factoextra` para identificar agrupamentos recorrentes entre combinações produto-instrumento-algoritmo\.',
         'explaining variance in category associations. Complementarily, Cluster Analysis (k-means and hierarchical) was applied with the `factoextra` package to identify recurring groupings among product-instrument-algorithm combinations.'),
        
        (r'com particionamento geográfico',
         'with geographical partitioning'),
        
        (r'interanual e testes de transferência entre safras, lotes e regiões comparáveis\.',
         'interannual and transfer tests across comparable harvests, batches, and regions.'),
        
        (r'de Explainable Artificial Intelligence \(XAI\)',
         'of Explainable Artificial Intelligence (XAI)'),
        
        (r'capazes de identificar territorial markers com plausibilidade físico-química, rastrear decisões de autenticação até environmental variables causais e rejeitar correlações espúrias sem fundamentação ecológica\.',
         'capable of identifying territorial markers with physicochemical plausibility, tracing authentication decisions to causal environmental variables, and rejecting spurious correlations without ecological foundation.'),
        
        # Seção Resultados
        (r'Essa predominância de arquiteturas supervisionadas sobre métodos não supervisionados',
         'This predominance of supervised architectures over unsupervised methods'),
        
        (r'a disponibilidade de conjuntos de dados rotulados e a pressão por métricas de accuracy quantificáveis, conforme documentado por',
         'labeled dataset availability and pressure for quantifiable accuracy metrics, as documented by'),
        
        (r'enquanto PLS-DA manteve relevância no pré-processamento quimiométrico',
         'while PLS-DA maintained relevance in chemometric preprocessing'),
        
        (r', estabelecendo um paradigma instrumental que favorece produtos de alto valor agregado com infraestrutura analítica consolidada\.',
         ', establishing an instrumental paradigm favoring high-value-added products with consolidated analytical infrastructure.'),
        
        (r'A distribuição geográfica dos estudos analisados',
         'The analyzed studies\' geographical distribution'),
        
        (r'um desequilíbrio na representstividade amostral, com 72% do corpus concentrado em produtos europeus e asiáticos',
         'an imbalance in sampling representativeness, with 72% of corpus concentrated on European and Asian products'),
        
        (r'Tal concentração',
         'Such concentration'),
        
        (r'que a infraestrutura de autenticação digital avança prioritariamente em sistemas de IGs consolidados, enquanto regiões do Sul Global apresentam menor volume de publicações, refletindo disparidades no acesso a tecnologias de caracterização analítica',
         'that digital authentication infrastructure advances primarily in consolidated GI systems, while Global South regions present lower publication volumes, reflecting disparities in access to analytical characterization technologies'),
        
        (r'A análise temporal',
         'Temporal analysis'),
        
        (r'correlação positiva entre a produção acadêmica e a complexidade algorítmica',
         'positive correlation between academic production and algorithmic complexity'),
        
        (r', observando-se um aumento na adoção de \*Deep Learning\* de 5% \(2010–2015\) para 28% \(2020–2025\)\. Entretanto, a validação desses modelos apresenta limitações estruturais: a ausência de testes longitudinais em 94% dos trabalhos',
         ', observing a Deep Learning adoption increase from 5% (2010–2015) to 28% (2020–2025). However, these models\' validation presents structural limitations: longitudinal testing absence in 94% of works'),
        
        (r'que os algoritmos são calibrados para condições sazonais específicas\. Essa característica restringe a capacidade de',
         'that algorithms are calibrated for specific seasonal conditions. This characteristic restricts'),
        
        (r'dos modelos frente à variabilidade climática interanual, comprometendo sua aplicabilidade como ferramentas de auditoria contínua\.',
         'of models facing interannual climate variability, compromising their applicability as continuous auditing tools.'),
        
        (r'A análise de redes',
         'Network analysis'),
        
        (r'a formação de agrupamentos metodológicos distintos',
         'the formation of distinct methodological clusters'),
        
        (r'A correlação entre algoritmos específicos e técnicas instrumentais \(como Redes Neurais associadas a dados espectrais\)',
         'The correlation between specific algorithms and instrumental techniques (such as Neural Networks associated with spectral data)'),
        
        (r'uma compartimentalização do desenvolvimento técnico\. Essa estrutura modular',
         'a compartmentalization of technical development. This modular structure'),
        
        (r'que a transferência de parâmetros entre diferentes classes de produtos e instrumentos analíticos permanece limitada, dificultando a padronização de protocolos universais para a certificação digital de origem\.',
         'that parameter transfer between different product classes and analytical instruments remains limited, hindering universal protocol standardization for digital origin certification.'),
        
        # Produtos específicos
        (r'\(4 e 1 registros, respectivamente\)\. A correlação de Spearman confirmou tendência ascendente para vinhos \(ρ = 0,615, p = 0,011\),',
         '(4 and 1 records, respectively). Spearman correlation confirmed ascending trend for wines (ρ = 0.615, p = 0.011),'),
        
        (r'após 2020',
         'after 2020'),
        
        (r'dos sistemas de IG europeus quanto a disponibilidade de dados espectrais padronizados, contrastando com a fragmentação observada em categorias em ascensão como café,',
         'of European GI systems and spectral data availability, contrasting with fragmentation observed in rising categories such as coffee,'),
        
        (r'de métodos de processamento dificulta a criação de assinaturas químicas universais\.',
         'of processing methods hinders creating universal chemical signatures.'),
        
        # Silos tecnológicos
        (r'A compartimentalização das abordagens metodológicas configurou-se como obstáculo crítico à operacionalização do Digital Terroir como sistema adaptativo e transferível\.',
         'Methodological approaches compartmentalization configured itself as critical obstacle to operationalizing Digital Terroir as adaptive and transferable system.'),
        
        (r'espacial e temporal',
         'spatial and temporal'),
        
        (r'através de diferentes produtos e regiões, a análise revelou formação de "silos tecnológicos" rígidos que limitam a interoperabilidade entre técnicas instrumentais e algoritmos\.',
         'across different products and regions, analysis revealed formation of rigid "technological silos" limiting interoperability between instrumental techniques and algorithms.'),
        
        (r'Essa compartimentalização metodológica não',
         'This methodological compartmentalization does not'),
        
        (r'meramente preferências técnicas, mas',
         'merely technical preferences, but'),
        
        (r'a sedimentação de práticas laboratoriais regionais ao longo de décadas, consolidadas',
         'the sedimentation of regional laboratory practices over decades, consolidated'),
        
        (r'através de publicações, transferência de conhecimento entre grupos de pesquisa e padronização de protocolos em agências regulatórias',
         'through publications, knowledge transfer between research groups, and protocol standardization in regulatory agencies'),
        
        (r'\. Tal rigidez estrutural compromete a visão do Digital Terroir como infraestrutura universalmente aplicável, exigindo protocolos multimodais que transcendam especializações regionais\.',
         '. Such structural rigidity compromises Digital Terroir vision as universally applicable infrastructure, requiring multimodal protocols transcending regional specializations.'),
        
        (r'de "tríades tecnológicas" estáveis\.',
         'of stable "technological triads".'),
        
        (r'entre Vinhos, Random Forest e NIR \(0,85; 0,32\), em oposição ao cluster formado por Chás, SVM e GC-MS \(-0,67; 0,91\)\.',
         'between Wines, Random Forest, and NIR (0.85; 0.32), in opposition to the cluster formed by Teas, SVM, and GC-MS (-0.67; 0.91).'),
        
        (r'metodológica que restringe a inovação interdisciplinar',
         'methodological compartmentalization restricting interdisciplinary innovation'),
        
        (r'\. A formação desses silos impede que avanços algorítmicos obtidos em uma tríade instrumental sejam transferidos para outras, limitando a',
         '. These silos\' formation prevents algorithmic advances obtained in one instrumental triad from being transferred to others, limiting'),
        
        (r'das arquiteturas de autenticação',
         'of authentication architectures'),
        
        (r', requisito fundamental para um Digital Terroir verdadeiramente interoperável entre diferentes matrizes alimentares e contextos geográficos\.',
         ', fundamental requirement for a truly interoperable Digital Terroir across different food matrices and geographical contexts.'),
        
        (r'No cenário recente, a fusão de dados multimodal \(28%\) e a integração com \*blockchain\* \(9%\) despontam como fronteiras de expansão tecnológica que, em tese, atendem aos critérios de auditabilidade do framework proposto\.',
         'In recent scenario, multimodal data fusion (28%) and blockchain integration (9%) emerge as technological expansion frontiers that, in theory, meet the proposed framework\'s auditability criteria.'),
        
        (r'\*field-deployable\* impõe um \*trade-off\* metrológico que tensiona os requisitos do Digital Terroir: a necessária compressão de modelos para operação \*in situ\* resulta em uma perda de accuracy de 10–15% em comparação aos padrões laboratoriais',
         'field-deployable imposes a metrological trade-off tensioning Digital Terroir requirements: necessary model compression for in situ operation results in 10–15% accuracy loss compared to laboratory standards'),
        
        (r'entre a acessibilidade das ferramentas de campo e a robustez exigida para a certificação oficial,',
         'between field tool accessibility and robustness required for official certification,'),
        
        (r'não apenas avanços algorítmicos, mas também inovação em hardware analítico portátil que preserve a precisão metrológica\.',
         'not only algorithmic advances but also innovation in portable analytical hardware preserving metrological precision.'),
        
        # Validação espacial
        (r'apresentam queda de accuracy 110% superior quando aplicados a regiões geograficamente independentes',
         'present 110% higher accuracy drop when applied to geographically independent regions'),
        
        (r'\. A linha tracejada',
         '. The dashed line'),
        
        (r'o limiar aceitável de degradação \(≤8%\) proposto para sistemas certificatórios do Digital Terroir\.',
         'the acceptable degradation threshold (≤8%) proposed for Digital Terroir certification systems.'),
        
        # Meta-análise
        (r'apresentam as maiores accuracys consolidadas, enquanto SVM demonstra maior robustez \(menor variância entre estudos\)\. A',
         'present the highest consolidated accuracies, while SVM demonstrates greater robustness (lower variance across studies). The'),
        
        (r'moderada \(\*\$I\^2 = 58\\%\)',
         'moderate (*$I^2 = 58\\%$)'),
        
        (r'variabilidade metodológica substancial entre estudos\. Os intervalos de confiança',
         'substantial methodological variability across studies. Confidence intervals'),
        
        (r'estimativas de efeitos aleatórios \(modelo REML\)\.',
         'random effects estimates (REML model).'),
    ]
    
    # Aplicar substituições longas
    for original, traducao in subs_longas:
        conteudo = re.sub(original, traducao, conteudo, flags=re.MULTILINE)
    
    # Salvar
    with open(arquivo, 'w', encoding='utf-8') as f:
        f.write(conteudo)
    
    print("✅ Tradução completa corrigida!")
    print(f"📊 Tamanho final: {len(conteudo)/1024:.1f} KB")

if __name__ == "__main__":
    arquivo = "1-MANUSCRITO/revisao_escopo_en.md"
    corrigir_traducao_v2(arquivo)
