param(
  [string]$TexFile = "sn-article.tex",
  [string]$LatexDir = $null
)

$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $toolsDir

if (-not $LatexDir) {
  $hit = Get-ChildItem -LiteralPath $rootDir -Recurse -File -Filter 'sn-article.tex' -ErrorAction SilentlyContinue |
    Select-Object -First 1
  if (-not $hit) {
    throw "Nao encontrei sn-article.tex abaixo de: $rootDir"
  }
  $LatexDir = $hit.Directory.FullName
}

if (-not (Test-Path -LiteralPath $LatexDir)) {
  throw "Nao encontrei LatexDir: $LatexDir"
}

Set-Location $LatexDir

$texPath = $TexFile
if (-not [IO.Path]::IsPathRooted($texPath)) {
  $texPath = Join-Path $LatexDir $TexFile
}

if (-not (Test-Path -LiteralPath $texPath)) {
  throw "Nao encontrei arquivo LaTeX: $texPath"
}

$tex = Get-Content -LiteralPath $texPath -Raw

# Remove comentarios (tudo apos % por linha)
$lines = Get-Content -LiteralPath $texPath
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

  $full = Join-Path $LatexDir $rel
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
