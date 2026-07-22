param(
    [string]$Class,
    [string]$Guide,
    [int]$Phase = 2,
    [string]$Manifest = ".\tools\wowhead-phase2-guides.json"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$manifestPath = if ([System.IO.Path]::IsPathRooted($Manifest)) { $Manifest } else { Join-Path $projectRoot $Manifest }
$guides = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($Class) { $guides = @($guides | Where-Object { $_.class -eq $Class.ToUpperInvariant() }) }
if ($Guide) { $guides = @($guides | Where-Object { $_.guide -eq $Guide }) }
$guides = @($guides | Where-Object { $_.phase -eq $Phase })
if ($guides.Count -eq 0) { throw "No matching Wowhead guide is recorded in $manifestPath." }

function ConvertFrom-HtmlText([string]$Value) {
    $withoutTags = [regex]::Replace($Value, '<[^>]+>', ' ')
    $decoded = [System.Net.WebUtility]::HtmlDecode($withoutTags)
    return ([regex]::Replace($decoded, '\s+', ' ')).Trim()
}

function Get-SlotFromHeading([string]$Heading) {
    $patterns = [ordered]@{
        "Head"='\bHead\b|Helm'; "Shoulder"='Shoulder'; "Back"='\bBack\b|Cloak'; "Chest"='Chest';
        "Wrist"='Wrist|Bracer'; "Hands"='\bHand\b|Glove'; "Waist"='Waist|Belt'; "Legs"='\bLeg\b|Pants';
        "Feet"='Feet|Boot'; "Neck"='Neck'; "Ring"='Ring'; "Trinket"='Trinket';
        "Off Hand"='Offhand|Off-hand|Shield'; "Ranged/Relic"='Wand|Relic|Idol|Totem|Libram|Ranged';
        "Two Hand"='Two-Handed'; "Main Hand"='One-Handed|Weapon'
    }
    foreach ($pair in $patterns.GetEnumerator()) {
        if ($Heading -match $pair.Value) { return $pair.Key }
    }
    return $null
}

function Read-AddonEntries([string]$ClassName, [string]$GuideName, [int]$PhaseNumber) {
    $result = @{}
    $inLists = $false; $currentClass = $null; $currentGuide = $null; $currentPhase = -1
    foreach ($line in Get-Content -LiteralPath (Join-Path $projectRoot "BisData.lua")) {
        if ($line -match '^LP\.BIS_LISTS\s*=') { $inLists = $true; continue }
        if ($line -match '^LP\.BIS_AUGMENTS\s*=') { break }
        if (-not $inLists) { continue }
        if ($line -match '^    \["([^"]+)"\] = \{$') { $currentClass = $Matches[1]; continue }
        if ($line -match '^        \["([^"]+)"\] = \{$') { $currentGuide = $Matches[1]; continue }
        if ($line -match '^            \[([012])\] = \{$') { $currentPhase = [int]$Matches[1]; continue }
        if ($currentClass -eq $ClassName -and $currentGuide -eq $GuideName -and $currentPhase -eq $PhaseNumber -and
            $line -match '^                \{(\d+), "([^"]+)", "([^"]+)", "([^"]*)"') {
            $result[[int]$Matches[1]] = [pscustomobject]@{ id=[int]$Matches[1]; slot=$Matches[2]; rank=$Matches[3]; name=$Matches[4] }
        }
    }
    return $result
}

$reports = @()
foreach ($guideRecord in $guides) {
    $response = Invoke-WebRequest -UseBasicParsing -Uri $guideRecord.url -TimeoutSec 45
    $html = $response.Content
    $title = ConvertFrom-HtmlText ([regex]::Match($html, '<title>(.*?)</title>', 'IgnoreCase,Singleline').Groups[1].Value)
    if ($title -notmatch 'TBC Classic') { throw "$($guideRecord.class)/$($guideRecord.guide) resolved to a non-TBC guide: $title" }

    $wowheadItems = @{}
    $sections = [regex]::Matches($html, '<h3[^>]*>(.*?)</h3>(.*?)(?=<h3[^>]*>|<h2[^>]*>|$)', 'IgnoreCase,Singleline')
    foreach ($section in $sections) {
        $heading = ConvertFrom-HtmlText $section.Groups[1].Value
        $slot = Get-SlotFromHeading $heading
        if (-not $slot) { continue }
        foreach ($row in [regex]::Matches($section.Groups[2].Value, '<tr[^>]*>(.*?)</tr>', 'IgnoreCase,Singleline')) {
            $cells = [regex]::Matches($row.Groups[1].Value, '<td[^>]*>(.*?)</td>', 'IgnoreCase,Singleline')
            if ($cells.Count -lt 2) { continue }
            $itemMatch = [regex]::Match($cells[1].Groups[1].Value, '/tbc/item=(\d+)/[^"'']+[^>]*>(.*?)</a>', 'IgnoreCase,Singleline')
            if (-not $itemMatch.Success) { continue }
            $itemId = [int]$itemMatch.Groups[1].Value
            $wowheadItems[$itemId] = [pscustomobject]@{
                id=$itemId; slot=$slot; rank=(ConvertFrom-HtmlText $cells[0].Groups[1].Value)
                name=(ConvertFrom-HtmlText $itemMatch.Groups[2].Value); heading=$heading
            }
        }
    }

    $addonItems = Read-AddonEntries $guideRecord.class $guideRecord.guide $guideRecord.phase
    $missing = @($wowheadItems.Values | Where-Object { -not $addonItems.ContainsKey($_.id) } | Sort-Object slot,name)
    $extra = @($addonItems.Values | Where-Object { -not $wowheadItems.ContainsKey($_.id) } | Sort-Object slot,name)
    $slotDifferences = @($wowheadItems.Values | Where-Object { $addonItems.ContainsKey($_.id) -and $addonItems[$_.id].slot -ne $_.slot } | Sort-Object slot,name)
    $reports += [pscustomobject]@{
        class=$guideRecord.class; guide=$guideRecord.guide; phase=$guideRecord.phase; title=$title; url=$guideRecord.url
        wowheadItems=$wowheadItems.Count; addonItems=$addonItems.Count; missingFromAddon=$missing
        addonOnly=$extra; slotDifferences=$slotDifferences
    }
}

$reports | ConvertTo-Json -Depth 6
