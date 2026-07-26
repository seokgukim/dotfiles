[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$InputPath,

    [Parameter(Position = 1)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $InputPath -PathType Leaf)) {
    throw "Markdown file not found: $InputPath"
}

$inputFile = Get-Item -LiteralPath $InputPath
if ($inputFile.Extension -notin '.md', '.markdown') {
    throw "Input must have a .md or .markdown extension: $InputPath"
}

$generatedPath = [IO.Path]::ChangeExtension($inputFile.FullName, '.pdf')
if ($OutputPath) {
    $outputFullPath = [IO.Path]::GetFullPath($OutputPath)
    if ([IO.Path]::GetExtension($outputFullPath) -ne '.pdf') {
        throw "Output must have a .pdf extension: $OutputPath"
    }

    $outputDirectory = [IO.Path]::GetDirectoryName($outputFullPath)
    [IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
} else {
    $outputFullPath = $generatedPath
}

$pdfOptions = '{"format":"A4","margin":"20mm","printBackground":true}'
$converter = Get-Command md-to-pdf -ErrorAction SilentlyContinue
if ($converter) {
    & $converter.Source $inputFile.FullName --basedir $inputFile.DirectoryName --pdf-options $pdfOptions
} else {
    $npx = Get-Command npx -ErrorAction SilentlyContinue
    if (-not $npx) {
        throw 'md-to-pdf or npx is required. Install Node.js and npm first.'
    }

    & $npx.Source --yes 'md-to-pdf@5.2.5' $inputFile.FullName --basedir $inputFile.DirectoryName --pdf-options $pdfOptions
}

if ($LASTEXITCODE -ne 0) {
    throw "PDF conversion failed with exit code $LASTEXITCODE."
}

if ($outputFullPath -ne $generatedPath) {
    Move-Item -LiteralPath $generatedPath -Destination $outputFullPath -Force
}

Write-Output "Created $outputFullPath"
