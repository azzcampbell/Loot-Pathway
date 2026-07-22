local root = arg[1] or "."
local failures, checks = {}, 0

local function check(condition, message)
    checks = checks + 1
    if not condition then table.insert(failures, message) end
end

local function loadAddonFile(name, addon)
    local chunk, reason = loadfile(root .. "/" .. name)
    if not chunk then error(reason) end
    chunk("LootPathway", addon)
end

local equipped, levels, names = {}, {}, {}
function UnitClass() return "Warrior", "WARRIOR" end
function UnitFactionGroup() return "Horde" end
function GetActiveTalentGroup() return 1 end
function GetTalentTabInfo(index) return nil, nil, nil, nil, index == 2 and 41 or 0 end
function GetInventoryItemID(_, inventory) return equipped[inventory] end
function GetInventoryItemLink(_, inventory)
    return equipped[inventory] and ("item:" .. equipped[inventory]) or nil
end
function GetItemInfo(item)
    local id = tonumber(item) or tonumber(string.match(item or "", "item:(%d+)"))
    return names[id] or ("Item " .. tostring(id)), "item:" .. tostring(id), 4, levels[id] or 100,
        nil, nil, nil, nil, nil, "Interface\\Icons\\INV_Misc_QuestionMark"
end

local LP = {db={selectedSource="ALL"}, characterDB={completed={}, guideOverrides={}}}
function LP:IsItemCompleted(itemID) return self.characterDB.completed[tostring(itemID)] == true end
loadAddonFile("Data.lua", LP)
loadAddonFile("BisData.lua", LP)
loadAddonFile("WowheadCorrections.lua", LP)
loadAddonFile("Engine.lua", LP)

check(LP.BIS_DATA_META.entries == 7228 and LP.BIS_DATA_META.uniqueItems == 1462, "reviewed runtime dataset totals must remain stable")
local orderFailure
for class, guides in pairs(LP.BIS_LISTS) do
    for guideName, phases in pairs(guides) do
        for phase, entries in pairs(phases) do
            local ordersBySlot, countsBySlot = {}, {}
            for _, entry in ipairs(entries) do
                local slot, displayOrder = entry[2], entry[9]
                ordersBySlot[slot], countsBySlot[slot] = ordersBySlot[slot] or {}, (countsBySlot[slot] or 0) + 1
                if type(displayOrder) ~= "number" or displayOrder < 1 or ordersBySlot[slot][displayOrder] then
                    orderFailure = class .. "/" .. guideName .. "/" .. phase .. "/" .. slot
                    break
                end
                ordersBySlot[slot][displayOrder] = true
            end
            for slot, count in pairs(countsBySlot) do
                for displayOrder = 1, count do
                    if not ordersBySlot[slot][displayOrder] then
                        orderFailure = class .. "/" .. guideName .. "/" .. phase .. "/" .. slot
                        break
                    end
                end
            end
        end
    end
