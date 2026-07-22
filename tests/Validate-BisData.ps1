$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$dataPath = Join-Path $projectRoot "BisData.lua"
$mappingPath = Join-Path $projectRoot "Data.lua"
$lines = Get-Content -LiteralPath $dataPath
$raw = $lines -join "`n"
$errors = [System.Collections.Generic.List[string]]::new()

function Add-ValidationError([string]$Message) {
    $script:errors.Add($Message)
}

$metaEntries = [regex]::Match($raw, '(?m)^\s*entries\s*=\s*(\d+),').Groups[1].Value
$metaUnique = [regex]::Match($raw, '(?m)^\s*uniqueItems\s*=\s*(\d+),').Groups[1].Value
if (-not $metaEntries -or -not $metaUnique) {
    throw "BisData.lua is missing entries or uniqueItems metadata."
}

$validSlots = @(
    "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands", "Waist",
    "Legs", "Feet", "Ring", "Trinket", "Main Hand", "Main Hand~Off Hand",
    "Two Hand", "Off Hand", "Ranged/Relic"
)
$requiredArmourSlots = @("Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet", "Ring", "Trinket", "Ranged/Relic")
$validRank = '^(BIS|Alt)(/BIS)?( (Mit|Stam|Thrt))?$'

$inLists = $false
$class = $null
$spec = $null
$phase = $null
$entries = [System.Collections.Generic.List[object]]::new()
$buckets = @{}
$guides = @{}

foreach ($line in $lines) {
    if ($line -match '^LP\.BIS_LISTS\s*=') { $inLists = $true; continue }
    if ($line -match '^LP\.BIS_AUGMENTS\s*=') { break }
    if (-not $inLists) { continue }
    if ($line -match '^    \["([^"]+)"\] = \{$') {
        $class = $Matches[1]
        if (-not $guides.ContainsKey($class)) { $guides[$class] = @{} }
        continue
    }
    if ($line -match '^        \["([^"]+)"\] = \{$') {
        $spec = $Matches[1]
        $guides[$class][$spec] = $true
        continue
    }
    if ($line -match '^            \[([012])\] = \{$') { $phase = [int]$Matches[1]; continue }
    if ($line -match '^                \{(\d+), "([^"]+)", "([^"]+)", "([^"]*)", "([^"]*)", "([^"]*)", "([^"]*)", "([ABH])"\},$') {
        $entry = [pscustomobject]@{
            Id = [int]$Matches[1]; Slot = $Matches[2]; Rank = $Matches[3]; Name = $Matches[4]
            SourceType = $Matches[5]; Source = $Matches[6]; Location = $Matches[7]; Faction = $Matches[8]
            Class = $class; Spec = $spec; Phase = $phase
        }
        $entries.Add($entry)
        $bucketKey = "$class|$spec|$phase"
        if (-not $buckets.ContainsKey($bucketKey)) { $buckets[$bucketKey] = @{} }
        $buckets[$bucketKey][$entry.Slot] = $true
        if ($entry.Id -le 0) { Add-ValidationError "$bucketKey contains invalid item ID $($entry.Id)." }
        if ($entry.Slot -notin $validSlots) { Add-ValidationError "$bucketKey item $($entry.Id) uses unknown slot '$($entry.Slot)'." }
        if ($entry.Rank -notmatch $validRank) { Add-ValidationError "$bucketKey item $($entry.Id) uses unknown rank '$($entry.Rank)'." }
        if ([string]::IsNullOrWhiteSpace($entry.Name)) { Add-ValidationError "$bucketKey item $($entry.Id) has no name." }
        if ($entry.SourceType -in @('', 'Unknown') -or $entry.Source -eq 'Unknown' -or $entry.Location -eq 'Unknown') {
            Add-ValidationError "$bucketKey item $($entry.Id) has incomplete source data."
        }
    }
}

if ($entries.Count -ne [int]$metaEntries) {
    Add-ValidationError "Metadata says $metaEntries entries but parsed $($entries.Count)."
}
$uniqueItems = @($entries.Id | Sort-Object -Unique).Count
if ($uniqueItems -ne [int]$metaUnique) {
    Add-ValidationError "Metadata says $metaUnique unique items but parsed $uniqueItems."
}

