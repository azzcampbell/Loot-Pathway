param(
    [Parameter(Mandatory = $true)]
    [string[]]$AuditReports
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$rankings = @{}

foreach ($reportPath in $AuditReports) {
    $resolvedReport = (Resolve-Path -LiteralPath $reportPath).Path
    $parsedReports = Get-Content -LiteralPath $resolvedReport -Raw | ConvertFrom-Json
    foreach ($report in $parsedReports) {
        foreach ($item in @($report.wowheadRankings)) {
            $key = "$($report.class)|$($report.guide)|$($report.phase)|$($item.id)"
            if ($rankings.ContainsKey($key) -and $rankings[$key] -ne $item.rank) {
                throw "Conflicting Wowhead ranks for '$key': '$($rankings[$key])' and '$($item.rank)'."
            }
            $rankings[$key] = [string]$item.rank
        }
    }
}

if ($rankings.Count -ne 7124) {
    throw "Expected 7,124 linked Wowhead rankings, found $($rankings.Count)."
}

function ConvertTo-LuaString([string]$Value) {
    return $Value.Replace('\', '\\').Replace('"', '\"')
}

function Update-Ranks([string]$Path, [bool]$GeneratedData) {
    $lines = [System.Collections.Generic.List[string]]::new()
    $class = $null; $guide = $null; $phase = -1; $inLists = -not $GeneratedData
    $linked = 0; $fallback = 0

    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($GeneratedData -and $line -match '^LP\.BIS_LISTS\s*=') { $inLists = $true; $lines.Add($line); continue }
        if ($GeneratedData -and $line -match '^LP\.BIS_AUGMENTS\s*=') { $inLists = $false; $lines.Add($line); continue }
        if (-not $inLists) { $lines.Add($line); continue }

        if ($GeneratedData) {
            if ($line -match '^    \["([^"]+)"\] = \{$') { $class = $Matches[1]; $lines.Add($line); continue }
            if ($line -match '^        \["([^"]+)"\] = \{$') { $guide = $Matches[1]; $lines.Add($line); continue }
            if ($line -match '^            \[([012])\] = \{$') { $phase = [int]$Matches[1]; $lines.Add($line); continue }
        } elseif ($line -match 'class="([^"]+)", guide="([^"]+)", phase=(\d+)') {
            $class = $Matches[1]; $guide = $Matches[2]; $phase = [int]$Matches[3]
            $lines.Add($line); continue
        }

        $pattern = if ($GeneratedData) {
            '^(\s+\{(\d+), "[^"]+", ")([^"]+)(", "[^"]*", "[^"]*", "[^"]*", "[^"]*", "[ABH]", \d+\},)$'
        } else {
            '^(\s+\{(\d+),"[^"]+",")([^"]+)(","[^"]*","[^"]*","[^"]*","[^"]*","[ABH]",\d+\},)$'
        }
        if ($line -match $pattern) {
            $prefix = $Matches[1]
            $itemID = [int]$Matches[2]
            $oldRank = $Matches[3]
            $suffix = $Matches[4]
            $key = "$class|$guide|$phase|$itemID"
            if ($rankings.ContainsKey($key)) {
                $newRank = $rankings[$key]
                $linked++
            } else {
                $newRank = if ($oldRank -match '^BIS') {
                    if ($oldRank -match 'Mit') { 'Best - Mitigation' } else { 'Best' }
                } elseif ($oldRank -eq 'Alt') {
                    'Optional'
                } else {
                    $oldRank
                }
                $fallback++
            }
            $line = $prefix + (ConvertTo-LuaString $newRank) + $suffix
        }
        $lines.Add($line)
    }

    [System.IO.File]::WriteAllLines($Path, $lines, [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ linked=$linked; fallback=$fallback }
}

$base = Update-Ranks (Join-Path $projectRoot 'BisData.lua') $true
$corrections = Update-Ranks (Join-Path $projectRoot 'WowheadCorrections.lua') $false
if (($base.linked + $corrections.linked) -ne 7124 -or ($base.fallback + $corrections.fallback) -ne 112) {
    throw "Unexpected rank totals: linked=$($base.linked + $corrections.linked), fallback=$($base.fallback + $corrections.fallback)."
}

Write-Output "Applied 7,124 exact Wowhead ranks and 112 reviewed fallback ranks."
