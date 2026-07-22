$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$core = Get-Content -LiteralPath (Join-Path $projectRoot "Core.lua") -Raw
$data = Get-Content -LiteralPath (Join-Path $projectRoot "Data.lua") -Raw
$engine = Get-Content -LiteralPath (Join-Path $projectRoot "Engine.lua") -Raw
$corrections = Get-Content -LiteralPath (Join-Path $projectRoot "WowheadCorrections.lua") -Raw
$difficulty = Get-Content -LiteralPath (Join-Path $projectRoot "DungeonDifficultyData.lua") -Raw
$ui = Get-Content -LiteralPath (Join-Path $projectRoot "UI.lua") -Raw
$diagnostics = Get-Content -LiteralPath (Join-Path $projectRoot "Diagnostics.lua") -Raw
$allRuntime = $core + "`n" + $data + "`n" + $corrections + "`n" + $difficulty + "`n" + $engine + "`n" + $diagnostics + "`n" + $ui
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
Require-Match $ui 'label=label\.\." \(Auto\)"' "The detected talent guide is not labelled Auto in the picker."
Require-Match $ui 'label=label\.\." \(Selected\)"' "The manually selected guide is not labelled Selected in the picker."
if ($ui -match 'Automatically follows your talent tree') { $errors.Add("The retired automatic-guide tooltip is still rendered.") }
Require-Match $ui 'RegisterEscapeClose\("LootPathwayFrame"\)' "The main window is not registered for Escape-key closing."
Require-Match $ui 'RegisterEscapeClose\("LootPathwayOptionsFrame"\)' "The options window is not registered for Escape-key closing."