end
check(not orderFailure, "runtime display orders must be unique and contiguous per guide/phase/slot: " .. tostring(orderFailure))
local detectedClass, detectedSpec = LP:GetPlayerBuild()
check(detectedClass == "WARRIOR" and detectedSpec == "Fury", "talent points must resolve the active specialization")
local feralChoices = LP:GetGuideChoices("DRUID", "Feral Combat")
check(#feralChoices == 2 and feralChoices[1] == "Cat" and feralChoices[2] == "Bear", "Feral Cat and Bear choices must both be reachable")
local hunterGuideChoices = LP:GetClassGuideChoices("HUNTER")
check(#hunterGuideChoices == 3 and hunterGuideChoices[1] == "Beast Mastery" and hunterGuideChoices[2] == "Marksmanship" and hunterGuideChoices[3] == "Survival",
    "Hunter spec picker must expose all three guides in class-spec order")
local pickerCoverageFailure
for class, guides in pairs(LP.BIS_LISTS) do
    local reachable = {}
    for _, guideName in ipairs(LP:GetClassGuideChoices(class)) do reachable[guideName] = true end
    for guideName in pairs(guides) do
        if not reachable[guideName] then pickerCoverageFailure = class .. "/" .. guideName; break end
    end
    if pickerCoverageFailure then break end
end
check(not pickerCoverageFailure, "every embedded guide must be reachable through the class picker: " .. tostring(pickerCoverageFailure))
check(LP:EntryFitsSlot("Main Hand~Off Hand", "MAINHAND"), "flexible weapon must fit main hand")
check(LP:EntryFitsSlot("Main Hand~Off Hand", "OFFHAND"), "flexible weapon must fit off hand")
check(not LP:EntryFitsSlot("Main Hand", "OFFHAND"), "main-hand-only weapon must not fit off hand")
check(LP:ClassifySource("Quest", "Example", "Shadowmoon Valley") == "QUEST", "quest source classification")
check(LP:ClassifySource("Profession", "Blacksmithing", "375") == "CRAFTABLE", "craft source classification")
check(LP:ClassifySource("Drop", "Prince Malchezaar", "Karazhan") == "RAID", "raid source classification")
check(LP:ClassifySource("Drop", "Quagmirran", "The Slave Pens (H)") == "HEROIC", "heroic source classification")
check(LP:GetDifficultySuffix("Drop", "Pathaleon", "The Mechanar") == "(N) (H)", "normal plus heroic suffix")

local fury = LP.BIS_LISTS.WARRIOR.Fury[1]
local furyIDs = {}
for _, entry in ipairs(fury) do furyIDs[entry[1]] = entry end
check(furyIDs[24544] ~= nil and furyIDs[23542] ~= nil, "current Phase 1 Fury alternatives must be applied")
check(furyIDs[30257] == nil and furyIDs[28429] == nil, "retired Phase 1 Fury entries must be removed")
local arcanePreRaid = LP.BIS_LISTS.MAGE.Arcane[0]
local hasNexusTorch = false
for _, entry in ipairs(arcanePreRaid) do if entry[1] == 27540 then hasNexusTorch = true end end
check(hasNexusTorch, "pre-raid Nexus Torch correction must be applied")

local originalGetPlayerBuild = LP.GetPlayerBuild
LP.GetPlayerBuild = function() return "HUNTER", "Beast Mastery", nil end
equipped[11], equipped[12] = nil, 28791
local ringAssignments = LP:GetPhaseTargetAssignments("RING", 2)
check(#ringAssignments == 2, "Hunter Phase 2 must assign two ring targets")
check(ringAssignments[1].id == 29997 and ringAssignments[2].id == 28791,
    "an equipped unique ring must keep its inventory position without duplicating the preview")
check(ringAssignments[1].id ~= ringAssignments[2].id, "paired ring previews must never duplicate one target")

equipped[13], equipped[14] = nil, 29383
local trinketAssignments = LP:GetPhaseTargetAssignments("TRINKET", 2)
check(trinketAssignments[1].id == 28830 and trinketAssignments[2].id == 29383,
    "equipped Bloodlust Brooch must be assigned to its real trinket slot")
check(not LP:IsTargetMet(trinketAssignments[1], 2, 13),
    "an empty trinket slot must not report Dragonspine Trophy as met")
check(LP:IsTargetMet(trinketAssignments[2], 2, 14),
    "equipped Bloodlust Brooch must report its own target as met")
check(not LP:IsTargetMet(trinketAssignments[1], 2, 14),
    "lower-ranked Bloodlust Brooch must not satisfy Dragonspine Trophy")
equipped[14] = 28830
check(LP:IsTargetMet(trinketAssignments[2], 2, 14),
    "higher-ranked Dragonspine Trophy may satisfy the Bloodlust Brooch target")
equipped[11], equipped[12], equipped[13], equipped[14] = nil, nil, nil, nil

LP.GetPlayerBuild = function() return "HUNTER", "Survival", nil end
LP:SetGuideOverride("Survival", "Marksmanship")
local manuallySelectedGuide, _, manualMode = LP:GetEmbeddedSpec("HUNTER", "Survival")
check(manuallySelectedGuide == "Marksmanship" and manualMode == "MANUAL", "spec picker selection must override the current talent guide")
LP:SetGuideOverride("Survival", nil)
equipped[11], equipped[12] = 29298, nil
local survivalRingAssignments = LP:GetPhaseTargetAssignments("RING", 2)
check(#survivalRingAssignments == 2, "Survival Phase 2 must assign two BIS ring targets")
check(survivalRingAssignments[1].id == 29298 and survivalRingAssignments[2].id == 28791,
    "equipped Band of Eternity must stay in its real slot beside Ring of the Recalcitrant")
check(LP:GetItemBISPhase(29298, "RING") == 2,
    "Band of Eternity must be recognised as Survival Phase 2 BIS in Reset mode")
check(LP:IsTargetMet(survivalRingAssignments[1], 2, 11),
    "equipped Band of Eternity must report its Phase 2 target as met")
equipped[11], equipped[12] = nil, nil
LP.GetPlayerBuild = originalGetPlayerBuild

local warlockAtieshOrders = {Affliction=4, Demonology=3, Destruction=3}
for warlockSpec, expectedOrder in pairs(warlockAtieshOrders) do
    LP.GetPlayerBuild = function() return "WARLOCK", warlockSpec, nil end
    local mainHandTargets = LP:GetPhasePrimaryTargets("MAINHAND", 2)
    check(mainHandTargets[1] and mainHandTargets[1].id == 32053,
        warlockSpec .. " Phase 2 preview must prefer the personal-DPS one-hand route over Atiesh")
    local atieshOrder
    for _, item in ipairs(LP:GetPhaseSlotItems("MAINHAND", 2, false)) do
        if item.id == 22630 then atieshOrder = item.listOrder end
    end
    check(atieshOrder == expectedOrder,
        warlockSpec .. " Atiesh must follow the stronger personal-DPS one-hand choices")
end
LP.GetPlayerBuild = originalGetPlayerBuild

local phaseTwoAtieshGuides = {
    {"DRUID", "Balance", 22632}, {"DRUID", "Restoration", 22632},
    {"MAGE", "Arcane", 22589}, {"MAGE", "Fire", 22589}, {"MAGE", "Frost", 22589},
    {"PRIEST", "Holy", 22631}, {"PRIEST", "Shadow", 22631},
    {"WARLOCK", "Affliction", 22630}, {"WARLOCK", "Demonology", 22630}, {"WARLOCK", "Destruction", 22630},
}
for _, guideCheck in ipairs(phaseTwoAtieshGuides) do
    local class, guideName, atieshID = unpack(guideCheck)
    LP.GetPlayerBuild = function() return class, guideName, nil end
    local phaseTwoMain = LP:GetPhasePrimaryTargets("MAINHAND", 2)[1]
    check(phaseTwoMain and phaseTwoMain.id ~= atieshID,
        class .. "/" .. guideName .. " Phase 2 must not present Atiesh as the default weapon")
end
LP.GetPlayerBuild = originalGetPlayerBuild

local actualGetPlayerBuild, actualGetEmbeddedSpec = LP.GetPlayerBuild, LP.GetEmbeddedSpec
local phasePlansChecked, phasePlanFailure = 0, nil
equipped[16], equipped[17] = nil, nil
for class, guides in pairs(LP.BIS_LISTS) do
    for guideName, guide in pairs(guides) do
        LP.GetPlayerBuild = function() return class, guideName, nil end
        LP.GetEmbeddedSpec = function() return guideName, guide, "TEST" end
        for phase = 0, 2 do
            phasePlansChecked = phasePlansChecked + 1
            local phasePlan = LP:GetModelPreviewPlan(phase)
            local hasTwoHand, hasOffHand = false, false
            for _, item in ipairs(phasePlan.items) do
                if item.slot == "MAINHAND" and item.bisSlot == "Two Hand" then hasTwoHand = true end
                if item.slot == "OFFHAND" then hasOffHand = true end
            end
            local displayedOffHand = LP:GetPhaseDisplayTarget("OFFHAND", phase, 1)
            if (hasTwoHand and hasOffHand) or (hasTwoHand and displayedOffHand) then
                phasePlanFailure = class .. "/" .. guideName .. "/phase " .. phase
                break
            end
        end
        if phasePlanFailure then break end
    end
    if phasePlanFailure then break end
end
check(phasePlansChecked == 75 and not phasePlanFailure,
    "all 75 guide-phase plans must prevent two-hand/off-hand conflicts: " .. tostring(phasePlanFailure))
LP.GetPlayerBuild, LP.GetEmbeddedSpec = actualGetPlayerBuild, actualGetEmbeddedSpec

local originalPrimaryTargets, originalSlots = LP.GetPhasePrimaryTargets, LP.SLOTS
LP.SLOTS = {
    {key="MAINHAND",label="Main hand",inventory=16},
    {key="OFFHAND",label="Off hand",inventory=17},
}
LP.GetPhasePrimaryTargets = function(_, slotKey)
    if slotKey == "MAINHAND" then return {{id=1001,slot="MAINHAND",bisSlot="Two Hand"}} end
    return {{id=1002,slot="OFFHAND",bisSlot="Off Hand"}}
end
local plan = LP:GetModelPreviewPlan(2)
check(#plan.items == 1 and plan.items[1].id == 1001, "two-handed phase preview must suppress off-hand target")
check(plan.clearOffHand, "two-handed phase preview must clear equipped off hand")
check(LP:GetPhaseDisplayTarget("OFFHAND", 2, 1) == nil, "two-handed phase layout must leave the off-hand gear slot empty")
local offhandPreview = LP:GetModelPreviewPlan(2, {id=1003,slot="OFFHAND",bisSlot="Off Hand"})
check(#offhandPreview.items == 1 and offhandPreview.items[1].id == 1003, "off-hand preview must replace conflicting two-hander")
check(offhandPreview.clearMainHand, "off-hand preview must clear the phase two-hander")
LP.GetPhasePrimaryTargets = function(_, slotKey)
    if slotKey == "MAINHAND" then return {{id=1004,slot="MAINHAND",bisSlot="Main Hand"}} end
    return {{id=1002,slot="OFFHAND",bisSlot="Off Hand"}}
end
check(LP:GetPhaseDisplayTarget("OFFHAND", 2, 1).id == 1002, "one-handed phase layout must retain its off-hand target")
LP.GetPhasePrimaryTargets, LP.SLOTS = originalPrimaryTargets, originalSlots

local testGuide = {
    [0] = {
        {9001,"Main Hand~Off Hand","BIS","Flexible Blade","Drop","Pathaleon","The Mechanar","B",2},
        {9002,"Off Hand","Alt","Owned Shield","Quest","A Test Quest","Netherstorm","B",1},
        {9003,"Off Hand","Alt","Alliance Shield","Drop","Pathaleon","The Mechanar","A",3},
    },
    [1] = {}, [2] = {},
}
LP.GetPlayerBuild = function() return "TEST", "Test", nil end
LP.GetEmbeddedSpec = function() return "Test", testGuide, "AUTO" end
LP.GetEffectiveRank = function(_, _, _, rank) return rank end
LP.SLOTS = {{key="OFFHAND",label="Off hand",inventory=17}}
LP.characterDB.completed["9002"] = true
names[9001], names[9002], names[9003] = "Flexible Blade", "Owned Shield", "Alliance Shield"
local offhandItems = LP:GetPhaseSlotItems("OFFHAND", 0, false)
check(#offhandItems == 2, "off-hand list must include flexible weapons and exclude wrong-faction items")
check(offhandItems[1].id == 9002 and offhandItems[2].id == 9001, "reviewed display order must override storage order")
LP.db.selectedSlot, LP.db.selectedSource = "OFFHAND", "ALL"
local recommendations = LP:GetRecommendations()
check(#recommendations == 2, "recommendations must include both eligible off-hand targets")
check(recommendations[1].id == 9001 and recommendations[2].id == 9002, "owned items must move below unowned items")
LP.db.selectedSource = "QUEST"
local questRecommendations = LP:GetRecommendations()
check(#questRecommendations == 1 and questRecommendations[1].id == 9002, "source filter must retain only matching recommendations")

if #failures > 0 then
    error("Engine tests failed (" .. #failures .. "/" .. checks .. "):\n - " .. table.concat(failures, "\n - "))
end
print("Engine behaviour valid: " .. checks .. " checks passed.")
