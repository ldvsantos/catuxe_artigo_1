$ErrorActionPreference = 'Stop'

# Ajuste de codepage: o output de ferramentas como pdflatex/bibtex costuma ser 8-bit.
# Em muitos terminais Windows, forcar UTF-8 (65001) faz aparecer "texto quebrado" (�).
# Aqui, trocamos para Windows-1252 durante a execucao e restauramos no final.
$oldCodePage = $null
try {
  $cpLine = (chcp)
  if ($cpLine -match '(\d+)') {
    $oldCodePage = $Matches[1]
  }
  chcp 1252 | Out-Null
} catch {
  # ignore
}

function Invoke-Checked {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][scriptblock]$Command
  )

  Write-Host "\n==> $Label" -ForegroundColor Cyan
  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "Falhou: $Label (exit code=$LASTEXITCODE)"
  }
}

$latexDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $latexDir

if (-not (Test-Path -LiteralPath (Join-Path $latexDir 'sn-article.tex'))) {
  throw "Nao encontrei sn-article.tex em: $latexDir"
}

# Limpeza defensiva: evita falhas do tipo "Runaway argument"/arquivos auxiliares corrompidos
# e problemas de lock/rename (ex.: SyncTeX) quando o PDF esta aberto no preview.
Invoke-Checked -Label 'Limpando artefatos antigos' -Command {
  Set-Location $latexDir
  $paths = @(
    'sn-article_revised.aux',
    'sn-article_revised.bbl',
    'sn-article_revised.blg',
    'sn-article_revised.log',
    'sn-article_revised.out',
    'sn-article_revised.toc',
    'sn-article_revised.lof',
    'sn-article_revised.lot',
    'sn-article_revised.synctex',
    'sn-article_revised.synctex.gz'
  )
  foreach ($p in $paths) {
    Remove-Item -LiteralPath (Join-Path $latexDir $p) -Force -ErrorAction SilentlyContinue
  }
}

# 1) Cache local de PNGs (evita falhas de leitura intermitentes em caminhos externos/OneDrive)
Invoke-Checked -Label 'Preparando cache local de figuras (PNG)' -Command {
  Set-Location $latexDir

  $cacheDir = Join-Path $latexDir '_fig_cache'
  New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null

  $pairs = @(
    @{ From = Join-Path $latexDir '..\2-FIGURAS\2-EN\network_completa.png';    To = Join-Path $cacheDir 'network_completa.png' },
    @{ From = Join-Path $latexDir '..\2-FIGURAS\2-EN\network_communities.png'; To = Join-Path $cacheDir 'network_communities.png' },
    @{ From = Join-Path $latexDir '..\2-FIGURAS\2-EN\network_algoritmo_produto.png'; To = Join-Path $cacheDir 'network_algoritmo_produto.png' },
    @{ From = Join-Path $latexDir '..\2-FIGURAS\2-EN\network_centrality_metrics.png'; To = Join-Path $cacheDir 'network_centrality_metrics.png' }
  )

  foreach ($p in $pairs) {
    if (-not (Test-Path -LiteralPath $p.From)) {
      throw "Figura não encontrada para cache: $($p.From)"
    }
    Copy-Item -LiteralPath $p.From -Destination $p.To -Force
  }
}

# 2) Checar se todas as imagens do LaTeX existem (sem gerar/atualizar figuras)
Invoke-Checked -Label 'Checando figuras referenciadas no LaTeX' -Command {
  Set-Location $latexDir
  powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $latexDir 'check_figures.ps1')
}

# 3) Compilar LaTeX (com jobname para evitar lock do PDF)
Invoke-Checked -Label 'pdflatex (passo 1)' -Command {
  Set-Location $latexDir
  pdflatex -interaction=nonstopmode -jobname=sn-article_revised sn-article.tex
}

Invoke-Checked -Label 'bibtex' -Command {
  Set-Location $latexDir
  bibtex sn-article_revised
}

Invoke-Checked -Label 'pdflatex (passo 2)' -Command {
  Set-Location $latexDir
  pdflatex -interaction=nonstopmode -jobname=sn-article_revised sn-article.tex
}

Invoke-Checked -Label 'pdflatex (passo 3)' -Command {
  Set-Location $latexDir
  pdflatex -interaction=nonstopmode -jobname=sn-article_revised sn-article.tex
}

Invoke-Checked -Label 'Sincronizando auxiliares para VS Code (LaTeX Workshop)' -Command {
  Set-Location $latexDir

  $pairs = @(
    @{ From = 'sn-article_revised.aux';       To = 'sn-article.aux' },
    @{ From = 'sn-article_revised.bbl';       To = 'sn-article.bbl' },
    @{ From = 'sn-article_revised.blg';       To = 'sn-article.blg' },
    @{ From = 'sn-article_revised.out';       To = 'sn-article.out' },
    @{ From = 'sn-article_revised.log';       To = 'sn-article.log' },
    @{ From = 'sn-article_revised.synctex.gz'; To = 'sn-article.synctex.gz' }
  )

  foreach ($p in $pairs) {
    if (Test-Path -LiteralPath (Join-Path $latexDir $p.From)) {
      Copy-Item -LiteralPath (Join-Path $latexDir $p.From) -Destination (Join-Path $latexDir $p.To) -Force
    }
  }
}

Write-Host "\nOK: pipeline concluido. PDF gerado: $latexDir\sn-article_revised.pdf" -ForegroundColor Green

if ($oldCodePage) {
  try { chcp $oldCodePage | Out-Null } catch { }
}
