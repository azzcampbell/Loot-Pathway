$ErrorActionPreference = "Stop"

$testRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $testRoot "Validate-BisData.ps1")
& (Join-Path $testRoot "Validate-DungeonDifficulty.ps1")
& (Join-Path $testRoot "Test-SourceContracts.ps1")
& (Join-Path $testRoot "Test-PackagerManifest.ps1")
& (Join-Path $testRoot "Test-LuaEngine.ps1")
& (Join-Path $testRoot "Test-ReleaseMetadata.ps1")
Write-Output "All Loot Pathway validation checks passed."
