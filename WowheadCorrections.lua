local _, LP = ...

-- Reviewed additions and narrow removals from the current TBC Anniversary
-- Pre-Raid, Phase 1 and Phase 2 Wowhead guides.
-- These remain separate from generated BisData.lua so every reviewed change
-- has an explicit source and can be re-audited when a guide is updated.
local corrections = {
    {
        class="DRUID", guide="Cat", phase=1,
        source="https://www.wowhead.com/tbc/guide/feral-druid-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow",
        items={
            {30676,"Waist","Best Hit Set (Unrealistic)","Lurker's Grasp","Drop","Hyakiss the Lurker","Karazhan","B",2},
            {30685,"Wrist","Alternative (unrealistic)","Ravager's Wrist-Wraps","Drop","Rokad the Ravager","Karazhan","B",2},
        },
    },
    {
        class="HUNTER", guide="Survival", phase=1,
        source="https://www.wowhead.com/tbc/guide/survival-hunter-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow",
        items={
            {30682,"Feet","Best","Glider's Sabatons","Drop","Shadikith the Glider","Karazhan","B",1},
            {30677,"Waist","Best","Lurker's Belt","Drop","Hyakiss the Lurker","Karazhan","B",1},
            {30686,"Wrist","Best","Ravager's Bands","Drop","Rokad the Ravager","Karazhan","B",1},
        },
    },
    {
        class="MAGE", guide="Arcane", phase=1,
        source="https://www.wowhead.com/tbc/guide/arcane-mage-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow",
        items={
            {29333,"Neck","Option","Torc of the Sethekk Prophet","Quest","Brother Against Brother","Sethekk Halls","B",6},
        },
    },
    {
        class="WARLOCK", guide="Affliction", phase=1,
        source="https://www.wowhead.com/tbc/guide/affliction-warlock-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow",
        items={
            {24692,"Wrist","Option","Elementalist Bracelets","Drop","World Drop","","B",2},
        },
    },
    {
        class="WARLOCK", guide="Demonology", phase=1,
        source="https://www.wowhead.com/tbc/guide/demonology-warlock-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow",
        items={
            {24692,"Wrist","Alternative","Elementalist Bracelets","Drop","World Drop","","B",2},
        },
    },
    {
        class="WARRIOR", guide="Fury", phase=1,
        source="https://www.wowhead.com/tbc/guide/fury-warrior-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow",
        items={
            {24544,"Chest","Great","Gladiator's Plate Chestpiece","PvP","Arena Points","Arena Vendor","B",3},
            {29020,"Hands","Hit Alternative","Warbringer Gauntlets","Tier Token","The Curator","Karazhan","B",3},
            {30538,"Legs","Best Pre-raid","Midnight Legguards","Drop","Quagmirran","The Slave Pens (H)","B",4},
            {28584,"Main Hand","Alternative","Big Bad Wolf's Paw","Drop","Opera Event (Wolf)","Karazhan","B",5},
            {28657,"Main Hand","Alternative","Fool's Bane","Drop","Terestian Illhoof","Karazhan","B",3},
            {29348,"Main Hand","Alternative","The Bladefist","Drop","Warchief Kargath Bladefist","The Shattered Halls (H)","B",2},
            {28767,"Main Hand","Alternative","The Decapitator","Drop","Prince Malchezaar","Karazhan","B",4},
            {23542,"Off Hand","Orc Alternative","Fel Edged Battleaxe","Profession","Blacksmithing (365)","29694","B",1},
            {28649,"Ring","Hit Alternative","Garona's Signet Ring","Drop","The Curator","Karazhan","B",6},
        },
    },
    {
        class="MAGE", guide="Arcane", phase=0,
        source="https://www.wowhead.com/tbc/guide/classes/mage/arcane/dps-bis-gear-pve-pre-raid",
        items={
            {27540,"Ranged/Relic","Option","Nexus Torch","Drop","Warchief Kargath Bladefist","The Shattered Halls","B",4},
        },
    },
    {
        class="SHAMAN", guide="Elemental", phase=0,
        source="https://www.wowhead.com/tbc/guide/classes/shaman/elemental/dps-bis-gear-pve-pre-raid",
        items={
            {31201,"Back","Option","Illidari Cloak","Drop","World Drop","","B",2},
        },
    },
    {
        class="DRUID", guide="Cat", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/druid/feral/dps-bis-gear-pve-phase-2",
        items={
            {30681,"Feet","Option","Glider's Boots","Drop","Shadikith the Glider","Karazhan","B",5},
            {30676,"Waist","Option","Lurker's Grasp","Drop","Hyakiss the Lurker","Karazhan","B",4},
            {30685,"Wrist","Option","Ravager's Wrist-Wraps","Drop","Rokad the Ravager","Karazhan","B",2},
        },
    },
    {
        class="HUNTER", guide="Survival", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/hunter/survival/dps-bis-gear-pve-phase-2",
        items={
            {30682,"Feet","Best Raid Wide Increase","Glider's Sabatons","Drop","Shadikith the Glider","Karazhan","B",3},
            {30677,"Waist","Best Raid Wide Increase","Lurker's Belt","Drop","Hyakiss the Lurker","Karazhan","B",2},
            {30686,"Wrist","Best Raid Wide Increase","Ravager's Bands","Drop","Rokad the Ravager","Karazhan","B",2},
        },
    },
    {
        class="PRIEST", guide="Holy", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/priest/healer-bis-gear-pve-phase-2",
        items={
            {30680,"Feet","Viable","Glider's Foot-Wraps","Drop","Shadikith the Glider","Karazhan","B",5},
            {25295,"Ranged/Relic","BiS","Flawless Wand","Drop","World Drop","","B",3},
            {30684,"Wrist","Throughput BiS","Ravager's Cuffs","Drop","Rokad the Ravager","Karazhan","B",5},
        },
    },
    {
        class="PRIEST", guide="Shadow", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/priest/shadow/dps-bis-gear-pve-phase-2",
        items={
            {25043,"Back","Option","Amber Cape","Drop","World Drop","","B",3},
            {31201,"Back","BiS","Illidari Cloak","Drop","Chief Engineer Lorthander","Netherstorm","B",1},
            {30680,"Feet","BiS - Servant's Quarters","Glider's Foot-Wraps","Drop","Shadikith the Glider","Karazhan","B",1},
            {31166,"Hands","BiS","Nethersteel-Lined Handwraps","Drop","Speaker Mar'grom","Blade's Edge Mountains","B",1},
            {25294,"Ranged/Relic","Option","Dragonscale Wand","Drop","World Drop","","B",4},
            {25295,"Ranged/Relic","Option","Flawless Wand","Drop","World Drop","","B",3},
            {30675,"Waist","BiS - Servant's Quarters","Lurker's Cord","Drop","Hyakiss the Lurker","Karazhan","B",1},
            {24692,"Wrist","Option","Elementalist Bracelets","Drop","World Drop","","B",3},
            {31225,"Wrist","BiS","Illidari Bindings","Drop","Ambassador Jerrikar","Shadowmoon Valley","B",2},
            {30684,"Wrist","BiS - Servant's Quarters","Ravager's Cuffs","Drop","Rokad the Ravager","Karazhan","B",1},
        },
    },
    {
        class="SHAMAN", guide="Enhancement", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/shaman/enhancement/dps-bis-gear-pve-phase-2",
        items={
            {29947,"Hands","Great","Gloves of the Searing Grip","Drop","Al'ar","Tempest Keep","B",2},
            {30040,"Waist","Best","Belt of Deep Shadow","Profession","Leatherworking (375)","36351","B",2},
        },
    },
    {
        class="WARLOCK", guide="Affliction", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/warlock/affliction/dps-bis-gear-pve-phase-2",
        items={
            {30680,"Feet","Option","Glider's Foot-Wraps","Drop","Shadikith the Glider","Karazhan","B",3},
            {30675,"Waist","Option","Lurker's Cord","Drop","Hyakiss the Lurker","Karazhan","B",4},
            {24692,"Wrist","Option","Elementalist Bracelets","Drop","World Drop","","B",5},
            {30684,"Wrist","BiS","Ravager's Cuffs","Drop","Rokad the Ravager","Karazhan","B",2},
        },
    },
    {
        class="WARLOCK", guide="Demonology", phase=2,
        source="https://www.wowhead.com/tbc/guide/classes/warlock/demonology/dps-bis-gear-pve-phase-2",
        items={
            {30680,"Feet","BiS","Glider's Foot-Wraps","Drop","Shadikith the Glider","Karazhan","B",2},
            {30675,"Waist","Option","Lurker's Cord","Drop","Hyakiss the Lurker","Karazhan","B",3},
            {24692,"Wrist","Option","Elementalist Bracelets","Drop","World Drop","","B",3},
            {30684,"Wrist","BiS","Ravager's Cuffs","Drop","Rokad the Ravager","Karazhan","B",1},
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

local removals = {
    {class="WARRIOR",guide="Fury",phase=1,item=30257,source="https://www.wowhead.com/tbc/guide/fury-warrior-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow"},
    {class="WARRIOR",guide="Fury",phase=1,item=31695,source="https://www.wowhead.com/tbc/guide/fury-warrior-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow"},
    {class="WARRIOR",guide="Fury",phase=1,item=28307,source="https://www.wowhead.com/tbc/guide/fury-warrior-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow"},
    {class="WARRIOR",guide="Fury",phase=1,item=28189,source="https://www.wowhead.com/tbc/guide/fury-warrior-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow"},
    {class="WARRIOR",guide="Fury",phase=1,item=28573,source="https://www.wowhead.com/tbc/guide/fury-warrior-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow"},
    {class="WARRIOR",guide="Fury",phase=1,item=24550,source="https://www.wowhead.com/tbc/guide/fury-warrior-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow"},
    {class="WARRIOR",guide="Fury",phase=1,item=28773,source="https://www.wowhead.com/tbc/guide/fury-warrior-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow"},
    {class="WARRIOR",guide="Fury",phase=1,item=28429,source="https://www.wowhead.com/tbc/guide/fury-warrior-dps-karazhan-best-in-slot-gear-burning-crusade-classic-wow"},
}

LP.BIS_CORRECTION_META = {source="Wowhead TBC Anniversary",phases="0,1,2",reviewed="2026-07-22",groups=#corrections,slotCorrections=#slotCorrections,removals=#removals}

LP.BIS_CORRECTION_SOURCES = {}
for _, correction in ipairs(removals) do
    local phaseEntries = LP.BIS_LISTS[correction.class][correction.guide][correction.phase]
    for index = #phaseEntries, 1, -1 do
        if phaseEntries[index][1] == correction.item then
            table.remove(phaseEntries, index)
            LP.BIS_DATA_META.entries = LP.BIS_DATA_META.entries - 1
        end
    end
    LP.BIS_CORRECTION_SOURCES[correction.class .. ":" .. correction.guide .. ":" .. correction.phase .. ":" .. correction.item] = correction.source
end

local knownItems, uniqueItems = {}, 0
for _, classGuides in pairs(LP.BIS_LISTS or {}) do
    for _, phases in pairs(classGuides) do
        for _, entries in pairs(phases) do
            for _, entry in ipairs(entries) do
                if not knownItems[entry[1]] then
                    knownItems[entry[1]] = true
                    uniqueItems = uniqueItems + 1
                end
            end
        end
    end
end
LP.BIS_DATA_META.uniqueItems = uniqueItems

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
