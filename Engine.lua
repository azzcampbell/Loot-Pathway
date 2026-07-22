local _, LP = ...

local SLOT_MAP = {
    ["Head"] = "HEAD", ["Neck"] = "NECK", ["Shoulder"] = "SHOULDER",
    ["Back"] = "BACK", ["Chest"] = "CHEST", ["Wrist"] = "WRIST",
    ["Hands"] = "HANDS", ["Waist"] = "WAIST", ["Legs"] = "LEGS",
    ["Feet"] = "FEET", ["Ring"] = "RING", ["Trinket"] = "TRINKET",
    ["Main Hand"] = "MAINHAND", ["Main Hand~Off Hand"] = "MAINHAND",
    ["Two Hand"] = "MAINHAND", ["Off Hand"] = "OFFHAND",
    ["Ranged/Relic"] = "RANGED",
}
LP.BIS_SLOT_MAP = SLOT_MAP

function LP:GetEffectiveEntrySlot(entrySlot, rank)
    if entrySlot ~= "Main Hand" then return entrySlot end
    local value = string.lower(tostring(rank or ""))
    local hasMain = string.find(value, "main hand", 1, true) or string.find(value, "main-hand", 1, true) or string.match(value, "%f[%a]mh%f[%A]")
    local hasOff = string.find(value, "off hand", 1, true) or string.find(value, "off-hand", 1, true) or string.match(value, "%f[%a]oh%f[%A]")
    if hasMain and hasOff then return "Main Hand~Off Hand" end
    if hasOff then return "Off Hand" end
    return entrySlot
end

function LP:EntryFitsSlot(entrySlot, slotKey, rank)
    entrySlot = self:GetEffectiveEntrySlot(entrySlot, rank)
    if entrySlot == "Main Hand~Off Hand" then
        return slotKey == "MAINHAND" or slotKey == "OFFHAND"
    end
    return SLOT_MAP[entrySlot] == slotKey
end

local RAID_ZONES = {
    "Karazhan", "Gruul's Lair", "Magtheridon's Lair", "Serpentshrine Cavern",
    "The Eye", "Tempest Keep", "Hyjal", "Black Temple", "Zul'Aman", "Sunwell",
}

local DUNGEON_ZONES = {
    "Hellfire Ramparts", "Blood Furnace", "Shattered Halls", "Slave Pens",
    "Underbog", "Steamvault", "Mana Tombs", "Mana-Tombs", "Auchenai Crypts",
    "Sethekk Halls", "Shadow Labyrinth", "Old Hillsbrad", "Black Morass",
    "Mechanar", "Botanica", "Arcatraz", "Magisters' Terrace",
}

local PHASE_LABELS = { [0] = "PRE-RAID", [1] = "PHASE 1", [2] = "PHASE 2" }

local function ContainsText(value, needles)
    value = string.lower(value or "")
    for _, needle in ipairs(needles) do
        if string.find(value, string.lower(needle), 1, true) then return true end
    end
    return false
end

local function ItemIDFromLink(link)
    return link and tonumber(string.match(link, "item:(%d+)")) or nil
end

function LP:GetPlayerBuild()
    local _, class = UnitClass("player")
    local tabs = self.SPECS[class]
    if not tabs then return class or "UNKNOWN", "Unknown", nil end

    local bestIndex, bestPoints = 1, -1
    local group = GetActiveTalentGroup and GetActiveTalentGroup() or 1
    for index = 1, 3 do
        local _, _, _, _, points = GetTalentTabInfo(index, false, false, group)
        if (points or 0) > bestPoints then bestIndex, bestPoints = index, points or 0 end
    end
    return class, tabs[bestIndex][1], tabs[bestIndex][2]
end

function LP:GetGuideOverride(talentSpec)
    local overrides = self.characterDB and self.characterDB.guideOverrides
    return overrides and overrides[talentSpec] or nil
end

function LP:SetGuideOverride(talentSpec, guideName)
    if not self.characterDB then self:ActivateCharacterProfile() end
    self.characterDB.guideOverrides[talentSpec] = guideName
    self.previewItem = nil
end

function LP:GetGuideChoices(class, talentSpec)
    local choices, seen = {}, {}
    local function add(guideName)
        if guideName and not seen[guideName] and self.BIS_LISTS[class] and self.BIS_LISTS[class][guideName] then
            seen[guideName] = true
            table.insert(choices, guideName)
        end
    end
    add(self.BIS_SPEC_MAP[class] and self.BIS_SPEC_MAP[class][talentSpec])
    local configured = self.BIS_GUIDE_CHOICES and self.BIS_GUIDE_CHOICES[class] and self.BIS_GUIDE_CHOICES[class][talentSpec]
    for _, guideName in ipairs(configured or {}) do add(guideName) end
    return choices
