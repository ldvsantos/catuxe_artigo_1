param(
    [string]$ProjectId = $env:OSF_PROJECT,
    [string]$RemotePath = "osfstorage/artifacts/artigo_1_catuxe_payload.zip",
    [string]$OutDir = "_release",
    [string[]]$Include = @(
        "8-REVISÃO_ESCOPO_SAT/latex",
        "8-REVISÃO_ESCOPO_SAT/2-DADOS/buscas",
        "8-REVISÃO_ESCOPO_SAT/2-DADOS/relatorios",
        "8-REVISÃO_ESCOPO_SAT/2-DADOS/referencias_filtradas",
        "8-REVISÃO_ESCOPO_SAT/2-DADOS/scripts",
        "8-REVISÃO_ESCOPO_SAT/3-REVIEW_GUIAS",
        "8-REVISÃO_ESCOPO_SAT/zenodo_release"
    )
)

$ErrorActionPreference = "Stop"

if (-not $env:OSF_TOKEN) {
    throw "Defina a variavel de ambiente OSF_TOKEN antes de executar."
}

if (-not $ProjectId) {
    throw "Informe o ProjectId por parametro ou defina OSF_PROJECT."
}

$osfExe = Join-Path $PSScriptRoot "..\.venv\Scripts\osf.exe"
$osfExe = (Resolve-Path $osfExe).Path

if (-not (Test-Path $osfExe)) {
    throw "Nao encontrei o executavel osf em $osfExe. Instale o pacote osfclient na venv."
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$zipPath = Join-Path $OutDir "osf_payload_$stamp.zip"

if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}

$paths = @()
foreach ($p in $Include) {
    if (Test-Path $p) {
        $paths += $p
    }
}

if ($paths.Count -eq 0) {
    throw "Nenhum caminho de entrada foi encontrado. Verifique o parametro Include."
}

Compress-Archive -Path $paths -DestinationPath $zipPath -Force

& $osfExe -p $ProjectId upload -U $zipPath $RemotePath

Write-Host "Upload concluido"
Write-Host "Arquivo local" $zipPath
Write-Host "Destino remoto" $RemotePath
