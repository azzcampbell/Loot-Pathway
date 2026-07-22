local root = arg[1] or "."
local failures, checks = {}, 0

local function check(condition, message)
    checks = checks + 1
    if not condition then table.insert(failures, message) end
end

SlashCmdList = {}
DEFAULT_CHAT_FRAME = {AddMessage=function() end}
UIParent = {}
function GetAddOnMetadata() return "test" end

local playerName, playerRealm = "Alpha", "Earth Strike"
function UnitFullName() return playerName, playerRealm end
function UnitName() return playerName end
function GetRealmName() return playerRealm end

local function loadCore(savedVariables)
    LootPathwayDB = savedVariables
    local addon, eventFrame = {}, nil
    function addon:CreateUI() self.frame = self.frame or {IsShown=function() return false end} end
    function addon:Refresh() self.refreshCount = (self.refreshCount or 0) + 1 end
    function addon:RefreshModel() self.modelRefreshCount = (self.modelRefreshCount or 0) + 1 end
    function addon:ToggleOptions() end
    function addon:RunSelfTests() end
    function CreateFrame()
        local frame = {events={}}
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:SetScript(kind, callback) self[kind] = callback end
        eventFrame = frame
        return frame
    end
    local chunk, reason = loadfile(root .. "/Core.lua")
    if not chunk then error(reason) end
    chunk("LootPathway", addon)
    eventFrame.OnEvent(eventFrame, "ADDON_LOADED", "LootPathway")
    eventFrame.OnEvent(eventFrame, "PLAYER_LOGIN")
    return addon, eventFrame
end

local fresh, freshEvents = loadCore(nil)
check(fresh.db.schemaVersion == 2, "fresh profile must use schema version 2")
check(fresh.characterKey == "Alpha-EarthStrike", "character key must normalise realm whitespace")
check(type(fresh.characterDB.completed) == "table", "fresh character completion table is missing")
fresh:ToggleItemCompleted(100)
check(fresh:IsItemCompleted(100), "fresh character ownership toggle did not persist")

fresh.frame = {shown=false}
function fresh.frame:IsShown() return self.shown end
function fresh.frame:Show() self.shown=true end
function fresh.frame:Hide() self.shown=false end
fresh.db.displayPhase, fresh.previewItem = 0, {id=999}
fresh.HideGuideMenu = function(self) self.guideMenuHidden=true end
local openRefreshBefore, openModelBefore = fresh.refreshCount or 0, fresh.modelRefreshCount or 0
fresh:Toggle()
check(fresh.frame:IsShown() and fresh.db.displayPhase == -1, "opening the addon must always start on Reset")
check(fresh.previewItem == nil and fresh.guideMenuHidden, "opening the addon must clear stale item and guide previews")
check((fresh.refreshCount or 0) == openRefreshBefore + 1 and (fresh.modelRefreshCount or 0) == openModelBefore + 1,
    "opening the addon must synchronise the equipped model and Reset gear display")
fresh:Toggle()
check(not fresh.frame:IsShown(), "toggling an open addon must close it")

playerName = "Beta"
fresh:ActivateCharacterProfile()
check(not fresh:IsItemCompleted(100), "ownership leaked between characters")
fresh:ToggleItemCompleted(200)
playerName = "Alpha"
fresh:ActivateCharacterProfile()
check(fresh:IsItemCompleted(100) and not fresh:IsItemCompleted(200), "returning character did not restore isolated ownership")
fresh.previewItem = {id=999}
local refreshBefore = fresh.refreshCount or 0
local modelBefore = fresh.modelRefreshCount or 0
freshEvents.OnEvent(freshEvents, "ACTIVE_TALENT_GROUP_CHANGED")
check(fresh.previewItem == nil, "dual-spec change did not clear stale item preview")
check((fresh.refreshCount or 0) == refreshBefore + 1 and (fresh.modelRefreshCount or 0) == modelBefore + 1, "dual-spec change did not refresh model and recommendations")

playerName, playerRealm = "Legacy", "Earth Strike"
local legacy = loadCore({schemaVersion=1, completed={['42']=true}, selectedSource="OTHER", scale=1})
check(legacy:IsItemCompleted(42), "legacy account ownership was not copied to the first character")
check(legacy.db.completed == nil, "legacy account-wide ownership table was not retired")
check(legacy.db.legacyCompletedMigratedTo == "Legacy-EarthStrike", "legacy migration destination was not recorded")
check(legacy.db.selectedSource == "ALL", "retired OTHER filter was not migrated")
check(legacy.db.scale >= 1.08 and legacy.db.uiScaleRevision == 1, "legacy UI scale migration was not applied")

playerName = "LegacyAlt"
legacy:ActivateCharacterProfile()
check(not legacy:IsItemCompleted(42), "migrated legacy ownership leaked to a second character")

playerName = "DungeonFilter"
local oldDungeonFilter = loadCore({schemaVersion=2, selectedSource="HEROIC", scale=1.08, uiScaleRevision=1})
check(oldDungeonFilter.db.selectedSource == "DUNGEON", "retired Heroic filter was not merged into Dungeon / Heroic")

if #failures > 0 then
    error("Core migration tests failed (" .. #failures .. "/" .. checks .. "):\n - " .. table.concat(failures, "\n - "))
end
print("Core profile migration valid: " .. checks .. " checks passed.")
