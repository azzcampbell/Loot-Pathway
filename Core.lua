local ADDON_NAME, LP = ...

LootPathway = LP
LP.name = ADDON_NAME
LP.version = (GetAddOnMetadata and GetAddOnMetadata(ADDON_NAME, "Version")) or "dev"

local defaults = {
    schemaVersion = 2,
    characters = {},
    minimised = false,
    locked = false,
    scale = 1.08,
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 12,
    selectedSlot = "ALL",
    selectedSource = "ALL",
    modelFacing = 0,
    minimapAngle = 0,
    displayPhase = -1,
    minimapHidden = false,
    showOwned = false,
    collapsedPhases = {},
}

local characterDefaults = {
    completed = {},
    guideOverrides = {},
}

local function CopyDefaults(source, target)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function CopyTable(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = type(value) == "table" and CopyTable(value) or value
    end
    return result
end

function LP:GetCharacterKey()
    local name, realm
    if UnitFullName then name, realm = UnitFullName("player") end
    name = name or (UnitName and UnitName("player")) or "Unknown"
    realm = realm or (GetRealmName and GetRealmName()) or "UnknownRealm"
    realm = tostring(realm):gsub("%s+", "")
    return tostring(name) .. "-" .. realm
end

function LP:ActivateCharacterProfile()
    local key = self:GetCharacterKey()
    self.db.characters = self.db.characters or {}
    self.db.characters[key] = self.db.characters[key] or {}
    CopyDefaults(characterDefaults, self.db.characters[key])
    self.characterKey = key
    self.characterDB = self.db.characters[key]

    if self.pendingLegacyCompleted then
        if not next(self.characterDB.completed) then
            self.characterDB.completed = CopyTable(self.pendingLegacyCompleted)
        end
        self.db.legacyCompletedMigratedTo = key
        self.pendingLegacyCompleted = nil
    end
end

function LP:GetCompletedItems()
    return (self.characterDB and self.characterDB.completed) or {}
end

function LP:IsItemCompleted(itemID)
    return self:GetCompletedItems()[tostring(itemID)] == true
end

function LP:ToggleItemCompleted(itemID)
    if not self.characterDB then self:ActivateCharacterProfile() end
    local key = tostring(itemID)
    self.characterDB.completed[key] = not self.characterDB.completed[key]
    return self.characterDB.completed[key]
end

function LP:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffd6b56dLoot Pathway|r  " .. tostring(message))
end

function LP:SavePosition()
    if not self.frame then return end
    local point, _, relativePoint, x, y = self.frame:GetPoint(1)
    self.db.point, self.db.relativePoint, self.db.x, self.db.y = point, relativePoint, x, y
end

function LP:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.db.displayPhase = -1
        self.previewItem = nil
        if self.HideGuideMenu then self:HideGuideMenu() end
        self.frame:Show()
        self:RefreshModel()
        self:Refresh()
    end
end

function LP:ResetPosition()
    self.db.point, self.db.relativePoint, self.db.x, self.db.y = "CENTER", "CENTER", 0, 12
    if self.frame then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 12)
    end
    self:Print("Window position reset.")
end

SLASH_LOOTPATHWAY1 = "/lootpathway"
SLASH_LOOTPATHWAY2 = "/lpw"
SlashCmdList.LOOTPATHWAY = function(input)
    input = string.lower((input or ""):match("^%s*(.-)%s*$"))
    if input == "reset" then
        LP:ResetPosition()
    elseif input == "options" then
        LP:ToggleOptions()
    elseif input == "refresh" then
        LP:Refresh(true)
        LP:Print("Gear and recommendations refreshed.")
    elseif input == "selftest" then
        LP:RunSelfTests()
    elseif input == "help" then
        LP:Print("/lpw - toggle  |  /lpw options  |  /lpw refresh  |  /lpw selftest  |  /lpw reset")
    else
        LP:Toggle()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("PLAYER_TALENT_UPDATE")
events:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        LootPathwayDB = LootPathwayDB or {}
        local previousSchemaVersion = tonumber(LootPathwayDB.schemaVersion) or 1
        local legacyCompleted = type(LootPathwayDB.completed) == "table" and CopyTable(LootPathwayDB.completed) or nil
        local previousScaleRevision = LootPathwayDB.uiScaleRevision
        CopyDefaults(defaults, LootPathwayDB)
        if previousSchemaVersion < 2 and legacyCompleted and next(legacyCompleted) then
            LP.pendingLegacyCompleted = legacyCompleted
        end
        LootPathwayDB.completed = nil
        LootPathwayDB.schemaVersion = 2
        if not previousScaleRevision then
            LootPathwayDB.scale = math.max(tonumber(LootPathwayDB.scale) or 1, 1.08)
            LootPathwayDB.uiScaleRevision = 1
        end
        if LootPathwayDB.selectedSource == "NORMAL" or LootPathwayDB.selectedSource == "HEROIC" then
            LootPathwayDB.selectedSource = "DUNGEON"
        elseif LootPathwayDB.selectedSource == "OTHER" then
            LootPathwayDB.selectedSource = "ALL"
        end
        LP.db = LootPathwayDB
    elseif event == "PLAYER_LOGIN" then
        LP:ActivateCharacterProfile()
        LP:CreateUI()
        LP:Refresh()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if C_Timer and C_Timer.After then
            C_Timer.After(0.2, function() if LP.frame then LP:RefreshModel(); LP:Refresh() end end)
        elseif LP.frame then
            LP:RefreshModel()
            LP:Refresh()
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        LP:RefreshModel()
        LP:Refresh()
    elseif event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        LP.previewItem = nil
        LP:RefreshModel()
        LP:Refresh()
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        if LP.frame and LP.frame:IsShown() then LP:Refresh() end
    elseif LP.frame then
        LP:Refresh()
    end
end)
