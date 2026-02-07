#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Citation Validator - Extracts and validates all citations from LaTeX document
against bibliography file and generates comprehensive validation report.
"""

import re
import os
from collections import defaultdict

# Define file paths
latex_file = r"c:\Users\vidal\OneDrive\Documentos\13 - CLONEGIT\artigo_1_catuxe\8-REVISÃO_ESCOPO_SAT\latex\sn-article.tex"
bib_file = r"c:\Users\vidal\OneDrive\Documentos\13 - CLONEGIT\artigo_1_catuxe\8-REVISÃO_ESCOPO_SAT\latex\referencias.bib"

def extract_citations_from_latex(file_path):
    """Extract all citation keys from LaTeX document"""
    citations = defaultdict(set)
    
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading LaTeX file: {e}")
        return citations
    
    # Find all citation commands
    # Pattern: \cite{KEY} or \citep{KEY} or \citet{KEY}
    # Handle multiple citations: \cite{KEY1,KEY2,KEY3}
    pattern = r'\\cite[ptn]?\{([^}]+)\}'
    
    matches = re.finditer(pattern, content)
    for match in matches:
        citation_cmd = match.group(0)
        # Extract citation type
        if '\\citet{' in citation_cmd:
            cit_type = 'citet'
        elif '\\citep{' in citation_cmd:
            cit_type = 'citep'
        else:
            cit_type = 'cite'
        
        # Extract individual citation keys
        keys_str = match.group(1)
        keys = [k.strip() for k in keys_str.split(',')]
        
        for key in keys:
            if key:
                citations[key].add(cit_type)
    
    return citations

def parse_bibtex(file_path):
    """Parse BibTeX file and extract all entries"""
    entries = {}
    
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading BibTeX file: {e}")
        return entries
    
    # Find all bibtex entries
    # Pattern: @ENTRYTYPE{KEY, ... }
    pattern = r'@\w+\{([^,\n]+),'
    
    matches = re.finditer(pattern, content, re.IGNORECASE)
    for match in matches:
        entry_key = match.group(1).strip()
        entries[entry_key] = True
    
    # Extract additional metadata for each entry
    for key in entries.keys():
        # Find year
        year_pattern = key + r'[^@]*year\s*=\s*\{*(\d{4})\}*'
        year_match = re.search(year_pattern, content, re.IGNORECASE | re.DOTALL)
        if year_match:
            entries[key] = {'year': year_match.group(1)}
        else:
            entries[key] = {'year': 'N/A'}
        
        # Find DOI
        doi_pattern = key + r'[^@]*doi\s*=\s*\{*([^},\n]+)\}*'
        doi_match = re.search(doi_pattern, content, re.IGNORECASE | re.DOTALL)
        if doi_match:
            doi_value = doi_match.group(1).strip()
            entries[key]['doi'] = doi_value
        else:
            entries[key]['doi'] = 'N/A'
    
    return entries

def validate_citations(citations, bib_entries):
    """Validate citations against bibliography"""
    validation_report = []
    
    for citation_key in sorted(citations.keys()):
        citation_types = ','.join(sorted(citations[citation_key]))
        exists_in_bib = citation_key in bib_entries
        
        if exists_in_bib:
            bib_entry = bib_entries[citation_key]
            year = bib_entry.get('year', 'N/A')
            doi = bib_entry.get('doi', 'N/A')
            
            # Validate year consistency with citation key
            year_match = "✓" if year != 'N/A' else "?"
            
            # Validate DOI format
            doi_valid = "✓" if (doi != 'N/A' and doi.startswith('10.')) else "✗"
            
            issues = []
            if year == 'N/A':
                issues.append("Missing year")
            if doi == 'N/A':
                issues.append("No DOI")
            if "Ã" in str(bib_entry):
                issues.append("Encoding error")
            
            status = "✓ FOUND"
            issues_str = "; ".join(issues) if issues else "None"
        else:
            status = "✗ MISSING"
            year = "MISSING"
            doi = "MISSING"
            year_match = "✗"
            doi_valid = "✗"
            issues_str = "Bibliography entry not found"
        
        validation_report.append({
            'key': citation_key,
            'type': citation_types,
            'status': status,
            'year': year,
            'doi': doi,
            'year_match': year_match,
            'doi_valid': doi_valid,
            'issues': issues_str
        })
    
    return validation_report

def generate_markdown_report(validation_report, total_citations):
    """Generate comprehensive markdown validation report"""
    
    # Count statistics
    found = sum(1 for r in validation_report if r['status'] == '✓ FOUND')
    missing = sum(1 for r in validation_report if r['status'] == '✗ MISSING')
    with_doi = sum(1 for r in validation_report if r['doi_valid'] == '✓')
    
    # Header
    markdown = f"""# Citation Validation Report

