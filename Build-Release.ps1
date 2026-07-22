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

if (Test-Path -LiteralPath $addonRoot) {
    Remove-Item -LiteralPath $addonRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $addonRoot -Force | Out-Null

$addonFiles = @(
    "LootPathway_TBC.toc",
    "Core.lua",
    "Data.lua",
    "BisData.lua",
    "Engine.lua",
    "UI.lua",
    "Assets\Brand\LootPathway-Minimap.tga",
    "README.md"
)

foreach ($file in $addonFiles) {
    $destination = Join-Path $addonRoot $file
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot $file) -Destination $destination -Force
}

Compress-Archive -LiteralPath $addonRoot -DestinationPath $zipPath -CompressionLevel Optimal -Force
Write-Output "Built $zipPath"