foreach ($className in $guides.Keys) {
    foreach ($guideName in $guides[$className].Keys) {
        foreach ($phaseNumber in 0..2) {
            $key = "$className|$guideName|$phaseNumber"
            if (-not $buckets.ContainsKey($key)) {
                Add-ValidationError "$key is missing or empty."
                continue
            }
            foreach ($slotName in $requiredArmourSlots) {
                if (-not $buckets[$key].ContainsKey($slotName)) {
                    Add-ValidationError "$key has no $slotName entries."
                }
            }
            if (-not ($buckets[$key].ContainsKey('Main Hand') -or $buckets[$key].ContainsKey('Main Hand~Off Hand') -or $buckets[$key].ContainsKey('Two Hand'))) {
                Add-ValidationError "$key has no usable weapon entry."
            }
        }
    }
}

$mappingRaw = Get-Content -LiteralPath $mappingPath -Raw
$reachable = @{}
foreach ($classMatch in [regex]::Matches($mappingRaw, '(?m)^    ([A-Z]+)=\{([^\r\n]+)\},$')) {
    $className = $classMatch.Groups[1].Value
    if (-not $reachable.ContainsKey($className)) { $reachable[$className] = @{} }
    foreach ($target in [regex]::Matches($classMatch.Groups[2].Value, '=(?:\s*)"([^"]+)"')) {
        $reachable[$className][$target.Groups[1].Value] = $true
    }
}
$inChoices = $false
$choiceClass = $null
foreach ($line in Get-Content -LiteralPath $mappingPath) {
    if ($line -match '^LP\.BIS_GUIDE_CHOICES\s*=') { $inChoices = $true; continue }
    if ($line -match '^LP\.BIS_RANK_OVERRIDES\s*=') { break }
    if (-not $inChoices) { continue }
    if ($line -match '^    ([A-Z]+)=\{$') {
        $choiceClass = $Matches[1]
        if (-not $reachable.ContainsKey($choiceClass)) { $reachable[$choiceClass] = @{} }
        continue
    }
    if ($choiceClass -and $line -match '=\{([^\r\n]+)\}') {
        foreach ($choice in [regex]::Matches($Matches[1], '"([^"]+)"')) {
            $reachable[$choiceClass][$choice.Groups[1].Value] = $true
        }
    }
}
foreach ($className in $guides.Keys) {
    foreach ($guideName in $guides[$className].Keys) {
        if (-not $reachable.ContainsKey($className) -or -not $reachable[$className].ContainsKey($guideName)) {
            Add-ValidationError "$className guide '$guideName' exists in BisData.lua but cannot be selected."
        }
    }
}

$phase2ManifestPath = Join-Path $projectRoot "tools\wowhead-phase2-guides.json"
if (-not (Test-Path -LiteralPath $phase2ManifestPath)) {
    Add-ValidationError "The Wowhead Phase 2 provenance manifest is missing."
} else {
    $phase2Manifest = Get-Content -LiteralPath $phase2ManifestPath -Raw | ConvertFrom-Json
    if ($phase2Manifest.Count -ne 25) { Add-ValidationError "Expected 25 Wowhead Phase 2 guide records, found $($phase2Manifest.Count)." }
    foreach ($className in $guides.Keys) {
        foreach ($guideName in $guides[$className].Keys) {
            $source = @($phase2Manifest | Where-Object { $_.class -eq $className -and $_.guide -eq $guideName -and $_.phase -eq 2 })
            if ($source.Count -ne 1) {
                Add-ValidationError "$className guide '$guideName' does not have exactly one Phase 2 Wowhead source."
            } elseif ($source[0].url -notmatch '^https://www\.wowhead\.com/tbc/guide/') {
                Add-ValidationError "$className guide '$guideName' has an invalid Wowhead source URL."
            }
        }
    }
}

if ($errors.Count -gt 0) {
    throw "BIS data validation failed:`n - $($errors -join "`n - ")"
}

Write-Output "BIS data valid: $($entries.Count) entries, $uniqueItems unique items, $($buckets.Count) class/spec/phase buckets."
