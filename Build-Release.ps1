$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$releaseRoot = Join-Path $projectRoot "release"
$addonRoot = Join-Path $releaseRoot "LootPathway"
$zipPath = Join-Path $projectRoot "LootPathway-0.4.5.zip"

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
    "README.md"
)

foreach ($file in $addonFiles) {
    $destination = Join-Path $addonRoot $file
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot $file) -Destination $destination -Force
}

Compress-Archive -LiteralPath $addonRoot -DestinationPath $zipPath -CompressionLevel Optimal -Force
Write-Output "Built $zipPath"
