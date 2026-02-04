param(
  [string]$TexFile = "sn-article.tex"
)

$ErrorActionPreference = 'Stop'

$latexDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $latexDir

if (-not (Test-Path -LiteralPath $TexFile)) {
  throw "Nao encontrei arquivo LaTeX: $TexFile"
}

$tex = Get-Content -LiteralPath $TexFile -Raw

# Remove comentarios (tudo apos % por linha)
$lines = Get-Content -LiteralPath $TexFile
$clean = ($lines | ForEach-Object { ($_ -replace '%.*$', '').TrimEnd() }) -join "`n"

# Captura caminhos em \includegraphics[...]{...}
$pattern = '\\includegraphics(?:\[[^\]]*\])?\{([^\}]+)\}'
$matches = [regex]::Matches($clean, $pattern)

$missing = @()
foreach ($m in $matches) {
  $rel = $m.Groups[1].Value.Trim()
  if (-not $rel) { continue }

  # Normaliza separadores
  $rel = $rel -replace '/', '\\'

  $full = Join-Path $latexDir $rel
  if (-not (Test-Path -LiteralPath $full)) {
    $missing += $rel
  }
}

if ($missing.Count -gt 0) {
  Write-Host "FALHA: figuras referenciadas e ausentes:" -ForegroundColor Red
  $missing | Sort-Object -Unique | ForEach-Object { Write-Host "- $_" }
  exit 1
}

Write-Host "OK, todas as figuras referenciadas existem." -ForegroundColor Green
exit 0
