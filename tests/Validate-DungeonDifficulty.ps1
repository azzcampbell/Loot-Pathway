$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$difficultyPath = Join-Path $projectRoot "DungeonDifficultyData.lua"
$zones = @(
    "Hellfire Ramparts", "Blood Furnace", "Shattered Halls", "Slave Pens", "Underbog", "Steamvault",
    "Mana Tombs", "Mana-Tombs", "Auchenai Crypts", "Sethekk Halls", "Shadow Labyrinth",
    "Old Hillsbrad", "Black Morass", "Mechanar", "Botanica", "Arcatraz", "Magisters' Terrace"
)
$zonePattern = ($zones | ForEach-Object { [regex]::Escape($_) }) -join '|'
$targets = @{}

foreach ($fileName in @("BisData.lua", "WowheadCorrections.lua")) {
    foreach ($line in Get-Content -LiteralPath (Join-Path $projectRoot $fileName)) {
        $entry = [regex]::Match($line, '^\s+\{(\d+),\s*"[^"]+",\s*"[^"]+",\s*"([^"]*)",\s*"([^"]*)",\s*"([^"]*)",\s*"([^"]*)",\s*"[ABH]"')
        if (-not $entry.Success) { continue }
        $combined = $entry.Groups[4].Value + ' ' + $entry.Groups[5].Value + ' ' + $entry.Groups[6].Value
        if ($entry.Groups[3].Value -eq "Drop" -and $combined -match $zonePattern) {
            $targets[[int]$entry.Groups[1].Value] = $entry.Groups[2].Value
        }
    }
}

$raw = Get-Content -LiteralPath $difficultyPath -Raw
$matches = [regex]::Matches($raw, '(?m)^\s*\[(\d+)\]\s*=\s*"(NORMAL|HEROIC|BOTH)"')
$modes = @{}
foreach ($match in $matches) {
    $id = [int]$match.Groups[1].Value
    if ($modes.ContainsKey($id)) { throw "Dungeon difficulty map contains duplicate item $id." }
    $modes[$id] = $match.Groups[2].Value
}

$missing = @($targets.Keys | Where-Object { -not $modes.ContainsKey($_) } | Sort-Object)
$extra = @($modes.Keys | Where-Object { -not $targets.ContainsKey($_) } | Sort-Object)
if ($missing.Count -gt 0) { throw "Dungeon targets are missing mode data: $($missing -join ', ')" }
if ($extra.Count -gt 0) { throw "Dungeon mode data contains unused items: $($extra -join ', ')" }
if ($raw -notmatch "items\s*=\s*$($modes.Count),") { throw "Dungeon difficulty metadata item count is stale." }

$expected = @{ 24462="NORMAL"; 27758="HEROIC"; 28288="BOTH"; 28342="BOTH"; 35511="HEROIC"; 35514="BOTH" }
foreach ($id in $expected.Keys) {
    if ($modes[$id] -ne $expected[$id]) { throw "Dungeon mode regression for item ${id}: expected $($expected[$id]), found $($modes[$id])." }
}

$counts = @{
    NORMAL = @($modes.Values | Where-Object { $_ -eq "NORMAL" }).Count
    HEROIC = @($modes.Values | Where-Object { $_ -eq "HEROIC" }).Count
    BOTH = @($modes.Values | Where-Object { $_ -eq "BOTH" }).Count
}
Write-Output "Dungeon difficulty data valid: $($modes.Count) items ($($counts.NORMAL) Normal, $($counts.HEROIC) Heroic, $($counts.BOTH) both), with no guessed modes."
