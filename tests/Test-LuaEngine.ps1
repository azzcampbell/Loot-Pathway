param([switch]$RequireLua)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$luaCommand = Get-Command lua -ErrorAction SilentlyContinue
if (-not $luaCommand -and $env:LOOT_PATHWAY_LUA) {
    $luaCommand = Get-Item -LiteralPath $env:LOOT_PATHWAY_LUA -ErrorAction SilentlyContinue
}
if (-not $luaCommand) {
    if ($RequireLua) { throw "Lua 5.1 is required for engine behaviour tests." }
    Write-Warning "Lua is unavailable; engine behaviour tests were skipped locally. CI requires them."
    return
}

$luaPath = if ($luaCommand.Source) { $luaCommand.Source } else { $luaCommand.FullName }
& $luaPath (Join-Path $projectRoot "tests\Test-Engine.lua") $projectRoot
if ($LASTEXITCODE -ne 0) { throw "Lua engine behaviour tests failed." }
