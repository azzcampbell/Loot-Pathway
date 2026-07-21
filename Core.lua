local ADDON_NAME, LP = ...

LootPathway = LP
LP.name = ADDON_NAME
LP.version = "0.4.4"

local defaults = {
    minimised = false,
    locked = false,
    scale = 1,
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
    completed = {},
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
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show(); self:Refresh() end
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
    elseif input == "help" then
        LP:Print("/lpw - toggle  |  /lpw options  |  /lpw refresh  |  /lpw reset")
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
        CopyDefaults(defaults, LootPathwayDB)
        LP.db = LootPathwayDB
    elseif event == "PLAYER_LOGIN" then
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
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        if LP.frame and LP.frame:IsShown() then LP:Refresh() end
    elseif LP.frame then
        LP:Refresh()
    end
end)
