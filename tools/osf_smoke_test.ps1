param(
    [string]$ProjectId = $env:OSF_PROJECT
)

$ErrorActionPreference = "Stop"

if (-not $env:OSF_TOKEN) {
    throw "Defina a variavel de ambiente OSF_TOKEN."
}

if (-not $ProjectId) {
    throw "Informe o ProjectId por parametro ou defina OSF_PROJECT."
}

$osfExe = Join-Path $PSScriptRoot "..\.venv\Scripts\osf.exe"
$osfExe = (Resolve-Path $osfExe).Path

& $osfExe -p $ProjectId list
