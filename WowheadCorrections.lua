local _, LP = ...

-- Reviewed additions from the current TBC Anniversary Phase 2 Wowhead guides.
-- These remain separate from generated BisData.lua so every post-Loon change
-- has an explicit source and can be re-audited when a guide is updated.
local corrections = {
    {
        class="DRUID", guide="Cat", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/druid/feral/dps-bis-gear-pve-phase-2",
        items={
            {30681,"Feet","Alt","Glider's Boots","Drop","Shadikith the Glider","Karazhan","B"},
            {30676,"Waist","Alt","Lurker's Grasp","Drop","Hyakiss the Lurker","Karazhan","B"},
            {30685,"Wrist","Alt","Ravager's Wrist-Wraps","Drop","Rokad the Ravager","Karazhan","B"},
        },
    },
    {
        class="HUNTER", guide="Survival", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/hunter/survival/dps-bis-gear-pve-phase-2",
        items={
            {30682,"Feet","BIS","Glider's Sabatons","Drop","Shadikith the Glider","Karazhan","B"},
            {30677,"Waist","BIS","Lurker's Belt","Drop","Hyakiss the Lurker","Karazhan","B"},
            {30686,"Wrist","BIS","Ravager's Bands","Drop","Rokad the Ravager","Karazhan","B"},
        },
    },
    {
        class="PRIEST", guide="Holy", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/priest/healer-bis-gear-pve-phase-2",
        items={
            {30680,"Feet","Alt","Glider's Foot-Wraps","Drop","Shadikith the Glider","Karazhan","B"},
            {25295,"Ranged/Relic","BIS","Flawless Wand","Drop","World Drop","","B"},
            {30684,"Wrist","BIS","Ravager's Cuffs","Drop","Rokad the Ravager","Karazhan","B"},
        },
    },
    {
        class="PRIEST", guide="Shadow", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/priest/shadow/dps-bis-gear-pve-phase-2",
        items={
            {25043,"Back","Alt","Amber Cape","Drop","World Drop","","B"},
            {31201,"Back","BIS","Illidari Cloak","Drop","Chief Engineer Lorthander","Netherstorm","B"},
            {30680,"Feet","BIS","Glider's Foot-Wraps","Drop","Shadikith the Glider","Karazhan","B"},
            {31166,"Hands","BIS","Nethersteel-Lined Handwraps","Drop","Speaker Mar'grom","Blade's Edge Mountains","B"},
            {25294,"Ranged/Relic","Alt","Dragonscale Wand","Drop","World Drop","","B"},
            {25295,"Ranged/Relic","Alt","Flawless Wand","Drop","World Drop","","B"},
            {30675,"Waist","BIS","Lurker's Cord","Drop","Hyakiss the Lurker","Karazhan","B"},
            {24692,"Wrist","Alt","Elementalist Bracelets","Drop","World Drop","","B"},
            {31225,"Wrist","BIS","Illidari Bindings","Drop","Ambassador Jerrikar","Shadowmoon Valley","B"},
            {30684,"Wrist","BIS","Ravager's Cuffs","Drop","Rokad the Ravager","Karazhan","B"},
        },
    },
    {
        class="SHAMAN", guide="Enhancement", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/shaman/enhancement/dps-bis-gear-pve-phase-2",
        items={
            {29947,"Hands","Alt","Gloves of the Searing Grip","Drop","Al'ar","Tempest Keep","B"},
            {30040,"Waist","BIS","Belt of Deep Shadow","Profession","Leatherworking (375)","36351","B"},
        },
    },
    {
        class="WARLOCK", guide="Affliction", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/warlock/affliction/dps-bis-gear-pve-phase-2",
        items={
            {30680,"Feet","Alt","Glider's Foot-Wraps","Drop","Shadikith the Glider","Karazhan","B"},
            {30675,"Waist","Alt","Lurker's Cord","Drop","Hyakiss the Lurker","Karazhan","B"},
            {24692,"Wrist","Alt","Elementalist Bracelets","Drop","World Drop","","B"},
            {30684,"Wrist","BIS","Ravager's Cuffs","Drop","Rokad the Ravager","Karazhan","B"},
        },
    },
    {
        class="WARLOCK", guide="Demonology", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/warlock/demonology/dps-bis-gear-pve-phase-2",
        items={
            {30680,"Feet","BIS","Glider's Foot-Wraps","Drop","Shadikith the Glider","Karazhan","B"},
            {30675,"Waist","Alt","Lurker's Cord","Drop","Hyakiss the Lurker","Karazhan","B"},
            {24692,"Wrist","Alt","Elementalist Bracelets","Drop","World Drop","","B"},
            {30684,"Wrist","BIS","Ravager's Cuffs","Drop","Rokad the Ravager","Karazhan","B"},
        },
    },
}

