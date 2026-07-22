$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$releaseRoot = Join-Path $projectRoot "release"
$addonRoot = Join-Path $releaseRoot "LootPathway"
$tocPath = Join-Path $projectRoot "LootPathway_TBC.toc"
$tocText = Get-Content -LiteralPath $tocPath -Raw
$versionMatch = [regex]::Match($tocText, '(?m)^## Version:\s*([^\r\n]+)')
if (-not $versionMatch.Success) {
    throw "LootPathway_TBC.toc does not contain a Version field."
}
$version = $versionMatch.Groups[1].Value.Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Invalid addon version '$version'. Expected a semantic version such as 0.4.6."
}
$zipPath = Join-Path $projectRoot "LootPathway-$version.zip"
. (Join-Path $projectRoot "tests\ReleaseFiles.ps1")

& (Join-Path $projectRoot "tests\Test-All.ps1")

if (Test-Path -LiteralPath $addonRoot) {
    Remove-Item -LiteralPath $addonRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $addonRoot -Force | Out-Null

$addonFiles = @(Get-LootPathwayReleaseFiles)

foreach ($file in $addonFiles) {
    $nativeFile = $file -replace '[\\/]', [System.IO.Path]::DirectorySeparatorChar
    $destination = Join-Path $addonRoot $nativeFile
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot $nativeFile) -Destination $destination -Force
}

Add-Type -AssemblyName System.IO.Compression
$zipStream = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::Create)
$archive = $null
try {
    $archive = [System.IO.Compression.ZipArchive]::new(
        $zipStream,
        [System.IO.Compression.ZipArchiveMode]::Create,
        $false
    )
    $fixedTimestamp = [System.DateTimeOffset]::new(2000, 1, 1, 0, 0, 0, [System.TimeSpan]::Zero)
    foreach ($file in ($addonFiles | Sort-Object)) {
        $entryName = "LootPathway/" + ($file -replace '\\', '/')
        $entry = $archive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
        $entry.LastWriteTime = $fixedTimestamp
        $nativeFile = $file -replace '[\\/]', [System.IO.Path]::DirectorySeparatorChar
        $sourceStream = [System.IO.File]::OpenRead((Join-Path $projectRoot $nativeFile))
        $entryStream = $null
        try {
            $entryStream = $entry.Open()
            $sourceStream.CopyTo($entryStream)
        }
        finally {
            if ($entryStream) { $entryStream.Dispose() }
            $sourceStream.Dispose()
        }
    }
}
finally {
    if ($archive) { $archive.Dispose() }
    else { $zipStream.Dispose() }
}
& (Join-Path $projectRoot "tests\Test-Package.ps1") -ZipPath $zipPath -ExpectedVersion $version
Write-Output "Built $zipPath"
