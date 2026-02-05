import re

with open(r'c:\Users\vidal\OneDrive\Documentos\13 - CLONEGIT\artigo_1_catuxe\8-REVISÃO_ESCOPO_SAT\latex\sn-article.tex', 'r', encoding='utf-8') as f:
    content = f.read()

# Extract text between \begin{document} and \end{document}
match = re.search(r'\\begin\{document\}(.*?)\\end\{document\}', content, re.DOTALL)
if match:
    text = match.group(1)
    
    # Remove comments
    text = re.sub(r'(?m)^%.*$', '', text)
    
    # Remove LaTeX commands with arguments
    text = re.sub(r'\\[a-zA-Z]+\*?\{[^{}]*\}', '', text)
    text = re.sub(r'\\[a-zA-Z]+\*?\[[^\]]*\]', '', text)
    
    # Remove remaining LaTeX commands
    text = re.sub(r'\\[a-zA-Z]+\*?', '', text)
    
    # Remove special characters and symbols
    text = re.sub(r'[\{\}\[\]$@&%]', '', text)
    
    # Clean up whitespace
    text = re.sub(r'\s+', ' ', text).strip()
    
    # Count words
    words = [w for w in text.split() if w.strip()]
    print(f'Total de palavras no texto principal: {len(words)}')
else:
    print('Arquivo não contém \\begin{document} e \\end{document}')