end

function LP:GetClassGuideChoices(class)
    local choices, seen = {}, {}
    local function add(guideName)
        if guideName and not seen[guideName] and self.BIS_LISTS[class] and self.BIS_LISTS[class][guideName] then
            seen[guideName] = true
            table.insert(choices, guideName)
        end
    end

    for _, specData in ipairs(self.SPECS[class] or {}) do
        local talentSpec = specData[1]
        add(self.BIS_SPEC_MAP[class] and self.BIS_SPEC_MAP[class][talentSpec])
        local configured = self.BIS_GUIDE_CHOICES and self.BIS_GUIDE_CHOICES[class] and self.BIS_GUIDE_CHOICES[class][talentSpec]
        for _, guideName in ipairs(configured or {}) do add(guideName) end
    end

    local remaining = {}
    for guideName in pairs(self.BIS_LISTS[class] or {}) do
        if not seen[guideName] then table.insert(remaining, guideName) end
    end
    table.sort(remaining)
    for _, guideName in ipairs(remaining) do add(guideName) end
    return choices
end

function LP:GetEmbeddedSpec(class, talentSpec)
    local automatic = self.BIS_SPEC_MAP[class] and self.BIS_SPEC_MAP[class][talentSpec]
    local override = self:GetGuideOverride(talentSpec)
    local selected = override and self.BIS_LISTS[class] and self.BIS_LISTS[class][override] and override or automatic
    return selected, selected and self.BIS_LISTS[class] and self.BIS_LISTS[class][selected], override and selected == override and "MANUAL" or "AUTO"
end