Require-Match $core 'RegisterEvent\("PLAYER_TALENT_UPDATE"\)' "Talent-change refresh event is missing."
Require-Match $core 'RegisterEvent\("ACTIVE_TALENT_GROUP_CHANGED"\)' "Dual-spec refresh event is missing."
Require-Match $ui 'CreateFrame\("DressUpModel"' "DressUpModel preview is missing."
Require-Match $ui 'playerModel\.TryOn' "Item preview dressing is missing."
Require-Match $ui 'playerModel\.UndressSlot' "Conflicting weapon preview clearing is missing."
Require-Match $ui '(?s)\{1,"HEAD","LEFT",20,-104\}.*\{10,"HANDS","RIGHT",-20,-104\}' "Head and Hands are not aligned on the same character-screen row."
Require-Match $ui '(?s)\{2,"NECK","LEFT",20,-152\}.*\{6,"WAIST","RIGHT",-20,-152\}' "Neck and Waist are not aligned on the same character-screen row."
Require-Match $ui '(?s)\{3,"SHOULDER","LEFT",20,-200\}.*\{7,"LEGS","RIGHT",-20,-200\}' "Shoulders and Legs are not aligned on the same character-screen row."
Require-Match $ui '(?s)\{15,"BACK","LEFT",20,-248\}.*\{8,"FEET","RIGHT",-20,-248\}' "Back and Feet are not aligned on the same character-screen row."
Require-Match $ui '(?s)\{5,"CHEST","LEFT",20,-296\}.*\{11,"RING","RIGHT",-20,-296,1\}' "Chest and the first Ring are not aligned on the same character-screen row."
Require-Match $ui '(?s)\{9,"WRIST","LEFT",20,-440\}.*\{14,"TRINKET","RIGHT",-20,-440,2\}' "Wrists and the second Trinket are not aligned on the bottom character-screen row."
Require-Match $ui '(?s)local DECORATIVE_SLOTS\s*=\s*\{.*\{4,"LEFT",20,-344\}.*\{19,"LEFT",20,-392\}' "Shirt and Tabard do not follow Chest in the left character-screen column."
Require-Match $ui 'function LP:CreateDecorativeGearSlot' "Decorative shirt and tabard slots are missing."
Require-Match $ui 'CreateFrame\("Frame",nil,parent,"BackdropTemplate"\).*slot:EnableMouse\(false\)' "Decorative shirt and tabard slots are still interactive."
Require-Match $ui 'GetInventoryItemTexture\("player",slot\.inventory\)' "Decorative slots do not display the currently equipped shirt and tabard."
Require-Match $ui 'slot\.icon:SetDesaturated\(true\)' "Decorative shirt and tabard slots are not greyed out."
Require-Match $ui 'for _,inventory in ipairs\(\{4,19\}\)' "The character model does not explicitly synchronise shirt and tabard equipment."
Require-Match $ui 'not link and self\.playerModel\.UndressSlot' "Removing a shirt or tabard does not clear it from the character model."
Require-Match $core '(?s)event == "PLAYER_EQUIPMENT_CHANGED".*LP:RefreshModel\(\).*LP:Refresh\(\)' "Equipment changes do not refresh both the character model and decorative slots."
Require-Match $ui 'button\.closeBorder' "Close buttons are missing their explicit unclipped border."
Require-Match $ui 'Click a gear slot to see its guide choices\.' "The main header is missing its action-led subtext."
Require-Match $ui 'titleRuleLeft' "The main title is missing its left decorative rule."
Require-Match $ui 'headerAccent' "The main header is missing its centred accent divider."
Require-Match $ui 'button\.closeGlyph=.*SetText\("X"\)' "Close buttons are missing their centred X glyph."
Require-Match $ui '\{"BOTTOMLEFT",1,1,size-2,2\}' "Close buttons are not using fixed pixel-safe border geometry."
if ($ui -match 'closeLines|line\.SetRotation') { $errors.Add("Close buttons still use glitch-prone rotated line textures.") }
Require-Match $ui 'row\.hoverBorder' "Drawer rows are missing their inset unclipped hover border."
Require-Match $ui '\{"BOTTOMLEFT",1,1,DRAWER_CONTENT_WIDTH-2,2\}' "Drawer hover border is not using fixed pixel-safe bottom-edge geometry."
Require-Match $ui 'local DRAWER_WIDTH = 468' "The replacement drawer is not using the approved tighter width."
Require-Match $ui 'local DRAWER_CONTENT_WIDTH = 414' "The replacement drawer content is not using the approved tighter width."
Require-Match $ui 'button:SetSize\(width,27\); button:SetPoint\("TOPLEFT",x,-116\)' "Source filters are not using the tighter vertical rhythm."
Require-Match $ui 'local height=82\s*\r?\n\s*local row=CreateFrame' "Drawer item rows are not using the tighter 82-pixel height."
Require-Match $ui 'header:Show\(\); y=y\+36' "Phase headers are not using the tighter vertical spacing."
Require-Match $ui 'row:Show\(\); y=y\+90' "Drawer items are not using the tighter vertical spacing."
Require-Match $ui 'y=y\+8' "Phase groups are not using the tighter closing gap."
Require-Match $ui 'header\.pixelBorder' "Collapsible phase headers are missing their explicit unclipped border."
Require-Match $ui 'self:SetHeaderBorderColor' "Collapsible phase headers do not use the pixel-safe border colour setter."
if ($ui -match 'header:SetScript\("On(Enter|Leave)",function\(self\) self:SetBackdropBorderColor') { $errors.Add("Collapsible phase header interactions still use glitch-prone native one-pixel borders.") }
Require-Match $ui 'chip\.pixelBorder' "Drawer item tags are missing their explicit unclipped border."
Require-Match $ui 'row\.rankChip:SetChipBorderColor' "Drawer rank tags do not use the pixel-safe border colour setter."
Require-Match $ui 'row\.sourceChip:SetChipBorderColor' "Drawer source tags do not use the pixel-safe border colour setter."
if ($ui -match 'row\.(rankChip|sourceChip):SetBackdropBorderColor') { $errors.Add("Drawer item tags still use glitch-prone native one-pixel borders.") }
Require-Match $ui 'qualityFrame:SetShown\(priorBISPhase~=nil and not targetMet\)' "A prior-phase quality border can still override a green MET border."
Require-Match $ui 'button\.rank:SetWidth\(40\); button\.rank:SetWordWrap\(false\)' "Gear-slot rank labels are not constrained to the icon width."
Require-Match $ui 'guideRankTier=="OPTION" and "OPT"' "Gear-slot Option labels are not shortened to prevent overflow."
if ($ui -match 'displayItem then button:SetBackdropBorderColor\(unpack\(PHASES\[phase\]\.colour\)\)') { $errors.Add("Gear preview borders still use phase colours instead of item quality colours.") }
Require-Match $engine 'function LP:GetEffectiveDisplayOrder' "Reviewed cross-category display-order overrides are missing."
Require-Match $engine 'function LP:IsBestRank' "Wowhead Best/BiS rank interpretation is missing."
Require-Match $engine 'function LP:GetRankTier' "Wowhead rank grouping is missing."
Require-Match $engine 'function LP:GetRankDisplayLabel' "Readable Wowhead rank labels are missing."
Require-Match $ui 'Guide rank:' "The drawer tooltip does not expose the original guide rank."
Require-Match $engine 'function LP:GetRankContextLabel' "Contextual guide ranks are not labelled for players."
Require-Match $engine 'function LP:GetItemGuidePosition' "Equipped guide alternatives cannot be resolved independently of Best rank."
Require-Match $engine 'item\.equipped\s*=\s*isEquipped' "Equipped guide alternatives are not retained in Reset-mode recommendations."
Require-Match $engine 'item\.completed\s*=\s*item\.completed\s+or\s+isEquipped' "Equipped guide alternatives are not automatically marked as owned."
Require-Match $engine '(?s)function LP:GetPhaseSlotItems.*local equippedIDs\s*=\s*self:GetEquippedIDs\(slot\).*item\.equipped\s*=\s*equippedIDs\[item\.id\]\s*==\s*true.*item\.completed\s*=\s*item\.completed\s+or\s+item\.equipped' "Phase drawers do not mark equipped guide items as owned."
Require-Match $ui 'item\.equipped and "EQUIPPED"' "Equipped drawer choices are not visibly labelled."
Require-Match $ui 'not row\.item\.equipped' "Automatically detected equipped items can still be manually unticked."
Require-Match $engine 'function LP:GetEffectiveEntrySlot' "Rank-labelled off-hand items are not normalised to the correct slot."
Require-Match $engine 'equippedID == target\.id' "MET does not require the exact guide item to be equipped."
if ($engine -match 'positionPhase > phase|positionPhase == phase and positionRank <= targetRank') { $errors.Add("MET still infers same-or-better status from phase ordering.") }
Require-Match $data 'DUNGEON=\{label="Dungeon / Heroic",short="DUNGEON / HEROIC"' "Dungeon and Heroic are not merged into one source tier."
Require-Match $difficulty '\[27758\]\s*=\s*"HEROIC"' "Hydra-fang Necklace is not explicitly marked Heroic-only."
Require-Match $difficulty '\[24462\]\s*=\s*"NORMAL"' "Luminous Pearls of Insight is not explicitly marked Normal-only."
Require-Match $difficulty '\[28342\]\s*=\s*"BOTH"' "Warp Infused Drape is not explicitly marked for both modes."
Require-Match $engine 'return "\(\?\)"' "Unknown dungeon modes are still silently guessed."
Require-Match $ui '"DUNGEON","DUNGEON / HEROIC"' "The merged Dungeon / Heroic filter is missing."
Require-Match $ui 'LP\.db\.selectedSource="ALL"' "Phase selection does not reset the drawer source filter."
Require-Match $ui 'LP\.db\.collapsedPhases\[self\.phase\]=false' "Phase selection does not expand the selected drawer section."
Require-Match $engine 'BIS_PREVIEW_OVERRIDES' "Reviewed phase-preview target overrides are missing."
if ($ui -match 'Drag to rotate - Right-click to reset') { $errors.Add("Removed model rotation instruction is still rendered.") }
if ($ui -match 'modelPreviewLabel|BIS PREVIEW|PREVIEW:') { $errors.Add("The removed character-model preview caption is still rendered.") }
Require-Match $ui 'metLegend:SetPoint\("BOTTOM",0,4\)' "The MET legend is not centred clear of the trinket column."
Require-Match $ui 'MET = THIS GUIDE ITEM IS EQUIPPED' "The MET legend does not explain its exact meaning."
Require-Match $ui 'All phase sections are collapsed' "Collapsed phase sections still produce a misleading empty state."
Require-Match $ui 'Manual note only; this does not equip the item\.' "Owned-state guidance is missing."
Require-Match $ui 'Preview only; your equipped gear will not change\.' "Preview-state guidance is missing."
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
