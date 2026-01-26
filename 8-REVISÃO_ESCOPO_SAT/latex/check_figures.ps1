$ErrorActionPreference = 'Stop'

$latexDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$texPath = Join-Path $latexDir 'sn-article.tex'

if (-not (Test-Path -LiteralPath $texPath)) {
  throw "sn-article.tex não encontrado em: $latexDir"
}

$tex = Get-Content -LiteralPath $texPath -Raw

# Captura caminhos em \includegraphics[...] {path}
$pattern = '(?s)\\includegraphics\s*(\[[^\]]*\])?\s*\{([^}]+)\}'
$matches = [regex]::Matches($tex, $pattern)

$paths = @()
foreach ($m in $matches) {
  $p = $m.Groups[2].Value.Trim()
  if ($p) { $paths += $p }
}

$paths = $paths | Select-Object -Unique

$missing = New-Object System.Collections.Generic.List[string]
foreach ($p in $paths) {
  # Resolve relativo ao diretório do LaTeX
  $candidate = Join-Path $latexDir $p
  if (-not (Test-Path -LiteralPath $candidate)) {
    $missing.Add($p)
  }
}

if ($missing.Count -gt 0) {
  Write-Host "Figuras ausentes referenciadas em sn-article.tex" -ForegroundColor Red
  foreach ($p in $missing) {
    Write-Host "- $p" -ForegroundColor Red
  }
  exit 1
}

Write-Host "OK, todas as figuras referenciadas existem." -ForegroundColor Green
exit 0
