local root = arg[1] or "."
local failures, checks, messages = {}, 0, {}

local function check(condition, message)
    checks = checks + 1
    if not condition then table.insert(failures, message) end
end

local function loadAddonFile(name, addon)
    local chunk, reason = loadfile(root .. "/" .. name)
    if not chunk then error(reason) end
    chunk("LootPathway", addon)
end

function UnitClass() return "Warlock", "WARLOCK" end
function UnitFactionGroup() return "Horde" end
function GetActiveTalentGroup() return 1 end
function GetTalentTabInfo(index) return nil, nil, nil, nil, index == 3 and 41 or 0 end
function GetInventoryItemID() return nil end
function GetInventoryItemLink() return nil end
function GetItemInfo(item)
    local id = tonumber(item) or tonumber(string.match(item or "", "item:(%d+)"))
    return "Item " .. tostring(id), "item:" .. tostring(id), 4, 100,
        nil, nil, nil, nil, nil, "Interface\\Icons\\INV_Misc_QuestionMark"
end

local LP = {
    db={schemaVersion=2,selectedSource="ALL"},
    characterDB={completed={},guideOverrides={}},
    characterKey="Tester-Earthstrike",
}
function LP:GetCharacterKey() return "Tester-Earthstrike" end
function LP:IsItemCompleted(itemID) return self.characterDB.completed[tostring(itemID)] == true end
function LP:ToggleItemCompleted(itemID)
    local key = tostring(itemID)
    self.characterDB.completed[key] = not self.characterDB.completed[key] or nil
    return self.characterDB.completed[key] == true
end
function LP:Print(message) table.insert(messages, message) end

loadAddonFile("Data.lua", LP)
loadAddonFile("BisData.lua", LP)
loadAddonFile("WowheadCorrections.lua", LP)
loadAddonFile("DungeonDifficultyData.lua", LP)
loadAddonFile("Engine.lua", LP)
loadAddonFile("Diagnostics.lua", LP)

local ok, diagnosticFailures = LP:RunSelfTests()
check(ok and diagnosticFailures == nil, "the healthy runtime self-test must pass")
check(messages[#messages] == "Self-test passed: 122 checks across profiles, guides, sources and ownership.",
    "the runtime self-test count or success message changed unexpectedly: " .. tostring(messages[#messages]))

local previewKey = "WARLOCK:Destruction:2:MAINHAND"
local savedPreview = LP.BIS_PREVIEW_OVERRIDES[previewKey]
local orderKey = "WARLOCK:Destruction:2:22630"
local savedOrder = LP.BIS_DISPLAY_ORDER_OVERRIDES[orderKey]
LP.BIS_PREVIEW_OVERRIDES[previewKey] = nil
LP.BIS_DISPLAY_ORDER_OVERRIDES[orderKey] = nil
messages = {}
local brokenOK, brokenFailures = LP:RunSelfTests()
local detectedAtiesh = false
for _, failure in ipairs(brokenFailures or {}) do
    if failure == "Atiesh is incorrectly selected as the current Phase 2 default weapon" then detectedAtiesh = true end
end
LP.BIS_PREVIEW_OVERRIDES[previewKey] = savedPreview
LP.BIS_DISPLAY_ORDER_OVERRIDES[orderKey] = savedOrder
check(not brokenOK and detectedAtiesh, "the runtime self-test must detect the Atiesh preview regression")

if #failures > 0 then
    error("Diagnostics tests failed (" .. #failures .. "/" .. checks .. "):\n - " .. table.concat(failures, "\n - "))
end
print("Runtime diagnostics valid: " .. checks .. " checks passed, including the 122-check in-game self-test.")