**Document:** sn-article.tex  
**Bibliography:** referencias.bib  
**Generated:** Citation Analysis Report

## Summary Statistics

- **Total Unique Citations Found:** {len(validation_report)}
- **Total Citation Instances:** {total_citations}
- **Citations Found in Bibliography:** {found} ({100*found/len(validation_report):.1f}%)
- **Citations Missing from Bibliography:** {missing} ({100*missing/len(validation_report):.1f}%)
- **Citations with Valid DOI:** {with_doi}
- **Encoding Issues Detected:** {sum(1 for r in validation_report if 'Encoding' in r['issues'])}

---

## Citation Validation Table

| Citation Key | Type | Status | Year | DOI | Year Match | DOI Valid | Issues |
|---|---|---|---|---|---|---|---|
"""
    
    for row in validation_report:
        markdown += f"| {row['key']} | {row['type']} | {row['status']} | {row['year']} | {row['doi']} | {row['year_match']} | {row['doi_valid']} | {row['issues']} |\n"
    
    # Missing citations section
    missing_cits = [r for r in validation_report if r['status'] == '✗ MISSING']
    if missing_cits:
        markdown += f"\n## Missing Citations ({len(missing_cits)})\n\n"
        markdown += "**These citations are used in the document but not found in referencias.bib:**\n\n"
        for cit in missing_cits:
            markdown += f"- `{cit['key']}` (used as: {cit['type']})\n"
    
    # Issues summary
    encoding_issues = [r['key'] for r in validation_report if 'Encoding' in r['issues']]
    if encoding_issues:
        markdown += f"\n## Encoding Issues ({len(encoding_issues)})\n\n"
        markdown += "**Bibliography entries with UTF-8 encoding corruption:**\n\n"
        for key in encoding_issues:
            markdown += f"- `{key}`\n"
    
    # Recommendations
    markdown += """
## Recommendations

1. **Add Missing Citations:** The following citation keys are used in the document but not found in the bibliography:
   - Verify these citations and add them to referencias.bib
   - Check for alternative naming conventions or typos

2. **Add DOI Information:** Include DOI for citations currently missing this information
   - This improves traceability and citation management

3. **Fix Encoding Issues:** Repair UTF-8 encoding corruption in bibliography entries
   - Use proper character encoding when editing .bib file
   - Test with BibTeX/LuaTeX parsers after editing

4. **Complete Missing Fields:** Ensure all bibliography entries have:
   - Author/Author names
   - Year of publication
   - DOI (when available)
   - Journal/Publisher information

---

**Report Generated:** Document citation analysis complete
"""
    
    return markdown

def main():
    """Main execution function"""
    print("=" * 60)
    print("Citation Validator - LaTeX Document Analysis")
    print("=" * 60)
    
    # Extract citations from LaTeX
    print("\n1. Extracting citations from LaTeX document...")
    citations = extract_citations_from_latex(latex_file)
    total_citation_instances = sum(len(v) for v in citations.values())
    print(f"   Found {len(citations)} unique citations ({total_citation_instances} instances)")
    
    # Parse bibliography
    print("\n2. Parsing bibliography file...")
    bib_entries = parse_bibtex(bib_file)
    print(f"   Found {len(bib_entries)} bibliography entries")
    
    # Validate
    print("\n3. Validating citations...")
    validation_report = validate_citations(citations, bib_entries)
    
    # Generate report
    print("\n4. Generating markdown report...")
    markdown_report = generate_markdown_report(validation_report, total_citation_instances)
    
    # Save report
    report_path = r"c:\Users\vidal\OneDrive\Documentos\13 - CLONEGIT\artigo_1_catuxe\CITATION_VALIDATION_REPORT.md"
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(markdown_report)
    
    print(f"\n✓ Report saved to: {report_path}")
    
    # Print summary
    found = sum(1 for r in validation_report if r['status'] == '✓ FOUND')
    missing = sum(1 for r in validation_report if r['status'] == '✗ MISSING')
    
    print("\n" + "=" * 60)
    print("VALIDATION SUMMARY")
    print("=" * 60)
    print(f"Total Citations: {len(validation_report)}")
    print(f"Found in Bibliography: {found}")
    print(f"Missing from Bibliography: {missing}")
    print("=" * 60)
    
    return validation_report

if __name__ == '__main__':
    main()
