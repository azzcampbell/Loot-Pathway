local _, LP = ...

local function CountKeys(value)
    local count = 0
    for _ in pairs(value or {}) do count = count + 1 end
    return count
end

function LP:RunSelfTests()
    local passed, failures = 0, {}
    local function check(condition, message)
        if condition then passed = passed + 1 else table.insert(failures, message) end
    end

    check(self.db and self.db.schemaVersion == 2, "SavedVariables schema is not version 2")
    check(self.characterDB and type(self.characterDB.completed) == "table", "character completion profile is unavailable")
    check(self.characterDB and type(self.characterDB.guideOverrides) == "table", "character guide overrides are unavailable")
    check(self.characterKey == self:GetCharacterKey(), "active character key is stale")
    check(self.BIS_DATA_META and self.BIS_DATA_META.currentPhase == 2, "current BIS phase metadata is invalid")

    local guideCount = 0
    for class, guides in pairs(self.BIS_LISTS or {}) do
        for guideName, phases in pairs(guides) do
            guideCount = guideCount + 1
            for phase = 0, self.BIS_DATA_META.currentPhase do
                check(type(phases[phase]) == "table" and #phases[phase] > 0, class .. "/" .. guideName .. " phase " .. phase .. " is empty")
            end
        end
    end
    check(guideCount == 25, "expected 25 embedded guides, found " .. guideCount)
    check(CountKeys(self.BIS_LISTS) == 9, "expected BIS data for 9 classes")

    for class, guides in pairs(self.BIS_LISTS or {}) do
        local reachable = {}
        for _, guideName in ipairs(self:GetClassGuideChoices(class)) do reachable[guideName] = true end
        local missing = {}
        for guideName in pairs(guides) do
            if not reachable[guideName] then table.insert(missing, guideName) end
        end
        table.sort(missing)
        check(#missing == 0, class .. " picker cannot reach: " .. table.concat(missing, ", "))
    end

    local playerClass, playerSpec = self:GetPlayerBuild()
    local selectedGuide, playerGuide = self:GetEmbeddedSpec(playerClass, playerSpec)
    check(selectedGuide and type(playerGuide) == "table", "current character does not resolve to a selectable BIS guide")

    local phaseTwoPlan = self:GetModelPreviewPlan(self.BIS_DATA_META.currentPhase)
    local planHasTwoHand, planHasOffHand = false, false
    for _, item in ipairs(phaseTwoPlan.items or {}) do
        if item.slot == "MAINHAND" and item.bisSlot == "Two Hand" then planHasTwoHand = true end
        if item.slot == "OFFHAND" then planHasOffHand = true end
    end
    check(not (planHasTwoHand and planHasOffHand), "current Phase 2 preview combines a two-hander with an off hand")

    local atieshByClass = {DRUID=22632, MAGE=22589, PRIEST=22631, WARLOCK=22630}
    local phaseTwoMain = self:GetPhasePrimaryTargets("MAINHAND", self.BIS_DATA_META.currentPhase)[1]
    check(not atieshByClass[playerClass] or not phaseTwoMain or phaseTwoMain.id ~= atieshByClass[playerClass],
        "Atiesh is incorrectly selected as the current Phase 2 default weapon")

    local druidChoices = self:GetGuideChoices("DRUID", "Feral Combat")
    local hasCat, hasBear = false, false
    for _, guideName in ipairs(druidChoices) do
        if guideName == "Cat" then hasCat = true end
        if guideName == "Bear" then hasBear = true end
    end
    check(hasCat and hasBear, "Feral Cat and Bear guides are not both selectable")

    check(self:ClassifySource("Quest", "Example", "Shadowmoon Valley") == "QUEST", "quest source classification failed")
    check(self:ClassifySource("Profession", "Tailoring", "375") == "CRAFTABLE", "craftable source classification failed")
    check(self:ClassifySource("Drop", "Prince Malchezaar", "Karazhan") == "RAID", "raid source classification failed")
    check(self:ClassifySource("Drop", "Quagmirran", "The Slave Pens (H)") == "HEROIC", "heroic source classification failed")
    check(self:ClassifySource("Drop", "Pathaleon", "The Mechanar") == "NORMAL", "normal dungeon source classification failed")
    check(self:GetDifficultySuffix("Drop", "Quagmirran", "The Slave Pens (H)") == "(H)", "heroic difficulty suffix failed")
    check(self:GetDifficultySuffix("Drop", "Pathaleon", "The Mechanar") == "(N) (H)", "normal/heroic difficulty suffix failed")
    check(self:EntryFitsSlot("Main Hand~Off Hand", "MAINHAND"), "flexible weapon did not match main hand")
    check(self:EntryFitsSlot("Main Hand~Off Hand", "OFFHAND"), "flexible weapon did not match off hand")
    check(not self:EntryFitsSlot("Main Hand", "OFFHAND"), "main-hand-only weapon incorrectly matched off hand")

    local testItem = 2147483647
    local previous = self.characterDB.completed[tostring(testItem)]
    self.characterDB.completed[tostring(testItem)] = nil
    check(not self:IsItemCompleted(testItem), "unowned item was reported as owned")
    check(self:ToggleItemCompleted(testItem) and self:IsItemCompleted(testItem), "owned-item toggle did not persist")
    check(not self:ToggleItemCompleted(testItem) and not self:IsItemCompleted(testItem), "owned-item toggle did not clear")
    self.characterDB.completed[tostring(testItem)] = previous

    if #failures == 0 then
        self:Print("Self-test passed: " .. passed .. " checks across profiles, guides, sources and ownership.")
        return true
    end

    self:Print("Self-test failed: " .. #failures .. " issue" .. (#failures == 1 and "" or "s") .. ".")
    for _, failure in ipairs(failures) do self:Print("FAIL - " .. failure) end
    return false, failures
end
