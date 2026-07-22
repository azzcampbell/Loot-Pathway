$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$core = Get-Content -LiteralPath (Join-Path $projectRoot "Core.lua") -Raw
$data = Get-Content -LiteralPath (Join-Path $projectRoot "Data.lua") -Raw
$engine = Get-Content -LiteralPath (Join-Path $projectRoot "Engine.lua") -Raw
$ui = Get-Content -LiteralPath (Join-Path $projectRoot "UI.lua") -Raw
$diagnostics = Get-Content -LiteralPath (Join-Path $projectRoot "Diagnostics.lua") -Raw
$allRuntime = $core + "`n" + $data + "`n" + $engine + "`n" + $diagnostics + "`n" + $ui
$errors = [System.Collections.Generic.List[string]]::new()

function Require-Match([string]$Text, [string]$Pattern, [string]$Message) {
    if ($Text -notmatch $Pattern) { $script:errors.Add($Message) }
}

Require-Match $core 'schemaVersion\s*=\s*2' "SavedVariables schema version 2 is missing."
Require-Match $core 'characters\s*=\s*\{\}' "Per-character profile storage is missing."
Require-Match $core 'function LP:ActivateCharacterProfile' "Character profile activation is missing."
Require-Match $core 'pendingLegacyCompleted' "Legacy completion migration is missing."
Require-Match $core 'LootPathwayDB\.completed\s*=\s*nil' "Legacy account-wide completion data is not retired after migration."
if ($allRuntime -match 'self\.db\.completed|LP\.db\.completed') { $errors.Add("Runtime code still reads account-wide completion state.") }

Require-Match $data '\["Feral Combat"\]\s*=\s*\{"Cat","Bear"\}' "Feral Cat/Bear guide choices are missing."
Require-Match $engine 'function LP:GetGuideChoices' "Guide choice resolution is missing."
Require-Match $engine 'function LP:SetGuideOverride' "Guide override persistence is missing."
Require-Match $engine 'override\s*=\s*self:GetGuideOverride' "Embedded guide resolution does not consult the character override."
Require-Match $ui 'function LP:CycleGuideSelection' "The in-game guide selector is missing."

Require-Match $core 'RegisterEvent\("PLAYER_TALENT_UPDATE"\)' "Talent-change refresh event is missing."
Require-Match $core 'RegisterEvent\("ACTIVE_TALENT_GROUP_CHANGED"\)' "Dual-spec refresh event is missing."
Require-Match $ui 'CreateFrame\("DressUpModel"' "DressUpModel preview is missing."
Require-Match $ui 'playerModel\.TryOn' "Item preview dressing is missing."
Require-Match $diagnostics 'function LP:RunSelfTests' "In-game runtime self-tests are missing."
Require-Match $core 'input == "selftest"' "The /lpw selftest command is missing."

if ($errors.Count -gt 0) {
    throw "Runtime contract validation failed:`n - $($errors -join "`n - ")"
}

Write-Output "Runtime contracts valid: character profiles, guide overrides, talent events and model preview are wired."
