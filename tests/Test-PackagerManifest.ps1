$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $PSScriptRoot "ReleaseFiles.ps1")

$expectedFiles = @(Get-LootPathwayReleaseFiles | ForEach-Object { $_ -replace '\\', '/' } | Sort-Object)
$pkgmetaPath = Join-Path $projectRoot ".pkgmeta"
$pkgmeta = Get-Content -LiteralPath $pkgmetaPath
$ignoreEntries = [System.Collections.Generic.List[string]]::new()
$readingIgnore = $false

foreach ($line in $pkgmeta) {
    if ($line -match '^ignore:\s*$') {
        $readingIgnore = $true
        continue
    }
    if ($readingIgnore -and $line -match '^\S') { break }
    if ($readingIgnore -and $line -match '^\s+-\s+(.+?)\s*$') {
        $ignoreEntries.Add(($matches[1].Trim() -replace '\\', '/').TrimEnd('/'))
    }
}

if ($ignoreEntries.Count -eq 0) { throw ".pkgmeta contains no ignore manifest." }

Push-Location $projectRoot
try {
    $trackedFiles = @(git ls-files)
    if ($LASTEXITCODE -ne 0) { throw "Could not read the Git tracked-file manifest." }
}
finally {
    Pop-Location
}

$packagerFiles = @($trackedFiles | Where-Object {
    $path = $_ -replace '\\', '/'
    if ($path -match '(^|/)\.[^/]+') { return $false }
    foreach ($ignored in $ignoreEntries) {
        if ($path -eq $ignored -or $path.StartsWith($ignored + '/', [System.StringComparison]::Ordinal)) {
            return $false
        }
    }
    return $true
} | Sort-Object)

$difference = @(Compare-Object -ReferenceObject $expectedFiles -DifferenceObject $packagerFiles)
if ($difference.Count -gt 0) {
    throw "CurseForge's .pkgmeta selection differs from the approved GitHub ZIP manifest:`n$($difference | Out-String)"
}

Write-Output "Packager parity valid: GitHub and CurseForge select the same $($expectedFiles.Count) tagged files."
