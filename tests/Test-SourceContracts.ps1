$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$core = Get-Content -LiteralPath (Join-Path $projectRoot "Core.lua") -Raw
$data = Get-Content -LiteralPath (Join-Path $projectRoot "Data.lua") -Raw
$engine = Get-Content -LiteralPath (Join-Path $projectRoot "Engine.lua") -Raw
$corrections = Get-Content -LiteralPath (Join-Path $projectRoot "WowheadCorrections.lua") -Raw
$ui = Get-Content -LiteralPath (Join-Path $projectRoot "UI.lua") -Raw
$diagnostics = Get-Content -LiteralPath (Join-Path $projectRoot "Diagnostics.lua") -Raw
$allRuntime = $core + "`n" + $data + "`n" + $corrections + "`n" + $engine + "`n" + $diagnostics + "`n" + $ui
$errors = [System.Collections.Generic.List[string]]::new()

function Require-Match([string]$Text, [string]$Pattern, [string]$Message) {
    if ($Text -notmatch $Pattern) { $script:errors.Add($Message) }
}

Require-Match $core 'schemaVersion\s*=\s*2' "SavedVariables schema version 2 is missing."
Require-Match $core 'characters\s*=\s*\{\}' "Per-character profile storage is missing."
Require-Match $core 'function LP:ActivateCharacterProfile' "Character profile activation is missing."
Require-Match $core 'pendingLegacyCompleted' "Legacy completion migration is missing."
Require-Match $core 'self\.db\.displayPhase\s*=\s*-1' "Opening the addon does not force the Reset display."
Require-Match $core 'self:RefreshModel\(\)\s*\r?\n\s*self:Refresh\(\)' "Opening the addon does not synchronise the model before the gear display."
Require-Match $core 'LootPathwayDB\.completed\s*=\s*nil' "Legacy account-wide completion data is not retired after migration."
if ($allRuntime -match 'self\.db\.completed|LP\.db\.completed') { $errors.Add("Runtime code still reads account-wide completion state.") }

Require-Match $data '\["Feral Combat"\]\s*=\s*\{"Cat","Bear"\}' "Feral Cat/Bear guide choices are missing."
Require-Match $data '\["HUNTER:Survival:2:29298"\]\s*=\s*"BIS"' "Survival Phase 2 Band of Eternity BIS correction is missing."
Require-Match $engine 'function LP:GetGuideChoices' "Guide choice resolution is missing."
Require-Match $engine 'function LP:SetGuideOverride' "Guide override persistence is missing."
Require-Match $engine 'override\s*=\s*self:GetGuideOverride' "Embedded guide resolution does not consult the character override."
Require-Match $engine 'function LP:GetClassGuideChoices' "The class-wide spec picker choices are missing."
Require-Match $ui 'function LP:ToggleGuideMenu' "The in-game spec picker is missing."
Require-Match $ui 'label=label\.\." - Current"' "The detected talent spec is not labelled Current in the picker."
Require-Match $ui 'label=label\.\." - Selected"' "The manually selected guide is not labelled Selected in the picker."
if ($ui -match 'Automatically follows your talent tree') { $errors.Add("The retired automatic-guide tooltip is still rendered.") }
Require-Match $ui 'RegisterEscapeClose\("LootPathwayFrame"\)' "The main window is not registered for Escape-key closing."
Require-Match $ui 'RegisterEscapeClose\("LootPathwayOptionsFrame"\)' "The options window is not registered for Escape-key closing."

Require-Match $core 'RegisterEvent\("PLAYER_TALENT_UPDATE"\)' "Talent-change refresh event is missing."
Require-Match $core 'RegisterEvent\("ACTIVE_TALENT_GROUP_CHANGED"\)' "Dual-spec refresh event is missing."
Require-Match $ui 'CreateFrame\("DressUpModel"' "DressUpModel preview is missing."
Require-Match $ui 'playerModel\.TryOn' "Item preview dressing is missing."
Require-Match $ui 'playerModel\.UndressSlot' "Conflicting weapon preview clearing is missing."
Require-Match $ui 'button\.closeBorder' "Close buttons are missing their explicit unclipped border."
Require-Match $ui 'See what to chase next, and where it drops\.' "The main header is missing its plain-English subtext."
Require-Match $ui 'titleRuleLeft' "The main title is missing its left decorative rule."
Require-Match $ui 'headerAccent' "The main header is missing its centred accent divider."
Require-Match $ui 'button\.closeGlyph=.*SetText\("X"\)' "Close buttons are missing their centred X glyph."
Require-Match $ui '\{"BOTTOMLEFT",1,1,size-2,2\}' "Close buttons are not using fixed pixel-safe border geometry."
if ($ui -match 'closeLines|line\.SetRotation') { $errors.Add("Close buttons still use glitch-prone rotated line textures.") }
Require-Match $ui 'row\.hoverBorder' "Drawer rows are missing their inset unclipped hover border."
Require-Match $ui '\{"BOTTOMLEFT",1,1,400,2\}' "Drawer hover border is not using fixed pixel-safe bottom-edge geometry."
Require-Match $ui 'qualityFrame:SetShown\(priorBISPhase~=nil and not targetMet\)' "A prior-phase quality border can still override a green MET border."
if ($ui -match 'displayItem then button:SetBackdropBorderColor\(unpack\(PHASES\[phase\]\.colour\)\)') { $errors.Add("Gear preview borders still use phase colours instead of item quality colours.") }
Require-Match $engine 'function LP:GetEffectiveDisplayOrder' "Reviewed cross-category display-order overrides are missing."
Require-Match $engine 'BIS_PREVIEW_OVERRIDES' "Reviewed phase-preview target overrides are missing."
if ($ui -match 'Drag to rotate - Right-click to reset') { $errors.Add("Removed model rotation instruction is still rendered.") }
Require-Match $ui 'metLegend:SetPoint\("BOTTOM",0,4\)' "The MET legend is not centred clear of the trinket column."
Require-Match $engine 'function LP:EntryFitsSlot' "Flexible hand-slot matching is missing."
Require-Match $engine 'function LP:GetModelPreviewPlan' "Model preview planning is missing."
Require-Match $engine 'function LP:GetPhaseTargetAssignments' "Paired-slot phase target assignment is missing."
Require-Match $engine 'function LP:GetPhaseDisplayTarget' "Two-handed phase display suppression is missing."
Require-Match $ui 'displayItem=self:GetPhaseDisplayTarget' "Gear buttons do not use the two-hand-safe phase target."
Require-Match $ui 'if plan\.clearOffHand then pcall\(self\.playerModel\.UndressSlot' "The model does not re-clear the off hand after dressing a two-hander."
Require-Match $diagnostics 'function LP:RunSelfTests' "In-game runtime self-tests are missing."
Require-Match $diagnostics 'self:GetClassGuideChoices\(class\)' "In-game self-tests do not verify class-picker guide reachability."
Require-Match $diagnostics 'current Phase 2 preview combines a two-hander with an off hand' "In-game self-tests do not detect conflicting weapon previews."
Require-Match $diagnostics 'Atiesh is incorrectly selected as the current Phase 2 default weapon' "In-game self-tests do not detect the Atiesh preview regression."
Require-Match $core 'input == "selftest"' "The /lpw selftest command is missing."
Require-Match $corrections 'source="Wowhead TBC Anniversary"' "The reviewed Wowhead correction layer is missing provenance metadata."

if ($errors.Count -gt 0) {
    throw "Runtime contract validation failed:`n - $($errors -join "`n - ")"
}

Write-Output "Runtime contracts valid: character profiles, guide overrides, talent events and model preview are wired."
