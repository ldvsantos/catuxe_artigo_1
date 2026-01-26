import re
from pathlib import Path

# Paths
root = Path(__file__).resolve().parents[3]
manus_dir = root / "1-MANUSCRITO"
bib_path = manus_dir / "referencias.bib"
input_md = manus_dir / "revisao_escopo_en.md"
output_md = manus_dir / "revisao_escopo_en.md"

if not bib_path.exists() or not input_md.exists():
    raise FileNotFoundError(
        "Arquivos esperados não encontrados. Ajuste os caminhos conforme o layout do projeto. "
        f"bib_path={bib_path} (exists={bib_path.exists()}); "
        f"input_md={input_md} (exists={input_md.exists()})"
    )

# Build mapping: (first_author_lower, year) -> citekey
entry_re = re.compile(r"@\w+\{([^,\s]+)")
author_re = re.compile(r"author\s*=\s*\{([^}]+)\}", re.IGNORECASE)
year_re = re.compile(r"year\s*=\s*\{([^}]+)\}", re.IGNORECASE)

mapping = {}
reverse_mapping = {}  # citekey -> (surname, year) for debugging
with bib_path.open(encoding="utf-8") as f:
    content = f.read()

# Split bib entries by @ symbol at start of line
entries = re.split(r'\n(?=@)', content)
for e in entries:
    if not e.strip():
        continue
    mkey = entry_re.search(e)
    if not mkey:
        continue
    key = mkey.group(1).strip()
    mauth = author_re.search(e)
    myear = year_re.search(e)
    if not mauth or not myear:
        continue
    year = myear.group(1).strip()
    # First author surname (last word of first author segment)
    first_author_segment = mauth.group(1).split(" and ")[0]
    # Remove braces and trim
    first_author_segment = re.sub(r"[{}]", "", first_author_segment).strip()
    # Try formats "Surname, Name" or "Name Surname"
    if "," in first_author_segment:
        surname = first_author_segment.split(",")[0].strip()
    else:
        parts = first_author_segment.split()
        surname = parts[-1].strip() if parts else first_author_segment.strip()
    
    # Clean surname (remove dots, etc)
    surname = re.sub(r'\s+', '', surname).lower()
    year_clean = year.strip()
    
    key_tuple = (surname, year_clean)
    # Store all variations
    if key_tuple not in mapping:
        mapping[key_tuple] = key
        reverse_mapping[key] = (surname, year_clean)

# Regex patterns for author-year citations like (Surname, 2018) or (Surname et al., 2018)
# Patterns for parenthetical citations, including multiple separated by ';' or ','
multi_parenthetical_re = re.compile(
    r"\((?P<cites>(?:[A-Z][A-Za-z'\-]+(?:\s+et\s+al\.)?|[A-Z][A-Za-z'\-]+)\s*,\s*\d{4}(?:\s*[;,]\s*(?:[A-Z][A-Za-z'\-]+(?:\s+et\s+al\.)?|[A-Z][A-Za-z'\-]+)\s*,\s*\d{4})*)\)"
)

# Pattern for single parenthetical citation
single_parenthetical_re = re.compile(
    r"\((?P<surname>[A-Z][A-Za-z'\-]+)(?:\s+et\s+al\.)?,\s*(?P<year>\d{4})\)"
)

# Pattern for narrative citation like Surname (2010)
narrative_re = re.compile(
    r"(?P<surname>[A-Z][A-Za-z'\-]+)(?:\s+et\s+al\.)?\s*\((?P<year>\d{4})\)"
)

text = input_md.read_text(encoding="utf-8")

print(f"Loaded {len(mapping)} unique author-year mappings from referencias.bib")

def replace_multi_parenthetical(m):
    segment = m.group("cites")
    parts = re.split(r"\s*[;,]\s*", segment)
    keys = []
    for part in parts:
        sm = re.match(r"(?P<surname>[A-Z][A-Za-z'\-]+)(?:\s+et\s+al\.)?\s*,\s*(?P<year>\d{4})", part)
        if not sm:
            continue
        surname = re.sub(r'\s+', '', sm.group("surname")).lower()
        year = sm.group("year")
        ck = mapping.get((surname, year))
        if ck:
            keys.append(f"@{ck}")
    if keys:
        return "[" + "; ".join(keys) + "]"
    return m.group(0)

def replace_single_parenthetical(m):
    surname = re.sub(r'\s+', '', m.group("surname")).lower()
    year = m.group("year")
    ck = mapping.get((surname, year))
    if ck:
        return f"[@{ck}]"
    return m.group(0)

def replace_narrative(m):
    surname = re.sub(r'\s+', '', m.group("surname")).lower()
    year = m.group("year")
    ck = mapping.get((surname, year))
    if ck:
        # Narrative citation without brackets
        return f"@{ck}"
    return m.group(0)

# Apply replacements: multi first, then single, then narrative
text = multi_parenthetical_re.sub(replace_multi_parenthetical, text)
text = single_parenthetical_re.sub(replace_single_parenthetical, text)
text = narrative_re.sub(replace_narrative, text)

# Ensure YAML lang is en-US
text = re.sub(r"(^lang:\s*)(.*)$", r"\1en-US", text, flags=re.MULTILINE)

# Ensure refs div at end
if "::: {#refs}" not in text:
    text = text.rstrip() + "\n\n::: {#refs}\n:::\n"

# Write synced copy and also update the original adjusted file
output_md.write_text(text, encoding="utf-8")
print("Citations mapped. Output:", output_md)
