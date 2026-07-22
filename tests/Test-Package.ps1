param(
    [Parameter(Mandatory = $true)]
    [string]$ZipPath,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$ExpectedVersion
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$resolvedZip = (Resolve-Path -LiteralPath $ZipPath).Path
. (Join-Path $PSScriptRoot "ReleaseFiles.ps1")
$expectedFiles = @(Get-LootPathwayReleaseFiles | Sort-Object)

$verificationRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("LootPathway-Package-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $verificationRoot | Out-Null

try {
    Expand-Archive -LiteralPath $resolvedZip -DestinationPath $verificationRoot
    $addonRoot = Join-Path $verificationRoot "LootPathway"
    if (-not (Test-Path -LiteralPath $addonRoot -PathType Container)) {
        throw "Package does not contain the required LootPathway root folder."
    }

    $topLevel = @(Get-ChildItem -LiteralPath $verificationRoot -Force)
    if ($topLevel.Count -ne 1 -or $topLevel[0].Name -ne "LootPathway" -or -not $topLevel[0].PSIsContainer) {
        throw "Package must contain exactly one top-level LootPathway folder."
    }

    $actualFiles = @(Get-ChildItem -LiteralPath $addonRoot -File -Recurse | ForEach-Object {
        $_.FullName.Substring($addonRoot.Length + 1)
    } | Sort-Object)
    $difference = @(Compare-Object -ReferenceObject $expectedFiles -DifferenceObject $actualFiles)
    if ($difference.Count -gt 0) {
        throw "Package file list differs from the approved runtime manifest:`n$($difference | Out-String)"
    }

    foreach ($relativePath in $expectedFiles) {
        $sourcePath = Join-Path $projectRoot $relativePath
        $packagedPath = Join-Path $addonRoot $relativePath
        $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
        $packagedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $packagedPath).Hash
        if ($sourceHash -ne $packagedHash) {
            throw "Packaged file '$relativePath' is not byte-identical to the tested source."
        }
    }

    $toc = Get-Content -LiteralPath (Join-Path $addonRoot "LootPathway_TBC.toc") -Raw
    if ($toc -notmatch "(?m)^## Version:\s*$([regex]::Escape($ExpectedVersion))\s*$") {
        throw "Packaged TOC version does not match expected version $ExpectedVersion."
    }
}
finally {
    if (Test-Path -LiteralPath $verificationRoot) {
        Remove-Item -LiteralPath $verificationRoot -Recurse -Force
    }
}

Write-Output "Package valid: one LootPathway root, $($expectedFiles.Count) approved files, version $ExpectedVersion, byte-identical sources."
