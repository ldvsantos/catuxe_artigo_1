import re
import os

# Caminhos
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# O arquivo bib está em ../referencias_filtradas/relative to scripts
BIB_FILE = os.path.join(BASE_DIR, '..', 'referencias_filtradas', 'referencias_scopus_wos_filtradas.bib')
# O output vai para ../../latex/
OUTPUT_MD = os.path.join(BASE_DIR, '..', '..', 'latex', '3-analise_excelencia.md')

SCORE_THRESHOLD = 12.0

def parse_bib_line_by_line(file_path):
    entries = []
    current_entry = None
    
    print(f"Lendo: {file_path}")
    
    if not os.path.exists(file_path):
        print(f"Erro: Arquivo não encontrado: {file_path}")
        return []

    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    for line in lines:
        line = line.strip()
        if line.startswith('@'):
            # Se já tinha um registro aberto, fecha
            if current_entry:
                entries.append(current_entry)
            
            # Começar novo
            parts = line.split('{', 1)
            if len(parts) > 1:
                key_part = parts[1].rstrip(',')
                current_entry = {'id': key_part}
            else:
                current_entry = {} 
                
        elif current_entry is not None:
            if line == '}':
                # Fim do registro
                entries.append(current_entry)
                current_entry = None
            else:
                # Parser simples linha a linha: campo = {valor},
                # Identifica campo={valor}
                match = re.match(r'([a-zA-Z0-9_]+)\s*=\s*{(.*)}', line)
                if match:
                    field = match.group(1).lower()
                    value = match.group(2)
                    
                    # Limpeza final (se tiver vírgula no final da chave, etc)
                    if value.endswith(','):
                        value = value[:-1]
                    
                    # Parse especial do note para score
                    if field == 'note':
                        # note = {Fonte: Scopus, Score: 15.0}
                        score_match = re.search(r'Score:\s*([\d\.]+)', value)
                        if score_match:
                            try:
                                current_entry['score'] = float(score_match.group(1))
                            except:
                                current_entry['score'] = 0.0
                        
                        fonte_match = re.search(r'Fonte:\s*([^,]+)', value)
                        if fonte_match:
                            current_entry['fonte'] = fonte_match.group(1).strip()
                    else:
                        current_entry[field] = value
    
    # Adicionar o último
    if current_entry:
        entries.append(current_entry)
        
    return entries

def generate_report(entries):
    # Filtrar Excelência
    excellence = [e for e in entries if e.get('score', 0) >= SCORE_THRESHOLD]
    
    # Ordenar por Score (desc) depois Ano (desc)
    excellence.sort(key=lambda x: (x.get('score', 0), x.get('year', '0000')), reverse=True)
    
    print(f"Encontrados {len(excellence)} artigos de excelência.")
    
    with open(OUTPUT_MD, 'w', encoding='utf-8') as f:
        f.write("# Análise Detalhada dos Artigos de Excelência\n\n")
        f.write(f"**Total de Artigos Selecionados:** {len(excellence)}\n")
        f.write(f"**Critério de Inclusão:** Score de Relevância >= {SCORE_THRESHOLD}\n\n")
        
        f.write("Esta seção detalha os estudos que apresentaram maior aderência aos temas investigados (Interseção entre Machine Learning e Sistemas Agrícolas Tradicionais), totalizando " + str(len(excellence)) + " artigos.\n\n")
        
        f.write("## Lista de Artigos\n\n")
        
        for i, article in enumerate(excellence, 1):
            title = article.get('title', 'Sem Título')
            authors = article.get('author', 'Sem Autor')
            year = article.get('year', 'N/A')
            journal = article.get('journal', article.get('booktitle', 'N/A'))
            score = article.get('score', 0)
            fonte = article.get('fonte', 'Desconhecido')
            doi = article.get('doi', '')
            
            kw = article.get('keywords', article.get('author_keywords', ''))
            
            f.write(f"### {i}. {title}\n\n")
            f.write(f"- **Ano:** {year}\n")
            f.write(f"- **Revista:** {journal}\n")
            f.write(f"- **Autores:** {authors}\n")
            f.write(f"- **Score:** {score} ({fonte})\n")
            if doi:
                f.write(f"- **DOI:** [{doi}](https://doi.org/{doi})\n")
            
            if kw:
                f.write(f"\n**Palavras-chave:** {kw}\n")
            
            # Abstract
            abstract = article.get('abstract', '')
            if abstract:
                f.write(f"\n> **Resumo:** {abstract}\n")
            
            f.write("\n---\n\n")
            
    print(f"Relatório gerado em: {OUTPUT_MD}")

if __name__ == "__main__":
    entries = parse_bib_line_by_line(BIB_FILE)
    generate_report(entries)
