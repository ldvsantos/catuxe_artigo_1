param(
  [switch]$DryRun,
  [switch]$RemovePdf,
  [switch]$RemoveBbl
)

$ErrorActionPreference = 'Stop'

function Find-LatexDir {
  param(
    [Parameter(Mandatory = $true)][string]$RootDir
  )

  $hit = Get-ChildItem -LiteralPath $RootDir -Recurse -File -Filter 'sn-article.tex' -ErrorAction SilentlyContinue |
    Select-Object -First 1

  if (-not $hit) {
    throw "Nao encontrei sn-article.tex abaixo de: $RootDir"
  }
  return $hit.Directory.FullName
}

function Remove-PathSafe {
  param(
    [Parameter(Mandatory = $true)][string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return
  }

  if ($DryRun) {
    Write-Host "[DryRun] Removeria: $Path" -ForegroundColor Yellow
    return
  }

  Remove-Item -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue
  Write-Host "Removido: $Path" -ForegroundColor Green
}

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $toolsDir
$latexDir = Find-LatexDir -RootDir $rootDir

Write-Host "Limpando artefatos LaTeX em: $latexDir" -ForegroundColor Cyan

$exts = @('.aux', '.blg', '.log', '.out', '.toc', '.lof', '.lot', '.synctex', '.synctex.gz', '.fls', '.fdb_latexmk', '.bcf', '.run.xml')
if ($RemoveBbl) {
  $exts += '.bbl'
}
if ($RemovePdf) {
  $exts += '.pdf'
}

Get-ChildItem -LiteralPath $latexDir -File -ErrorAction SilentlyContinue |
  Where-Object {
    $name = $_.Name
    ($name -like 'sn-article*') -and ($exts -contains $_.Extension)
  } |
  ForEach-Object {
    Remove-PathSafe -Path $_.FullName
  }

$dirs = @('_build_logs', '_fig_cache', '_minted')
foreach ($d in $dirs) {
  Remove-PathSafe -Path (Join-Path $latexDir $d)
}

Get-ChildItem -LiteralPath $latexDir -File -Filter '*.data.minted' -ErrorAction SilentlyContinue |
  ForEach-Object {
    Remove-PathSafe -Path $_.FullName
  }

Write-Host 'OK' -ForegroundColor Green