local slotCorrections = {
    {class="ROGUE",guide="Dps",phase=2,item=29151,from="Off Hand",to="Ranged/Relic",source="https://www.wowhead.com/tbc/guide/classes/rogue/dps-bis-gear-pve-phase-2"},
    {class="ROGUE",guide="Dps",phase=2,item=29152,from="Off Hand",to="Ranged/Relic",source="https://www.wowhead.com/tbc/guide/classes/rogue/dps-bis-gear-pve-phase-2"},
    {class="ROGUE",guide="Dps",phase=2,item=30724,from="Off Hand",to="Ranged/Relic",source="https://www.wowhead.com/tbc/guide/classes/rogue/dps-bis-gear-pve-phase-2"},
    {class="ROGUE",guide="Dps",phase=2,item=28772,from="Off Hand",to="Ranged/Relic",source="https://www.wowhead.com/tbc/guide/classes/rogue/dps-bis-gear-pve-phase-2"},
    {class="WARRIOR",guide="Arms",phase=2,item=32052,from="Main Hand~Off Hand",to="Off Hand",source="https://www.wowhead.com/tbc/guide/classes/warrior/arms/dps-bis-gear-pve-phase-2"},
    {class="WARRIOR",guide="Fury",phase=2,item=32052,from="Main Hand~Off Hand",to="Off Hand",source="https://www.wowhead.com/tbc/guide/classes/warrior/fury/dps-bis-gear-pve-phase-2"},
    {class="WARRIOR",guide="Fury",phase=2,item=29924,from="Main Hand~Off Hand",to="Off Hand",source="https://www.wowhead.com/tbc/guide/classes/warrior/fury/dps-bis-gear-pve-phase-2"},
    {class="WARRIOR",guide="Fury",phase=2,item=29996,from="Main Hand~Off Hand",to="Off Hand",source="https://www.wowhead.com/tbc/guide/classes/warrior/fury/dps-bis-gear-pve-phase-2"},
    {class="WARRIOR",guide="Fury",phase=2,item=30082,from="Main Hand~Off Hand",to="Off Hand",source="https://www.wowhead.com/tbc/guide/classes/warrior/fury/dps-bis-gear-pve-phase-2"},
}

LP.BIS_CORRECTION_META = {source="Wowhead TBC Anniversary",phase=2,reviewed="2026-07-22",groups=#corrections,slotCorrections=#slotCorrections}

local knownItems = {}
for _, classGuides in pairs(LP.BIS_LISTS or {}) do
    for _, phases in pairs(classGuides) do
        for _, entries in pairs(phases) do
            for _, entry in ipairs(entries) do knownItems[entry[1]] = true end
        end
    end
end

LP.BIS_CORRECTION_SOURCES = {}
for _, correction in ipairs(corrections) do
    local phaseEntries = LP.BIS_LISTS[correction.class][correction.guide][correction.phase]
    for _, item in ipairs(correction.items) do
        local exists = false
        for _, current in ipairs(phaseEntries) do
            if current[1] == item[1] and current[2] == item[2] then exists = true; break end
        end
        if not exists then
            table.insert(phaseEntries, item)
            LP.BIS_DATA_META.entries = LP.BIS_DATA_META.entries + 1
            if not knownItems[item[1]] then
                knownItems[item[1]] = true
                LP.BIS_DATA_META.uniqueItems = LP.BIS_DATA_META.uniqueItems + 1
            end
        end
        LP.BIS_CORRECTION_SOURCES[correction.class .. ":" .. correction.guide .. ":" .. correction.phase .. ":" .. item[1]] = correction.source
    end
end

for _, correction in ipairs(slotCorrections) do
    local phaseEntries = LP.BIS_LISTS[correction.class][correction.guide][correction.phase]
    for _, item in ipairs(phaseEntries) do
        if item[1] == correction.item and item[2] == correction.from then item[2] = correction.to end
    end
    LP.BIS_CORRECTION_SOURCES[correction.class .. ":" .. correction.guide .. ":" .. correction.phase .. ":" .. correction.item] = correction.source
end
