<#
.SYNOPSIS
    Export every Mermaid .mmd diagram to a .png.

.DESCRIPTION
    Renders each *.mmd file in the source directory to a PNG in the output
    directory using mermaid-cli (mmdc), invoked via npx. Requires Node.js.
    The mermaid-cli package (and a headless Chromium) is fetched by npx on
    first run.

.EXAMPLE
    pwsh scripts/export-mermaid.ps1

.EXAMPLE
    pwsh scripts/export-mermaid.ps1 -Scale 3 -Background transparent
#>
[CmdletBinding()]
param(
    [string]$SourceDir  = (Join-Path $PSScriptRoot '..' 'docs' 'mermaid-diagrams'),
    [string]$OutputDir  = (Join-Path $PSScriptRoot '..' 'docs' 'images'),
    [int]$Scale         = 2,
    [string]$Background  = 'white'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw 'npx (Node.js) was not found on PATH. Install Node.js and retry.'
}

$SourceDir = (Resolve-Path $SourceDir).Path
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
$OutputDir = (Resolve-Path $OutputDir).Path

$diagrams = Get-ChildItem -Path $SourceDir -Filter '*.mmd' -File
if ($diagrams.Count -eq 0) {
    Write-Warning "No .mmd files found in $SourceDir"
    return
}

Write-Host "Exporting $($diagrams.Count) diagram(s) from $SourceDir -> $OutputDir"

foreach ($diagram in $diagrams) {
    $outFile = Join-Path $OutputDir ($diagram.BaseName + '.png')
    Write-Host "  $($diagram.Name) -> $(Split-Path $outFile -Leaf)"

    & npx -y '@mermaid-js/mermaid-cli' -i $diagram.FullName -o $outFile -b $Background -s $Scale
    if ($LASTEXITCODE -ne 0) {
        throw "mermaid-cli failed on $($diagram.Name) (exit $LASTEXITCODE)"
    }
}

Write-Host 'Done.'
