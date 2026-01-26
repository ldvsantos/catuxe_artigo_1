#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para corrigir traduções parciais no manuscrito em inglês
Substitui frases mistas português/inglês por traduções completas
"""

import re

def corrigir_traducao_completa(arquivo_entrada, arquivo_saida):
    """Corrige todas as traduções parciais no arquivo em inglês"""
    
    with open(arquivo_entrada, 'r', encoding='utf-8') as f:
        conteudo = f.read()
    
    # Dicionário de substituições de frases completas (ordem importa - mais específicas primeiro)
    substituicoes = {
        # Abstract e introdução
        r'As Geographical Indications \(IGs\) constituem coupled socioecological systems, onde a typicity emerge de interações dinâmicas entre solo, clima e biota\. A validação desses nexos demands ferramentas auditáveis de environmental governance\.': 
        'Geographical Indications (GIs) constitute coupled socioecological systems, wherein typicity emerges from dynamic interactions among soil, climate, and biota. Validating these nexuses demands auditable environmental governance tools.',
        
        r'Within this context, o presente estudo investiga se o atual aparato de Machine Learning possui a robustez necessária para alicerçar o Digital Terroir\.':
        'Within this context, the present study investigates whether current Machine Learning apparatus possesses the necessary robustness to underpin Digital Terroir.',
        
        r'Avalia-se a adequação metodológica pela capacidade de generalization espacial e temporal dos modelos, e a \'maturidade técnica\' pelo grau de algorithmic transparency \(XAI\) e reproducibility, requisitos indispensáveis para a transição de classificadores laboratoriais para ferramentas de governança\.':
        'Methodological adequacy is evaluated by models\' spatial and temporal generalization capacity, and \'technical maturity\' by the degree of algorithmic transparency (XAI) and reproducibility, indispensable requirements for transitioning from laboratory classifiers to governance tools.',
        
        r'Investiga-se, especificamente, se os algoritmos vigentes possuem a robustez necessária para transcender a mera classificação geográfica e atuar como instrumentos de inferential auditing verificável\.':
        'Specifically, it investigates whether prevailing algorithms possess the necessary robustness to transcend mere geographical classification and act as verifiable inferential auditing instruments.',
        
        r'Em conformidade com as diretrizes PRISMA-ScR, was conducted uma síntese crítica de 148 estudos revisados por pares \(2010–2025\)\.':
        'In accordance with PRISMA-ScR guidelines, a critical synthesis of 148 peer-reviewed studies (2010–2025) was conducted.',
        
        r'Analysis evaluated padrões de validação, interpretabilidade e integração de dados ambientais para determinar a viabilidade operacional do framework proposto\.':
        'Analysis evaluated validation patterns, interpretability, and environmental data integration to determine the operational viability of the proposed framework.',
        
        r'Although os classificadores demonstrate alta accuracy discriminante \(80–100%\), o paradigma predominante de modelagem estática proves insuficiente para operacionalizar o Digital Terroir como um Inferential Digital Twin\.':
        'Although classifiers demonstrate high discriminant accuracy (80–100%), the prevailing static modeling paradigm proves insufficient to operationalize Digital Terroir as an Inferential Digital Twin.',
        
        r'A viabilidade da proposta é restringida por lacunas críticas de generalization, especificamente a ausência de longitudinal validation sob climate variability \(94%\), testes espacialmente independentes \(77%\) e algorithmic explainability \(86,5%\)\.':
        'The proposal\'s viability is constrained by critical generalization gaps, specifically the absence of longitudinal validation under climate variability (94%), spatially independent tests (77%), and algorithmic explainability (86.5%).',
        
        r'A efetivação do Digital Terroir como instrumento de sustentabilidade e epistemic sovereignty demands uma reorientação da pesquisa\. É imperativa a transição de experimentos de classificação laboratorial para o desenvolvimento de modelos adaptativos, transparentes e validados em cenários climáticos reais\.':
        'Actualizing Digital Terroir as sustainability instrument and epistemic sovereignty demands research reorientation. Transitioning from laboratory classification experiments to developing adaptive, transparent models validated under real climate scenarios is imperative.',
        
        # Seção 1 - Introduction
        r'As Geographical Indications \(IGs\) transcendem sua função original como propriedade intelectual ao surgir como instrumentos estratégicos para a environmental governance e a conservação da agrobiodiversity no Antropoceno':
        'Geographical Indications (GIs) transcend their original intellectual property function by emerging as strategic instruments for environmental governance and agrobiodiversity conservation in the Anthropocene',
        
        r'Elas representsm mecanismos para valorizar práticas agrícolas regenerativas e manter paisagens culturais, onde o \*terroir\* é redefinido não apenas como um atributo sensorial, mas como uma impressão digital do produto e da climate resilience':
        'They represent mechanisms to value regenerative agricultural practices and maintain cultural landscapes, where *terroir* is redefined not merely as a sensory attribute, but as a fingerprint of the product and climate resilience',
        
        r'A distinção entre Protected Geographical Indication \(IGP\) e Protected Designation of Origin \(DOP\) reflects diferentes graus de dependência dos ciclos naturais':
        'The distinction between Protected Geographical Indication (PGI) and Protected Designation of Origin (PDO) reflects different degrees of dependence on natural cycles',
        
        r'Essa complexidade sistêmica e a natureza difusa de seus acoplamentos limitam a detecção dos ecosystem services que sustentam a typicity e o valor do produto por métricas convencionais':
        'This systemic complexity and the diffuse nature of its couplings limit conventional metrics\' detection of ecosystem services sustaining typicity and product value',
        
        r'Consequently, a valoração desses serviços e a governança de bens comuns são fragilizadas, facilitando práticas de greenwashing':
        'Consequently, valuation of these services and commons governance are weakened, facilitating greenwashing practices',
        
        r'A ausência de instrumental analítico capaz de decifrar esses acoplamentos sistêmicos compromete o monitoramento e a fiscalização ambiental em biomas extensos':
        'The absence of analytical instrumentation capable of deciphering these systemic couplings compromises environmental monitoring and enforcement in extensive biomes',
        
        r'Within this context, o Machine Learning \(ML\) proves uma abordagem computacional intrínseca para a análise de sistemas complexos\.':
        'Within this context, Machine Learning (ML) proves an intrinsic computational approach for complex systems analysis.',
        
        r'However, a literatura carece de um framework conceitual unificado':
        'However, the literature lacks a unified conceptual framework',
        
        r'In this sense, esta revisão mapeia sistematicamente':
        'In this sense, this review systematically maps',
        
        r'is proposed o conceito de \'Digital Terroir\' como framework analítico':
        'the concept of \'Digital Terroir\' is proposed as an analytical framework',
        
        # Seção 2 - Metodologia
        r'To quantificar a abrangência e a adequação dos estudos, foram aplicadas métricas':
        'To quantify studies\' coverage and adequacy, metrics were applied',
        
        r'Essas métricas enablesm a avaliação quantitativa':
        'These metrics enable quantitative evaluation',
        
        r'mediante decomposição de tabelas de contingência':
        'through contingency table decomposition',
        
        r'a ACM enables extrair dimensões latentes':
        'MCA enables extracting latent dimensions',
        
        r'onde nós representsm entidades':
        'where nodes represent entities',
        
        r'arestas indicatesm coocorrência':
        'edges indicate co-occurrence',
        
        r'mediante correlação de Spearman':
        'through Spearman correlation',
        
        r'Finally, para avaliar a conformidade':
        'Finally, to evaluate compliance',
        
        r'mediante score padronizado':
        'through standardized score',
        
        r'Cada indicatesdor contribuiu':
        'Each indicator contributed',
        
        # Seção 3.1 - Digital Terroir Framework
        r'Adotamos neste estudo a definição constitutesva do Digital Terroir':
        'We adopt in this study the constitutive definition of Digital Terroir',
        
        r'que fornece representsção pontual do espaço físico':
        'which provides point representation of physical space',
        
        r'To o reconhecimento técnico operacional como Digital Terroir':
        'For technical operational recognition as Digital Terroir',
        
        r'A robustez de validação constitutes requisito primário, demandsndo desempenho consistente mediante spatial validationmente independente':
        'Validation robustness constitutes primary requirement, demanding consistent performance through spatially independent validation',
        
        r'séries temporais longitudinais representstivas de climate variability':
        'longitudinal time series representative of climate variability',
        
        r'A algorithmic transparency demands implementação de métodos':
        'Algorithmic transparency demands implementation of methods',
        
        # Seção 3.2 - Dominância de vinhos
        r'Queijo e café permaneceram sub-representsdos':
        'Cheese and coffee remained under-represented',
        
        r'indicatesndo expansão sistemática':
        'indicating systematic expansion',
        
        r'Essa consolidação de vinhos como categoria dominante reflects tanto a maturidade':
        'This consolidation of wines as dominant category reflects both the maturity',
        
        # Seção 3.3 - Silos tecnológicos
        r'Enquanto o framework proposto demands modelos capazes de generalization':
        'While the proposed framework demands models capable of generalization',
        
        r'As coordenadas vetoriais confirmsm a existência':
        'Vector coordinates confirm the existence',
        
        r'Observa-se forte convergência':
        'Strong convergence is observed',
        
        r'A rigidez desses agrupamentos indicates uma compartimentalização':
        'The rigidity of these groupings indicates compartmentalization',
        
        r'However, a demands por dispositivos portáteis':
        'However, demands for portable devices',
        
        r'Tal discrepância evidences a tensão atual':
        'Such discrepancy evidences current tension',
        
        r'sinalizando que a transição para Gêmeos Digitais operacionais demands não apenas':
        'signaling that transitioning to operational Digital Twins demands not only',
        
        # Seção 3.4 - Validação espacial
        r'To mensurar o impacto dessa omissão':
        'To measure this omission\'s impact',
        
        r'corroboratesndo a hipótese de overfitting espacial':
        'corroborating the spatial overfitting hypothesis',
        
        # Palavras soltas comuns em todo documento
        r'\bobserva-se\b': 'it is observed',
        r'\bpresenta-se\b': 'is presented',
        r'\bconstitutes\b': 'constitutes',
        r'\bdemands\b': 'demands',
        r'\benables\b': 'enables',
        r'\bindicates\b': 'indicates',
        r'\breflects\b': 'reflects',
        r'\bproves\b': 'proves',
        r'\bevidences\b': 'evidences',
        r'\brepresentsm\b': 'represent',
        r'\bindicatesm\b': 'indicate',
        r'\bdemandsndo\b': 'demanding',
        r'\brepresentstivas\b': 'representative',
        r'\brepresentstivos\b': 'representative',
        r'\bconfirmsm\b': 'confirm',
        r'\bcorroboratesndo\b': 'corroborating',
        r'\bsob a perspectiva\b': 'from the perspective',
        r'\bdiante de\b': 'in the face of',
        r'\bmediante\b': 'through',
        r'\bonde a\b': 'where the',
        r'\bonde o\b': 'where the',
        r'\batravés de\b': 'through',
        r'\batravés dos\b': 'through the',
    }
    
    # Aplicar substituições em ordem
    for padrao, substituicao in substituicoes.items():
        conteudo = re.sub(padrao, substituicao, conteudo, flags=re.MULTILINE)
    
    # Salvar arquivo corrigido
    with open(arquivo_saida, 'w', encoding='utf-8') as f:
        f.write(conteudo)
    
    print(f"✅ CORREÇÃO CONCLUÍDA!")
    print(f"📄 Arquivo corrigido: {arquivo_saida}")
    print(f"📊 Tamanho: {len(conteudo)/1024:.1f} KB")

if __name__ == "__main__":
    arquivo_entrada = "1-MANUSCRITO/revisao_escopo_en.md"
    arquivo_saida = "1-MANUSCRITO/revisao_escopo_en.md"
    
    corrigir_traducao_completa(arquivo_entrada, arquivo_saida)
