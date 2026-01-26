#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SISTEMA INTEGRADO DE ANÁLISE - REVISÃO DE ESCOPO
Tema: Machine Learning aplicado a Indicações Geográficas
Fonte: Scopus + Web of Science (combinados)
Versão: 2.0 - Análise Integrada de Múltiplas Fontes
"""

import re
import os
from typing import List, Set, Dict, Tuple
from collections import defaultdict

# ============================================================================
# CONFIGURAÇÃO: CRITÉRIOS DE FILTRAGEM E PONTUAÇÃO
# ============================================================================

# Termos PRIORITÁRIOS (peso alto): 3 pontos cada
TERMOS_PRIORITARIOS = {
    'sat': [
        'traditional agricultural system', 'traditional farming system',
        'traditional agriculture', 'traditional agroecosystem',
        'sistemas agrícolas tradicionais', 'sistema agrícola tradicional',
        'agricultura tradicional', 'agroecolog',
        'socioecological system', 'socio-ecological system',
        'biocultural', 'cultural landscape', 'agrobiodiversity',
        'traditional knowledge', 'indigenous knowledge', 'local knowledge',
        'shifting cultivation', 'slash-and-burn'
    ]
}

# Termos de ALTA relevância (peso médio): 1.5 pontos cada
TERMOS_ALTA = {
    'ml': [
        'machine learning', 'artificial intelligence', 'deep learning',
        'random forest', 'neural network', 'support vector machine', 'svm',
        'classification model', 'predictive model', 'ensemble learning',
        'decision tree', 'data mining',
        'supervised learning', 'unsupervised learning',
        'gradient boosting', 'naive bayes', 'k-nearest neighbor', 'knn',
        'convolutional neural network', 'cnn',
        'artificial neural network', 'ann',
        'explainable ai', 'explainable artificial intelligence',
        'xai', 'model interpretability', 'feature importance'
    ]
}

# Termos de relevância ADEQUADA: 0.5 pontos cada
TERMOS_ADEQUADOS = [
    'modeling', 'modelling', 'spatial analysis', 'remote sensing',
    'gis', 'geographic information system'
]

# Critérios de exclusão
TERMOS_EXCLUSAO = [
    'review', 'systematic review', 'meta-analysis',
    'book chapter', 'conference', 'editorial'
]

# Pontuação de referência
SCORE_EXCELENCIA = 12  # >= 12 pontos (Muito relevante) - REDUZIDO DE 15
SCORE_ALTA = 6         # >= 6 pontos (Relevante) - REDUZIDO DE 8
SCORE_ADEQUADA = 2     # >= 2 pontos (Ao menos um termo forte) - REDUZIDO DE 3
SCORE_BAIXA = 0        # < 2 pontos (incerto)

# ============================================================================
# PARTE 1: PROCESSAMENTO DE ARQUIVOS BIB
# ============================================================================

def extrair_referencias_bib(arquivo_bib: str, fonte: str) -> Dict[str, Dict]:
    """
    Extrai referências de arquivo BibTeX com identificação de fonte
    """
    referencias = {}
    ref_atual = None
    
    print(f"\n📚 Processando {fonte}: {os.path.basename(arquivo_bib)}...")
    
    try:
        with open(arquivo_bib, 'r', encoding='utf-8', errors='ignore') as arquivo:
            conteudo_completo = []
            
            for linha in arquivo:
                # Nova entrada começa com @
                if linha.strip().startswith('@'):
                    match = re.match(r'@(\w+)\{([^,]+),', linha)
                    if match:
                        tipo, chave = match.groups()
                        chave = chave.strip()
                        
                        # Adicionar fonte à chave para evitar duplicatas
                        chave_unica = f"{chave}_{fonte}"
                        
                        referencias[chave_unica] = {
                            'tipo': tipo,
                            'chave_original': chave,
                            'chave_unica': chave_unica,
                            'fonte': fonte,
                            'title': '',
                            'author': '',
                            'year': '',
                            'abstract': '',
                            'keywords': '',
                            'affiliations': '',
                            'address': '',
                            'author_keywords': '',
                            'journal': '',
                            'conteudo_completo': ''
                        }
                        ref_atual = chave_unica
                        conteudo_completo = []
                
                elif ref_atual:
                    conteudo_completo.append(linha)
                
                # Fim de uma entrada (linha com apenas })
                if linha.strip() == '}' and ref_atual:
                    # Juntar todas as linhas da entrada
                    entry_text = ''.join(conteudo_completo)
                    referencias[ref_atual]['conteudo_completo'] = entry_text.lower()
                    
                    # Extrair campos suportando multilinhas (DOTALL)
                    # Scopus usa 'affiliations' e 'author_keywords'
                    # WoS usa 'address' e 'keywords'
                    campos_extracao = ['title', 'author', 'year', 'abstract', 'keywords', 
                                     'affiliations', 'address', 'author_keywords', 'journal']
                    
                    for campo in campos_extracao:
                        # Regex procura: campo = { conteudo }
                        # [^}]+ tenta pegar tudo até o fechamento. 
                        # Nota: BibTeX aninhado pode falhar com regex simples, mas para export padrão funciona bem
                        padrao = rf'{campo}\s*=\s*\{{(.+?)\}}\s*(?:,|$)'
                        match = re.search(padrao, entry_text, re.IGNORECASE | re.DOTALL)
                        if match:
                            # Remover quebras de linha e espaços extras do valor extraído
                            valor = match.group(1).replace('\n', ' ').replace('\r', ' ')
                            valor = ' '.join(valor.split())
                            referencias[ref_atual][campo] = valor

                    ref_atual = None
        
        print(f"   ✅ {len(referencias)} referências extraídas de {fonte}")
        return referencias
    
    except FileNotFoundError:
        print(f"   ❌ Arquivo não encontrado: {arquivo_bib}")
        return {}
    except Exception as e:
        print(f"   ❌ Erro ao processar {arquivo_bib}: {e}")
        return {}

def remover_duplicatas(refs_scopus: Dict, refs_wos: Dict) -> Tuple[Dict, Dict]:
    """
    Remove duplicatas entre Scopus e WoS baseado em título/ano/autor
    Mantém a referência da fonte considerada mais completa
    """
    print("\n🔄 Removendo duplicatas entre Scopus e Web of Science...")
    
    # Criar índice de títulos normalizados do Scopus
    titulos_scopus = {}
    for chave, ref in refs_scopus.items():
        titulo_norm = re.sub(r'[^\w\s]', '', ref.get('title', '').lower())
        titulo_norm = ' '.join(titulo_norm.split())  # normalizar espaços
        if titulo_norm:
            titulos_scopus[titulo_norm] = chave
    
    # Verificar WoS contra Scopus
    duplicatas = []
    refs_wos_unicas = {}
    
    for chave_wos, ref_wos in refs_wos.items():
        titulo_norm = re.sub(r'[^\w\s]', '', ref_wos.get('title', '').lower())
        titulo_norm = ' '.join(titulo_norm.split())
        
        if titulo_norm in titulos_scopus:
            duplicatas.append(chave_wos)
            print(f"   🔄 Duplicata encontrada: {ref_wos.get('title', '')[:60]}...")
        else:
            refs_wos_unicas[chave_wos] = ref_wos
    
    print(f"   ✅ Duplicatas removidas: {len(duplicatas)}")
    print(f"   ✅ Referências únicas do WoS: {len(refs_wos_unicas)}")
    
    return refs_scopus, refs_wos_unicas

def combinar_referencias(refs_scopus: Dict, refs_wos_unicas: Dict) -> Dict:
    """
    Combina referências de ambas as fontes
    """
    referencias_combinadas = {}
    
    # Adicionar Scopus
    referencias_combinadas.update(refs_scopus)
    
    # Adicionar WoS (já sem duplicatas)
    referencias_combinadas.update(refs_wos_unicas)
    
    print(f"\n📊 Base combinada:")
    print(f"   • Scopus: {len(refs_scopus)} refs")
    print(f"   • Web of Science: {len(refs_wos_unicas)} refs")
    print(f"   • TOTAL: {len(referencias_combinadas)} refs únicas")
    
    return referencias_combinadas

# ============================================================================
# PARTE 2: SISTEMA DE PONTUAÇÃO
# ============================================================================

def calcular_score(referencia: Dict) -> Tuple[float, List[str]]:
    """
    Calcula score baseado nos critérios definidos
    """
    score = 0.0
    termos_encontrados = []
    
    # Preparar texto para busca
    titulo = referencia.get('title', '').lower()
    abstract = referencia.get('abstract', '').lower()
    keywords = referencia.get('keywords', '').lower()
    conteudo = referencia.get('conteudo_completo', '').lower()
    
    # PRIORITÁRIOS (3 pontos cada)
    for categoria, termos in TERMOS_PRIORITARIOS.items():
        for termo in termos:
            termo_lower = termo.lower()
            count = 0
            localizacao = []
            
            if termo_lower in titulo:
                count += 1
                localizacao.append('título')
            if termo_lower in keywords:
                count += 1
                localizacao.append('keywords')
            if termo_lower in abstract:
                count += 1
                localizacao.append('abstract')
            elif termo_lower in conteudo:
                count += 1
                localizacao.append('conteúdo')
            
            if count > 0:
                pontos = count * 3.0
                score += pontos
                local = ', '.join(localizacao)
                termos_encontrados.append(f"🔴 PRIORITÁRIO ({local}): {termo}")
    
    # ALTA RELEVÂNCIA (1.5 pontos cada)
    for categoria, termos in TERMOS_ALTA.items():
        for termo in termos:
            termo_lower = termo.lower()
            if (termo_lower in titulo or termo_lower in keywords or 
                termo_lower in abstract or termo_lower in conteudo):
                score += 1.5
                termos_encontrados.append(f"🟠 ALTA: {termo}")
    
    # ADEQUADA (0.5 pontos cada)
    for termo in TERMOS_ADEQUADOS:
        termo_lower = termo.lower()
        if (termo_lower in titulo or termo_lower in keywords or 
            termo_lower in abstract or termo_lower in conteudo):
            score += 0.5
            termos_encontrados.append(f"🟡 ADEQUADA: {termo}")
    
    return score, termos_encontrados

def verificar_exclusao(referencia: Dict) -> Tuple[bool, str]:
    """
    Verifica critérios de exclusão
    """
    titulo = referencia.get('title', '').lower()
    tipo = referencia.get('tipo', '').lower()
    conteudo = referencia.get('conteudo_completo', '').lower()
    
    for termo in TERMOS_EXCLUSAO:
        if termo.lower() in titulo or termo.lower() in tipo or termo.lower() in conteudo:
            return True, f"Excluído: {termo}"
    
    return False, ""

# ============================================================================
# PARTE 3: FILTRAGEM E CLASSIFICAÇÃO
# ============================================================================

def filtrar_e_classificar(referencias: Dict) -> Dict:
    """
    Filtra e classifica referências por relevância
    """
    print("\n" + "="*80)
    print("🔍 INICIANDO FILTRAGEM E CLASSIFICAÇÃO")
    print("="*80)
    
    resultados = {
        'excelencia': [],
        'alta': [],
        'adequada': [],
        'baixa': [],
        'excluidas': []
    }
    
    for chave, ref in referencias.items():
        # Verificar exclusão
        excluir, motivo = verificar_exclusao(ref)
        if excluir:
            resultados['excluidas'].append((chave, ref, 0.0, [], motivo))
            continue
        
        # Calcular score
        score, termos = calcular_score(ref)
        
        # Classificar
        if score >= SCORE_EXCELENCIA:
            resultados['excelencia'].append((chave, ref, score, termos))
        elif score >= SCORE_ALTA:
            resultados['alta'].append((chave, ref, score, termos))
        elif score >= SCORE_ADEQUADA:
            resultados['adequada'].append((chave, ref, score, termos))
        else:
            resultados['baixa'].append((chave, ref, score, termos))
    
    # Ordenar por score (decrescente)
    for categoria in ['excelencia', 'alta', 'adequada', 'baixa']:
        resultados[categoria].sort(key=lambda x: x[2], reverse=True)
    
    return resultados

# ============================================================================
# PARTE 4: RELATÓRIOS
# ============================================================================

def gerar_relatorio_completo(resultados: Dict, arquivo_saida: str):
    """
    Gera relatório detalhado da análise - APENAS ARTIGOS RELEVANTES
    """
    total = sum(len(resultados[cat]) for cat in ['excelencia', 'alta', 'adequada', 'baixa', 'excluidas'])
    relevantes = sum(len(resultados[cat]) for cat in ['excelencia', 'alta', 'adequada'])
    
    with open(arquivo_saida, 'w', encoding='utf-8') as rel:
        rel.write("="*90 + "\n")
        rel.write("RELATÓRIO CONSOLIDADO - ARTIGOS RELEVANTES\n")
        rel.write("Tema: Machine Learning aplicado a Sistemas Agrícolas Tradicionais\n")
        rel.write("Fontes: Scopus + Web of Science (Combinados)\n")
        rel.write("="*90 + "\n\n")
        
        # Resumo Executivo
        rel.write("📊 RESUMO EXECUTIVO\n")
        rel.write("-"*90 + "\n")
        rel.write(f"Total analisado: {total}\n")
        rel.write(f"✅ RELEVANTES SELECIONADOS: {relevantes} ({relevantes/total*100:.1f}%)\n")
        rel.write(f"❌ Não selecionados (baixa relevância + excluídos): {total-relevantes} ({(total-relevantes)/total*100:.1f}%)\n\n")
        
        rel.write(f"🏆 Excelência (≥{SCORE_EXCELENCIA} pts): {len(resultados['excelencia'])}\n")
        rel.write(f"🥈 Alta relevância (≥{SCORE_ALTA} pts): {len(resultados['alta'])}\n")
        rel.write(f"🥉 Adequada (≥{SCORE_ADEQUADA} pts): {len(resultados['adequada'])}\n\n")
        
        # Distribuição por fonte
        rel.write("📚 DISTRIBUIÇÃO POR FONTE (Artigos Relevantes)\n")
        rel.write("-"*90 + "\n")
        fontes_count = defaultdict(int)
        fontes_por_categoria = defaultdict(lambda: defaultdict(int))
        
        for cat_key, cat_name in [('excelencia', 'Excelência'), ('alta', 'Alta'), ('adequada', 'Adequada')]:
            for item in resultados[cat_key]:
                fonte = item[1].get('fonte', 'desconhecido')
                fontes_count[fonte] += 1
                fontes_por_categoria[fonte][cat_name] += 1
        
        for fonte in sorted(fontes_count.keys()):
            rel.write(f"  • {fonte}: {fontes_count[fonte]} artigos\n")
            categorias = fontes_por_categoria[fonte]
            detalhes = []
            if categorias['Excelência'] > 0:
                detalhes.append(f"{categorias['Excelência']} excelência")
            if categorias['Alta'] > 0:
                detalhes.append(f"{categorias['Alta']} alta")
            if categorias['Adequada'] > 0:
                detalhes.append(f"{categorias['Adequada']} adequada")
            rel.write(f"    ({', '.join(detalhes)})\n")
        rel.write("\n")
        
        # Distribuição temporal
        rel.write("📅 DISTRIBUIÇÃO TEMPORAL (Artigos Relevantes)\n")
        rel.write("-"*90 + "\n")
        anos_count = defaultdict(int)
        for cat in ['excelencia', 'alta', 'adequada']:
            for item in resultados[cat]:
                ano = item[1].get('year', 'N/A')[:4]
                if ano.isdigit():
                    anos_count[int(ano)] += 1
        
        for ano in sorted(anos_count.keys()):
            barra = "█" * anos_count[ano]
            rel.write(f"  {ano}: {barra} ({anos_count[ano]})\n")
        rel.write("\n")
        
        # Detalhamento por categoria
        rel.write("\n" + "="*90 + "\n")
        rel.write(f"📋 LISTA COMPLETA DOS {relevantes} ARTIGOS RELEVANTES\n")
        rel.write("="*90 + "\n\n")
        
        contador_geral = 1
        for categoria_nome, categoria_key, emoji in [
            ('EXCELÊNCIA', 'excelencia', '🏆'),
            ('ALTA RELEVÂNCIA', 'alta', '🥈'),
            ('ADEQUADA', 'adequada', '🥉')
        ]:
            if resultados[categoria_key]:
                rel.write("\n" + "-"*90 + "\n")
                rel.write(f"{emoji} {categoria_nome} ({len(resultados[categoria_key])} artigos)\n")
                rel.write("-"*90 + "\n\n")
                
                for chave, ref, score, termos in resultados[categoria_key]:
                    titulo = ref.get('title', 'Sem título')
                    ano = ref.get('year', 'N/A')[:4]
                    autor = ref.get('author', 'N/A')
                    fonte = ref.get('fonte', 'desconhecido')
                    chave_orig = ref.get('chave_original', chave)
                    
                    rel.write(f"{contador_geral}. [{fonte}] {chave_orig}\n")
                    rel.write(f"   📊 Score: {score:.1f} pontos\n")
                    rel.write(f"   📅 Ano: {ano}\n")
                    rel.write(f"   👤 Autor(es): {autor[:100]}{'...' if len(autor) > 100 else ''}\n")
                    rel.write(f"   📖 Título: {titulo}\n")
                    
                    if termos:
                        rel.write(f"   🔍 Termos encontrados ({len(termos)}):\n")
                        for termo in termos[:15]:  # Mostrar até 15 termos
                            rel.write(f"      • {termo}\n")
                        if len(termos) > 15:
                            rel.write(f"      ... e mais {len(termos)-15} termos\n")
                    rel.write("\n")
                    contador_geral += 1
    
    print(f"\n💾 Relatório salvo em: {arquivo_saida}")

def gerar_bibliografia_filtrada(resultados: Dict, arquivo_saida: str):
    """
    Gera arquivo BibTeX apenas com referências relevantes
    """
    print(f"\n📝 Gerando bibliografia filtrada...")
    
    with open(arquivo_saida, 'w', encoding='utf-8') as bib:
        bib.write("% Bibliografia Filtrada - Revisão de Escopo\n")
        bib.write("% ML aplicado a Sistemas Agrícolas Tradicionais\n")
        bib.write("% Fontes: Scopus + Web of Science\n\n")
        
        for categoria in ['excelencia', 'alta', 'adequada']:
            if resultados[categoria]:
                bib.write(f"\n% ============= {categoria.upper()} =============\n\n")
                
                for chave, ref, score, termos in resultados[categoria]:
                    # Reconstruir entrada BibTeX
                    tipo = ref.get('tipo', 'article')
                    chave_orig = ref.get('chave_original', chave)
                    
                    bib.write(f"@{tipo}{{{chave_orig},\n")
                    
                    # Campos padrão
                    for campo in ['author', 'title', 'journal', 'year', 'volume', 'pages', 'doi', 'abstract']:
                        valor = ref.get(campo, '')
                        if valor:
                            bib.write(f"  {campo} = {{{valor}}},\n")
                    
                    # Campos de metadados extras (para análise)
                    for campo in ['keywords', 'author_keywords', 'affiliations', 'address']:
                        valor = ref.get(campo, '')
                        if valor:
                            bib.write(f"  {campo} = {{{valor}}},\n")
                            
                    # Adicionar nota com fonte e score
                    fonte = ref.get('fonte', '')
                    bib.write(f"  note = {{Fonte: {fonte}, Score: {score:.1f}}},\n")
                    
                    bib.write("}\n\n")
    
    print(f"   ✅ Bibliografia salva em: {arquivo_saida}")

def exibir_resumo_terminal(resultados: Dict):
    """
    Exibe resumo no terminal
    """
    total = sum(len(resultados[cat]) for cat in ['excelencia', 'alta', 'adequada', 'baixa', 'excluidas'])
    relevantes = sum(len(resultados[cat]) for cat in ['excelencia', 'alta', 'adequada'])
    
    print("\n" + "="*80)
    print("📋 RESUMO DA ANÁLISE")
    print("="*80)
    
    print(f"\n📊 ESTATÍSTICAS:")
    print(f"  • Total analisado: {total}")
    print(f"  • Relevantes: {relevantes} ({relevantes/total*100:.1f}%)")
    print(f"  • Excluídos: {len(resultados['excluidas'])}")
    
    print(f"\n🎯 CLASSIFICAÇÃO POR RELEVÂNCIA:")
    print(f"  • Excelência: {len(resultados['excelencia'])}")
    print(f"  • Alta: {len(resultados['alta'])}")
    print(f"  • Adequada: {len(resultados['adequada'])}")
    print(f"  • Baixa: {len(resultados['baixa'])}")
    
    # Distribuição por fonte
    print(f"\n📚 DISTRIBUIÇÃO POR FONTE:")
    fontes_count = defaultdict(int)
    for cat in ['excelencia', 'alta', 'adequada']:
        for item in resultados[cat]:
            fonte = item[1].get('fonte', 'desconhecido')
            fontes_count[fonte] += 1
    
    for fonte, count in sorted(fontes_count.items()):
        print(f"  • {fonte}: {count} artigos")

# ============================================================================
# FUNÇÃO PRINCIPAL
# ============================================================================

def main():
    """
    Executa análise completa combinando Scopus + Web of Science
    """
    print("="*80)
    print("🔍 SISTEMA INTEGRADO DE ANÁLISE - REVISÃO DE ESCOPO")
    print("Tema: Machine Learning aplicado a Sistemas Agrícolas Tradicionais")
    print("Fontes: Scopus + Web of Science")
    print("="*80)
    
    # Configuração de arquivos
    arquivo_scopus = 'scopus_export.bib'
    arquivo_wos = 'wos_export.bib'
    
    # Verificar existência
    scopus_exists = os.path.exists(arquivo_scopus)
    wos_exists = os.path.exists(arquivo_wos)
    
    if not scopus_exists and not wos_exists:
        print("\n❌ Nenhum arquivo de corpus encontrado!")
        print(f"   Esperado: {arquivo_scopus} ou {arquivo_wos}")
        return
    
    # ETAPA 1: Extrair referências
    print("\n" + "="*80)
    print("ETAPA 1: EXTRAÇÃO DE REFERÊNCIAS")
    print("="*80)
    
    refs_scopus = {}
    refs_wos = {}
    
    if scopus_exists:
        refs_scopus = extrair_referencias_bib(arquivo_scopus, 'Scopus')
    else:
        print(f"\n⚠️  Arquivo Scopus não encontrado: {arquivo_scopus}")
    
    if wos_exists:
        refs_wos = extrair_referencias_bib(arquivo_wos, 'WoS')
    else:
        print(f"\n⚠️  Arquivo WoS não encontrado: {arquivo_wos}")
    
    if not refs_scopus and not refs_wos:
        print("\n❌ Nenhuma referência extraída!")
        return
    
    # ETAPA 2: Remover duplicatas e combinar
    print("\n" + "="*80)
    print("ETAPA 2: REMOÇÃO DE DUPLICATAS E COMBINAÇÃO")
    print("="*80)
    
    if refs_scopus and refs_wos:
        refs_scopus, refs_wos_unicas = remover_duplicatas(refs_scopus, refs_wos)
        referencias = combinar_referencias(refs_scopus, refs_wos_unicas)
    elif refs_scopus:
        referencias = refs_scopus
        print(f"\n📊 Usando apenas Scopus: {len(referencias)} refs")
    else:
        referencias = refs_wos
        print(f"\n📊 Usando apenas WoS: {len(referencias)} refs")
    
    # ETAPA 3: Filtrar e classificar
    print("\n" + "="*80)
    print("ETAPA 3: FILTRAGEM E CLASSIFICAÇÃO")
    print("="*80)
    
    resultados = filtrar_e_classificar(referencias)
    
    # ETAPA 4: Gerar relatórios
    print("\n" + "="*80)
    print("ETAPA 4: GERAÇÃO DE RELATÓRIOS")
    print("="*80)
    
    # Criar diretório se não existir
    os.makedirs('../relatorios', exist_ok=True)
    
    gerar_relatorio_completo(
        resultados,
        '../relatorios/relatorio_analise_scopus_wos.txt'
    )
    
    gerar_bibliografia_filtrada(
        resultados,
        '../referencias_filtradas/referencias_scopus_wos_filtradas.bib'
    )
    
    exibir_resumo_terminal(resultados)
    
    print("\n" + "="*80)
    print("✅ ANÁLISE CONCLUÍDA!")
    print("="*80)
    print("\n📁 Arquivos gerados:")
    print("   • ../relatorios/relatorio_analise_scopus_wos.txt")
    print("   • ../referencias_filtradas/referencias_scopus_wos_filtradas.bib")
    print("\n")

if __name__ == '__main__':
    main()
