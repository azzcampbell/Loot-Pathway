param(
    [Parameter(Mandatory = $true)]
    [string[]]$AuditReports
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$orders = @{}

foreach ($reportPath in $AuditReports) {
    $resolvedReport = (Resolve-Path -LiteralPath $reportPath).Path
    foreach ($report in (Get-Content -LiteralPath $resolvedReport -Raw | ConvertFrom-Json)) {
        foreach ($item in $report.displayOrders) {
            $key = "$($report.class)|$($report.guide)|$($report.phase)|$($item.id)"
            if ($orders.ContainsKey($key)) { throw "Duplicate display-order key '$key'." }
            $orders[$key] = [int]$item.order
        }
    }
}

if ($orders.Count -ne 7228) {
    throw "Expected 7,228 reviewed runtime display orders, found $($orders.Count)."
}

function Add-OrdersToFile([string]$Path, [bool]$GeneratedData) {
    $lines = [System.Collections.Generic.List[string]]::new()
    $class = $null; $guide = $null; $phase = -1; $inLists = -not $GeneratedData
    $annotated = 0; $retired = 0

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

        $entryPattern = if ($GeneratedData) {
            '^                \{(\d+), "[^"]+", "[^"]+", "[^"]*", "[^"]*", "[^"]*", "[^"]*", "[ABH]"(?:, \d+)?\},$'
        } else {
            '^\s+\{(\d+),"[^"]+","[^"]+","[^"]*","[^"]*","[^"]*","[^"]*","[ABH]"(?:,\d+)?\},$'
        }
        if ($line -match $entryPattern) {
            $key = "$class|$guide|$phase|$([int]$Matches[1])"
            $order = $orders[$key]
            if ($null -eq $order) {
                if (-not $GeneratedData) { throw "Correction item '$key' has no reviewed display order." }
                $order = 9999
                $retired++
            } else {
                $annotated++
            }
            $separator = if ($GeneratedData) { ", " } else { "," }
            $line = [regex]::Replace($line, '(?:,\s*\d+)?\},$', "$separator$order},")
        }
        $lines.Add($line)
    }

    $encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllLines($Path, $lines, $encoding)
    return [pscustomobject]@{ annotated=$annotated; retired=$retired }
}

$dataResult = Add-OrdersToFile (Join-Path $projectRoot "BisData.lua") $true
$correctionResult = Add-OrdersToFile (Join-Path $projectRoot "WowheadCorrections.lua") $false
if ($dataResult.annotated -ne 7180 -or $dataResult.retired -ne 8 -or $correctionResult.annotated -ne 48) {
    throw "Unexpected annotation totals: base=$($dataResult.annotated), retired=$($dataResult.retired), corrections=$($correctionResult.annotated)."
}

Write-Output "Applied 7,228 Wowhead display orders (7,180 base entries and 48 corrections); marked eight retired base entries out of ranking."
