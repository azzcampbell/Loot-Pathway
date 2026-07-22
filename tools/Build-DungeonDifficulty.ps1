param(
    [Parameter(Mandatory=$true)]
    [string]$AtlasLootDataPath,
    [string]$SourceCommit = "unknown",
    [string]$OutputPath = ".\DungeonDifficultyData.lua",
    [string]$AuditPath = ".\tools\dungeon-difficulty-audit.json"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$zones = @(
    "Hellfire Ramparts", "Blood Furnace", "Shattered Halls", "Slave Pens", "Underbog", "Steamvault",
    "Mana Tombs", "Mana-Tombs", "Auchenai Crypts", "Sethekk Halls", "Shadow Labyrinth",
    "Old Hillsbrad", "Black Morass", "Mechanar", "Botanica", "Arcatraz", "Magisters' Terrace"
)
$zonePattern = ($zones | ForEach-Object { [regex]::Escape($_) }) -join '|'
$items = @{}
$manualModes = @{
    # Seasonal Ahune drops are not included in AtlasLootClassic's dungeon file.
    # Wowhead TBC item/NPC pages confirm the scythe drops in both modes and the necklace only in Heroic.
    35511 = 'HEROIC' # Hailstone Pendant
    35514 = 'BOTH'   # Frostscythe of Lord Ahune
}

function Add-TargetEntries([string]$Path) {
    foreach ($line in Get-Content -LiteralPath $Path) {
        $match = [regex]::Match($line, '^\s+\{(\d+),\s*"[^"]+",\s*"[^"]+",\s*"([^"]*)",\s*"([^"]*)",\s*"([^"]*)",\s*"([^"]*)",\s*"[ABH]"')
        if (-not $match.Success) { continue }
        $combined = $match.Groups[4].Value + ' ' + $match.Groups[5].Value + ' ' + $match.Groups[6].Value
        if ($match.Groups[3].Value -eq 'Drop' -and $combined -match $zonePattern) {
            $id = [int]$match.Groups[1].Value
            if (-not $items.ContainsKey($id)) { $items[$id] = $match.Groups[2].Value }
        }
    }
}

Add-TargetEntries (Join-Path $projectRoot 'BisData.lua')
Add-TargetEntries (Join-Path $projectRoot 'WowheadCorrections.lua')
if ($items.Count -lt 300) { throw "Expected at least 300 unique dungeon drops, found $($items.Count)." }
if (-not (Test-Path -LiteralPath $AtlasLootDataPath)) { throw "AtlasLoot TBC data file not found: $AtlasLootDataPath" }

$modes = @{}
$activeMode = $null
$modeDepth = 0
foreach ($line in Get-Content -LiteralPath $AtlasLootDataPath) {
    if (-not $activeMode) {
        $start = [regex]::Match($line, '^\s*\[(NORMAL|HEROIC)_DIFF\]\s*=\s*\{')
        if ($start.Success) {
            $activeMode = $start.Groups[1].Value
            $modeDepth = ([regex]::Matches($line, '\{')).Count - ([regex]::Matches($line, '\}')).Count
        }
        continue
    }

    $itemMatch = [regex]::Match($line, '^\s*\{\s*\d+\s*,\s*(\d+)\b')
    if ($itemMatch.Success) {
        $id = [int]$itemMatch.Groups[1].Value
        if ($items.ContainsKey($id)) {
            if (-not $modes.ContainsKey($id)) { $modes[$id] = @{ NORMAL=$false; HEROIC=$false } }
            $modes[$id][$activeMode] = $true
        }
    }

    $modeDepth += ([regex]::Matches($line, '\{')).Count - ([regex]::Matches($line, '\}')).Count
    if ($modeDepth -le 0) { $activeMode = $null; $modeDepth = 0 }
}

$results = [System.Collections.Generic.List[object]]::new()
$missing = [System.Collections.Generic.List[string]]::new()
foreach ($id in @($items.Keys | Sort-Object)) {
    if ($manualModes.ContainsKey($id)) {
        $results.Add([pscustomobject]@{ id=[int]$id; name=$items[$id]; difficulty=$manualModes[$id] })
        continue
    }
    $itemModes = $modes[$id]
    if (-not $itemModes -or (-not $itemModes.NORMAL -and -not $itemModes.HEROIC)) {
        $missing.Add("$id $($items[$id])")
        continue
    }
    $difficulty = if ($itemModes.NORMAL -and $itemModes.HEROIC) { 'BOTH' } elseif ($itemModes.HEROIC) { 'HEROIC' } else { 'NORMAL' }
    $results.Add([pscustomobject]@{ id=[int]$id; name=$items[$id]; difficulty=$difficulty })
}
if ($missing.Count -gt 0) { throw "AtlasLoot did not resolve every bundled dungeon target:`n - $($missing -join "`n - ")" }

$resolvedAudit = if ([System.IO.Path]::IsPathRooted($AuditPath)) { $AuditPath } else { Join-Path $projectRoot $AuditPath }
$resolvedOutput = if ([System.IO.Path]::IsPathRooted($OutputPath)) { $OutputPath } else { Join-Path $projectRoot $OutputPath }
$encoding = [System.Text.UTF8Encoding]::new($false)
$audit = [ordered]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    source = 'AtlasLootClassic TBC dungeon tables'
    sourceUrl = 'https://github.com/Hoizame/AtlasLootClassic/blob/master/AtlasLootClassic_DungeonsAndRaids/data-tbc.lua'
    sourceCommit = $SourceCommit
    items = @($results | Sort-Object id)
}
[System.IO.File]::WriteAllText($resolvedAudit, (($audit | ConvertTo-Json -Depth 5) + "`n"), $encoding)

$normalCount = @($results | Where-Object difficulty -eq 'NORMAL').Count
$heroicCount = @($results | Where-Object difficulty -eq 'HEROIC').Count
$bothCount = @($results | Where-Object difficulty -eq 'BOTH').Count
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('local _, LP = ...')
$lines.Add('')
$lines.Add('-- Generated from AtlasLootClassic''s explicit TBC Normal and Heroic dungeon tables.')
$lines.Add('-- Representative modes were cross-checked against the linked Wowhead TBC item pages.')
$lines.Add('LP.DUNGEON_DIFFICULTY_META = {')
$lines.Add('    source = "AtlasLootClassic TBC dungeon tables; representative Wowhead cross-check",')
$lines.Add('    reviewed = "2026-07-22",')
$lines.Add("    items = $($results.Count),")
$lines.Add("    normal = $normalCount,")
$lines.Add("    heroic = $heroicCount,")
$lines.Add("    both = $bothCount,")
$lines.Add('}')
$lines.Add('')
$lines.Add('LP.DUNGEON_DIFFICULTY = {')
foreach ($item in @($results | Sort-Object id)) {
    $safeName = $item.name.Replace('--', '- -')
    $lines.Add("    [$($item.id)] = `"$($item.difficulty)`", -- $safeName")
}
$lines.Add('}')
$lines.Add('')
[System.IO.File]::WriteAllLines($resolvedOutput, $lines, $encoding)

Write-Output "Generated $resolvedOutput with $($results.Count) items: $normalCount Normal, $heroicCount Heroic and $bothCount both."