function LP:GetPhaseAugments(slotKey, phase)
    local class, talentSpec = self:GetPlayerBuild()
    local embeddedSpec = self:GetEmbeddedSpec(class, talentSpec)
    local specData = embeddedSpec and self.BIS_AUGMENTS and self.BIS_AUGMENTS[class] and self.BIS_AUGMENTS[class][embeddedSpec]
    if not specData then return {}, nil end

    local phaseData = specData[phase] or {}
    local baseData = specData[0] or {}
    local gems = (phaseData.gems and #phaseData.gems > 0) and phaseData.gems or (baseData.gems or {})
    local enchants = {}
    local function collect(source)
        for _, enchant in ipairs(source or {}) do
            local mapped = SLOT_MAP[enchant[2]]
            if mapped == slotKey or (slotKey == "OFFHAND" and enchant[2] == "Main Hand~Off Hand") then
                table.insert(enchants, enchant)
            end
        end
    end
    collect(phaseData.enchants)
    if phase ~= 0 then collect(baseData.enchants) end
    return gems, enchants[1]
end

function LP:GetEffectiveRank(phase, itemID, rank)
    local class, talentSpec = self:GetPlayerBuild()
    local embeddedSpec = self:GetEmbeddedSpec(class, talentSpec)
    local key = class .. ":" .. tostring(embeddedSpec or talentSpec) .. ":" .. tostring(phase) .. ":" .. tostring(itemID)
    return (self.BIS_RANK_OVERRIDES and self.BIS_RANK_OVERRIDES[key]) or rank or "Optional"
end

function LP:IsBestRank(rank)
    local value = string.lower(tostring(rank or ""))
    if string.find(value, "best until", 1, true) or string.find(value, "near best", 1, true) or
       string.find(value, "2nd best", 1, true) or string.find(value, "p1 best", 1, true) or
       string.find(value, "p1 bis", 1, true) or string.find(value, "pre%-?raid") or
       string.find(value, "pre raid", 1, true) then
        return false
    end
    return string.find(value, "bis", 1, true) ~= nil or string.sub(value, 1, 4) == "best"
end

function LP:GetRankTier(rank)
    if self:IsBestRank(rank) then return "BEST" end
    local value = string.lower(tostring(rank or ""))
    if string.find(value, "great", 1, true) or string.find(value, "strong", 1, true) or
       string.find(value, "alternative", 1, true) or string.find(value, "close second", 1, true) or
       string.find(value, "near best", 1, true) or string.find(value, "best until", 1, true) or
       string.find(value, "2nd best", 1, true) or string.find(value, "recommended", 1, true) then
        return "STRONG"
    end
    return "OPTION"
end

function LP:GetRankDisplayLabel(rank)
    local tierNumber = string.match(string.lower(tostring(rank or "")), "until tier%s*(%d+)")
    if tierNumber then return "UNTIL T" .. tierNumber end
    return self:GetRankTier(rank)
end

function LP:GetRankContextLabel(rank)
    local value = string.lower(tostring(rank or ""))
    local contexts = {
        {"personal dps", "PERSONAL"}, {"raid dps", "RAID DPS"}, {"raid support", "RAID SUPPORT"},
        {"mitigation", "MITIGATION"}, {"threat", "THREAT"}, {"hit cap", "HIT SET"}, {"hit set", "HIT SET"},
        {"set bonus", "SET BONUS"}, {"4p", "SET BONUS"}, {"2p", "SET BONUS"},
        {"pvp", "PVP"}, {"unrealistic", "UNREALISTIC"}, {"realistic", "REALISTIC"}, {"expensive", "EXPENSIVE"},
        {"demon", "DEMONS"}, {"undead", "UNDEAD"}, {"human", "HUMAN"}, {"orc", "ORC"},
        {"fast", "FAST"}, {"slow", "SLOW"},
    }
    for _, context in ipairs(contexts) do
        if string.find(value, context[1], 1, true) then return context[2] end
    end
    return nil
end

function LP:GetEffectiveDisplayOrder(phase, itemID, displayOrder)
    local class, talentSpec = self:GetPlayerBuild()
    local embeddedSpec = self:GetEmbeddedSpec(class, talentSpec)
    local key = class .. ":" .. tostring(embeddedSpec or talentSpec) .. ":" .. tostring(phase) .. ":" .. tostring(itemID)
    return (self.BIS_DISPLAY_ORDER_OVERRIDES and self.BIS_DISPLAY_ORDER_OVERRIDES[key]) or displayOrder
end

function LP:GetEquippedLevel(inventorySlot)
    if type(inventorySlot) == "table" then
        local lowestLevel, lowestLink
        for _, slotID in ipairs(inventorySlot) do
            local level, link = self:GetEquippedLevel(slotID)
            if lowestLevel == nil or level < lowestLevel then lowestLevel, lowestLink = level, link end
        end
        return lowestLevel or 0, lowestLink
    end
    local link = GetInventoryItemLink("player", inventorySlot)
    if not link then return 0, nil end
    return select(4, GetItemInfo(link)) or 0, link
end

function LP:GetSlot(slotKey)
    for _, slot in ipairs(self.SLOTS) do if slot.key == slotKey then return slot end end
end

function LP:GetEquippedIDs(slot)
    local ids, inventories = {}, type(slot.inventory) == "table" and slot.inventory or {slot.inventory}
    for _, inventory in ipairs(inventories) do
        local id = GetInventoryItemID and GetInventoryItemID("player", inventory)
        if not id then id = ItemIDFromLink(GetInventoryItemLink("player", inventory)) end
        if id then ids[id] = true end
    end
    return ids
end

function LP:ClassifySource(sourceType, source, location, itemID)
    local combined = (source or "") .. " " .. (location or "")
    if ContainsText(sourceType, {"quest"}) then return "QUEST" end
    if ContainsText(sourceType, {"profession", "craft"}) then return "CRAFTABLE" end
    if ContainsText(combined, RAID_ZONES) then return "RAID" end
    if ContainsText(location, {"(H)", "Heroic"}) or ContainsText(sourceType, {"Dungeon Token"}) then return "DUNGEON" end
    if ContainsText(combined, DUNGEON_ZONES) then return "DUNGEON" end
    return "OTHER"
end

function LP:GetDifficultySuffix(sourceType, source, location, itemID)
    local combined = (source or "") .. " " .. (location or "")
    if not ContainsText(combined, DUNGEON_ZONES) then return "" end
    local difficulty = self.DUNGEON_DIFFICULTY and self.DUNGEON_DIFFICULTY[itemID]
    if difficulty == "HEROIC" then return "(H)" end
    if difficulty == "BOTH" then return "(N) (H)" end
    if difficulty == "NORMAL" then return "(N)" end
    if ContainsText(combined, {"(H)", "Heroic"}) then return "(H)" end
    return "(?)"
end

function LP:GetListPosition(slotKey, guide)
    local slot = self:GetSlot(slotKey)
    if not slot or not guide then return -1, nil end
    local equipped = self:GetEquippedIDs(slot)
    local bestPhase, bestRank, bestIsBIS = -1, nil, false
    for phase = 0, (self.BIS_DATA_META.currentPhase or 2) do
        for _, entry in ipairs(guide[phase] or {}) do
            local rank = self:GetEffectiveRank(phase, entry[1], entry[3])
            if self:EntryFitsSlot(entry[2], slotKey, rank) and equipped[entry[1]] then
                local isBIS = self:IsBestRank(rank)
                if (isBIS and (not bestIsBIS or phase > bestPhase)) or (not bestIsBIS and phase > bestPhase) then
                    bestPhase, bestRank, bestIsBIS = phase, rank, isBIS
                end
            end
        end
    end
    return bestPhase, bestRank
end

function LP:GetInventoryListPosition(inventory, slotKey, guide)
    local link = GetInventoryItemLink("player", inventory)
    local itemID = (GetInventoryItemID and GetInventoryItemID("player", inventory)) or ItemIDFromLink(link)
    if not itemID or not guide then return -1, nil end
    local bestPhase, bestRank, bestOrder, bestIsBIS = -1, nil, nil, false
    for phase = 0, (self.BIS_DATA_META.currentPhase or 2) do
        for _, entry in ipairs(guide[phase] or {}) do
            local rank = self:GetEffectiveRank(phase, entry[1], entry[3])
            if entry[1] == itemID and self:EntryFitsSlot(entry[2], slotKey, rank) then
                local isBIS = self:IsBestRank(rank)
                if (isBIS and (not bestIsBIS or phase > bestPhase)) or (not bestIsBIS and phase > bestPhase) then
                    bestPhase, bestRank, bestOrder, bestIsBIS = phase, rank, entry[9], isBIS
                end
            end
        end
    end
    return bestPhase, bestRank, bestOrder
end

function LP:IsCurrentPhaseBIS(itemID, slotKey)
    return self:GetItemBISPhase(itemID, slotKey) == (self.BIS_DATA_META.currentPhase or 2)
end

function LP:GetItemBISPhase(itemID, slotKey)
    if not itemID then return nil end
    local class, talentSpec = self:GetPlayerBuild()
    local _, guide = self:GetEmbeddedSpec(class, talentSpec)
    local bestPhase
    for phase = 0, (self.BIS_DATA_META.currentPhase or 2) do
        for _, entry in ipairs(guide and guide[phase] or {}) do
            local rank = self:GetEffectiveRank(phase, entry[1], entry[3])
            if entry[1] == itemID and self:EntryFitsSlot(entry[2], slotKey, rank) and self:IsBestRank(rank) then bestPhase = phase end
        end
    end
    return bestPhase
end

function LP:GetBisItem(entry, phase, slot, equippedLevel)
    local itemID, bisSlot, rank, fallbackName, sourceType, source, location, _, displayOrder = unpack(entry)
    rank = self:GetEffectiveRank(phase, itemID, rank)
    bisSlot = self:GetEffectiveEntrySlot(bisSlot, rank)
    displayOrder = self:GetEffectiveDisplayOrder(phase, itemID, displayOrder)
    local name, link, quality, level, _, _, _, _, _, icon = GetItemInfo(itemID)
    local tier = self:ClassifySource(sourceType, source, location, itemID)
    return {
        id = itemID, name = name or fallbackName, link = link, quality = quality or 3,
        level = level or 0, icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
        slot = slot.key, slotLabel = slot.label, bisSlot = bisSlot,
        slotOrder = type(slot.inventory) == "table" and slot.inventory[1] or slot.inventory,
        tier = tier, sourceKind = self.TIERS[tier].short,
        sourceType = sourceType or "Other", boss = source or "", place = location or "",
        difficulty = self:GetDifficultySuffix(sourceType, source, location, itemID),
        listRank = rank or "Alt", phase = phase, phaseLabel = PHASE_LABELS[phase],
        rankContext = self:GetRankContextLabel(rank),
        displayOrder = displayOrder,
        equippedLevel = equippedLevel or 0,
        completed = self:IsItemCompleted(itemID),
    }
end

local function IsFactionMatch(entryFaction, playerFaction)
    if not entryFaction or entryFaction == "B" then return true end
    if playerFaction == "Alliance" then return entryFaction == "A" end
    if playerFaction == "Horde" then return entryFaction == "H" end
    return true
end

function LP:GetPhaseSlotItems(slotKey, phase, applySourceFilter)
    local class, talentSpec = self:GetPlayerBuild()
    local embeddedSpec, guide = self:GetEmbeddedSpec(class, talentSpec)
    local slot = self:GetSlot(slotKey)
    local results = {}
    if not guide or not slot then return results, talentSpec, embeddedSpec end

    local equippedLevel = self:GetEquippedLevel(slot.inventory)
    local playerFaction = UnitFactionGroup and UnitFactionGroup("player") or nil
    local sourceFilter = self.db.selectedSource or "ALL"
    for listOrder, entry in ipairs(guide[phase] or {}) do
        local effectiveRank = self:GetEffectiveRank(phase, entry[1], entry[3])
        if self:EntryFitsSlot(entry[2], slotKey, effectiveRank) and IsFactionMatch(entry[8], playerFaction) then
            local item = self:GetBisItem(entry, phase, slot, equippedLevel)
            item.listOrder = item.displayOrder or listOrder
            if not applySourceFilter or sourceFilter == "ALL" or item.tier == sourceFilter then
                table.insert(results, item)
            end
        end
    end
    table.sort(results, function(a, b)
        if (a.listOrder or 9999) ~= (b.listOrder or 9999) then
            return (a.listOrder or 9999) < (b.listOrder or 9999)
        end
        return a.name < b.name
    end)
    return results, talentSpec, embeddedSpec
end

function LP:GetPhasePrimaryTargets(slotKey, phase)
    local items = self:GetPhaseSlotItems(slotKey, phase, false)
    local primary, fallback, seen = {}, {}, {}
    for _, item in ipairs(items) do
        if not seen[item.id] then
            seen[item.id] = true
            if self:IsBestRank(item.listRank) then table.insert(primary, item)
            else table.insert(fallback, item) end
        end
    end
    if #primary == 0 then primary = fallback end
    local class, talentSpec = self:GetPlayerBuild()
    local embeddedSpec = self:GetEmbeddedSpec(class, talentSpec)
    local previewKey = class .. ":" .. tostring(embeddedSpec or talentSpec) .. ":" .. tostring(phase) .. ":" .. tostring(slotKey)
    local preferredID = self.BIS_PREVIEW_OVERRIDES and self.BIS_PREVIEW_OVERRIDES[previewKey]
    if preferredID then
        for index, item in ipairs(primary) do
            if item.id == preferredID then
                table.remove(primary, index)
                table.insert(primary, 1, item)
                break
            end
        end
    end
    return primary
end

function LP:GetPhaseTargetAssignments(slotKey, phase)
    local slot = self:GetSlot(slotKey)
    local targets = self:GetPhasePrimaryTargets(slotKey, phase)
    if not slot then return {} end

    local inventories = type(slot.inventory) == "table" and slot.inventory or {slot.inventory}
    local assignments, used = {}, {}

    -- Paired slots should keep an exact equipped target in its real inventory
    -- position. This prevents one ring or trinket from satisfying both previews.
    for ordinal, inventory in ipairs(inventories) do
        local link = GetInventoryItemLink("player", inventory)
        local equippedID = (GetInventoryItemID and GetInventoryItemID("player", inventory)) or ItemIDFromLink(link)
        if equippedID then
            for targetIndex, target in ipairs(targets) do
                if not used[targetIndex] and target.id == equippedID then
                    assignments[ordinal], used[targetIndex] = target, true
                    break
                end
            end
        end
    end

    local nextTarget = 1
    for ordinal = 1, #inventories do
        if not assignments[ordinal] then
            while nextTarget <= #targets and used[nextTarget] do nextTarget = nextTarget + 1 end
            if nextTarget <= #targets then
                assignments[ordinal], used[nextTarget] = targets[nextTarget], true
                nextTarget = nextTarget + 1
            end
        end
    end
    return assignments
end

function LP:GetPhaseDisplayTarget(slotKey, phase, ordinal)
    if slotKey == "OFFHAND" then
        local mainHandTarget = self:GetPhaseTargetAssignments("MAINHAND", phase)[1]
        if mainHandTarget and mainHandTarget.bisSlot == "Two Hand" then return nil end
    end
    return self:GetPhaseTargetAssignments(slotKey, phase)[ordinal or 1]
end

function LP:GetModelPreviewPlan(phase, previewItem)
    local plan = {items={}, clearMainHand=false, clearOffHand=false}
    local phaseUsesTwoHand = false
    phase = tonumber(phase) or -1

    if phase >= 0 then
        for _, slot in ipairs(self.SLOTS or {}) do
            if slot.key ~= "OFFHAND" or not phaseUsesTwoHand then
                local targets = self:GetPhaseTargetAssignments(slot.key, phase)
                local inventories = type(slot.inventory) == "table" and slot.inventory or {slot.inventory}
                for ordinal = 1, #inventories do
                    local target = targets[ordinal]
                    if target then
                        target.previewInventory = inventories[ordinal]
                        table.insert(plan.items, target)
                        if slot.key == "MAINHAND" and target.bisSlot == "Two Hand" then
                            phaseUsesTwoHand = true
                            plan.clearOffHand = true
                        end
                    end
                end
            end
        end
    end

    if previewItem then
        for index = #plan.items, 1, -1 do
            local current = plan.items[index]
            if current.slot == previewItem.slot or
               (previewItem.slot == "MAINHAND" and previewItem.bisSlot == "Two Hand" and current.slot == "OFFHAND") or
               (previewItem.slot == "OFFHAND" and current.slot == "MAINHAND" and current.bisSlot == "Two Hand") then
                table.remove(plan.items, index)
            end
        end
        if previewItem.slot == "MAINHAND" and previewItem.bisSlot == "Two Hand" then plan.clearOffHand = true end
        if previewItem.slot == "OFFHAND" and phaseUsesTwoHand then plan.clearMainHand = true end
        table.insert(plan.items, previewItem)
    end

    return plan
end

function LP:IsTargetMet(target, phase, inventory)
    if not target then return false end
    local slot = self:GetSlot(target.slot)
    if not slot then return false end
    local link = inventory and GetInventoryItemLink("player", inventory)
    local equippedID = inventory and ((GetInventoryItemID and GetInventoryItemID("player", inventory)) or ItemIDFromLink(link))
    if equippedID == target.id then return true, "This guide item is equipped." end
    if self:GetEquippedIDs(slot)[target.id] then return true, "This guide item is equipped." end
    return false, nil
end

function LP:GetRecommendations()
    local class, talentSpec = self:GetPlayerBuild()
    local embeddedSpec, guide = self:GetEmbeddedSpec(class, talentSpec)
    local selectedSlot, selectedSource = self.db.selectedSlot, self.db.selectedSource or "ALL"
    local currentPhase = self.BIS_DATA_META.currentPhase or 2
    local playerFaction = UnitFactionGroup and UnitFactionGroup("player") or nil
    local results, positions = {}, {}

    if not guide then return results, talentSpec, nil, positions end

    for _, slot in ipairs(self.SLOTS) do
        if selectedSlot == "ALL" or selectedSlot == slot.key then
            local equippedLevel = self:GetEquippedLevel(slot.inventory)
            local equippedIDs = self:GetEquippedIDs(slot)
            local positionPhase, positionRank = self:GetListPosition(slot.key, guide)
            positions[slot.key] = { phase = positionPhase, rank = positionRank }
            for phase = 0, currentPhase do
                local samePhase = phase == positionPhase
                local includePhase = positionPhase < 0 or phase > positionPhase or samePhase
                local onlyBIS = samePhase
                if includePhase then
                    for listOrder, entry in ipairs(guide[phase] or {}) do
                        local effectiveRank = self:GetEffectiveRank(phase, entry[1], entry[3])
                        if self:EntryFitsSlot(entry[2], slot.key, effectiveRank) and not equippedIDs[entry[1]] and IsFactionMatch(entry[8], playerFaction) then
                            local isBIS = self:IsBestRank(effectiveRank)
                            if not onlyBIS or isBIS then
                                local item = self:GetBisItem(entry, phase, slot, equippedLevel)
                                item.listOrder = item.displayOrder or listOrder
                                if selectedSource == "ALL" or item.tier == selectedSource then
                                    table.insert(results, item)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(results, function(a, b)
        if a.phase ~= b.phase then return a.phase < b.phase end
        if a.slotOrder ~= b.slotOrder then return a.slotOrder < b.slotOrder end
        if a.completed ~= b.completed then return not a.completed end
        if (a.listOrder or 9999) ~= (b.listOrder or 9999) then
            return (a.listOrder or 9999) < (b.listOrder or 9999)
        end
        return a.name < b.name
    end)

    if selectedSlot == "ALL" then
        local seen, compact = {}, {}
        for _, item in ipairs(results) do
            if not seen[item.slot] then seen[item.slot] = true; table.insert(compact, item) end
        end
        results = compact
    end
    return results, talentSpec, embeddedSpec, positions
end
