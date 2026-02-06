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
    [Parameter(Mandatory = $true)][scriptblock]$Command,
    [Parameter(Mandatory = $false)][string]$OutputPath
  )

  Write-Host "\n==> $Label" -ForegroundColor Cyan
  & $Command
  if ($LASTEXITCODE -ne 0) {
    # Em alguns ambientes (por exemplo, execução via ferramentas/CI), logs muito verbosos
    # podem levar à interrupção do processo. Em caso de falha, imprimimos apenas o final
    # do .log para diagnóstico rápido.
    try {
      $latexDir = Split-Path -Parent $MyInvocation.MyCommand.Path
      $logPath = Join-Path $latexDir 'sn-article_revised.log'
      if (Test-Path -LiteralPath $logPath) {
        Write-Host "\n==> Trecho final do log (sn-article_revised.log)" -ForegroundColor Yellow
        Get-Content -LiteralPath $logPath -Tail 80
      }

      $blgPath = Join-Path $latexDir 'sn-article_revised.blg'
      if (Test-Path -LiteralPath $blgPath) {
        Write-Host "\n==> Trecho final do BibTeX log (sn-article_revised.blg)" -ForegroundColor Yellow
        Get-Content -LiteralPath $blgPath -Tail 80
      }

      if ($OutputPath -and (Test-Path -LiteralPath $OutputPath)) {
        Write-Host "\n==> Trecho final da saida capturada ($([IO.Path]::GetFileName($OutputPath)))" -ForegroundColor Yellow
        Get-Content -LiteralPath $OutputPath -Tail 120
      }
    } catch {
      # ignore
    }
    throw "Falhou: $Label (exit code=$LASTEXITCODE)"
  }
}

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $toolsDir

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

$latexDir = Find-LatexDir -RootDir $rootDir

$buildLogDir = Join-Path $latexDir '_build_logs'
New-Item -ItemType Directory -Force -Path $buildLogDir | Out-Null

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
  $outPath = Join-Path $buildLogDir 'check_figures.txt'
  powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $toolsDir 'check_figures.ps1') -LatexDir $latexDir -TexFile 'sn-article.tex' *> $outPath
} -OutputPath (Join-Path $buildLogDir 'check_figures.txt')

# 3) Compilar LaTeX (com jobname para evitar lock do PDF)
Invoke-Checked -Label 'pdflatex (passo 1)' -Command {
  Set-Location $latexDir
  $outPath = Join-Path $buildLogDir 'pdflatex_pass1.txt'
  pdflatex -shell-escape -interaction=batchmode -halt-on-error -file-line-error -jobname=sn-article_revised sn-article.tex *> $outPath
} -OutputPath (Join-Path $buildLogDir 'pdflatex_pass1.txt')

Invoke-Checked -Label 'bibtex' -Command {
  Set-Location $latexDir
  $outPath = Join-Path $buildLogDir 'bibtex.txt'
  bibtex sn-article_revised *> $outPath
} -OutputPath (Join-Path $buildLogDir 'bibtex.txt')

Invoke-Checked -Label 'pdflatex (passo 2)' -Command {
  Set-Location $latexDir
  $outPath = Join-Path $buildLogDir 'pdflatex_pass2.txt'
  pdflatex -shell-escape -interaction=batchmode -halt-on-error -file-line-error -jobname=sn-article_revised sn-article.tex *> $outPath
} -OutputPath (Join-Path $buildLogDir 'pdflatex_pass2.txt')

Invoke-Checked -Label 'pdflatex (passo 3)' -Command {
  Set-Location $latexDir
  $outPath = Join-Path $buildLogDir 'pdflatex_pass3.txt'
  pdflatex -shell-escape -interaction=batchmode -halt-on-error -file-line-error -jobname=sn-article_revised sn-article.tex *> $outPath
} -OutputPath (Join-Path $buildLogDir 'pdflatex_pass3.txt')

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

Invoke-Checked -Label 'Sincronizando PDF principal (sn-article.pdf)' -Command {
  Set-Location $latexDir
  $from = Join-Path $latexDir 'sn-article_revised.pdf'
  $to = Join-Path $latexDir 'sn-article.pdf'
  if (-not (Test-Path -LiteralPath $from)) {
    throw "Nao encontrei o PDF gerado: $from"
  }
  Copy-Item -LiteralPath $from -Destination $to -Force
}

Write-Host "\nOK: pipeline concluido. PDFs gerados: $latexDir\sn-article.pdf (principal) e $latexDir\sn-article_revised.pdf" -ForegroundColor Green

if ($oldCodePage) {
  try { chcp $oldCodePage | Out-Null } catch { }
}
