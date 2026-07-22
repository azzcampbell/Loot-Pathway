local _, LP = ...

LP.TIERS = {
    QUEST={label="Quest",short="QUEST",colour={0.28,0.78,0.53},order=1},
    DUNGEON={label="Dungeon / Heroic",short="DUNGEON / HEROIC",colour={0.37,0.58,0.92},order=2},
    CRAFTABLE={label="Craftable",short="CRAFTABLE",colour={0.92,0.52,0.24},order=3},
    OTHER={label="Other",short="OTHER",colour={0.56,0.59,0.64},order=4},
    RAID={label="Raid",short="RAID",colour={0.72,0.45,0.92},order=5},
}

-- Talent trees are mapped to the closest embedded BIS guide. Some role guides
-- combine trees (Rogue DPS and Priest healing); Feral defaults to Cat.
LP.BIS_SPEC_MAP = {
    WARRIOR={Arms="Arms",Fury="Fury",Protection="Protection"},
    PALADIN={Holy="Holy",Protection="Protection",Retribution="Retribution"},
    HUNTER={["Beast Mastery"]="Beast Mastery",Marksmanship="Marksmanship",Survival="Survival"},
    ROGUE={Assassination="Dps",Combat="Dps",Subtlety="Dps"},
    PRIEST={Discipline="Holy",Holy="Holy",Shadow="Shadow"},
    SHAMAN={Elemental="Elemental",Enhancement="Enhancement",Restoration="Restoration"},
    MAGE={Arcane="Arcane",Fire="Fire",Frost="Frost"},
    WARLOCK={Affliction="Affliction",Demonology="Demonology",Destruction="Destruction"},
    DRUID={Balance="Balance",["Feral Combat"]="Cat",Restoration="Restoration"},
}

-- Talent trees do not always identify the player's role. Feral Combat can use
-- either the Cat or Bear guide, so both are exposed through the guide selector.
LP.BIS_GUIDE_CHOICES = {
    DRUID={
        ["Feral Combat"]={"Cat","Bear"},
    },
}

-- Reviewed guide corrections applied on top of the bundled list snapshot.
-- Wowhead Phase 2 treats Voidheart Gloves as a two-piece set option rather
-- than the slot's Phase 2 BIS for Destruction.
LP.BIS_RANK_OVERRIDES = {
    ["HUNTER:Survival:2:29298"] = "BIS",
    ["WARLOCK:Destruction:2:28968"] = "2PC",
}
-- Wowhead ranks weapons inside separate one-hand and two-hand sections. These
-- display overrides combine those sections into one honest personal-DPS route.
-- Atiesh remains listed because its party aura gives it exceptional raid value,
-- but the guide explicitly states that its personal stats trail the best 1H+OH.
LP.BIS_DISPLAY_ORDER_OVERRIDES = {
    ["WARLOCK:Affliction:2:22630"] = 4,
    ["WARLOCK:Demonology:2:22630"] = 3,
    ["WARLOCK:Destruction:2:22630"] = 3,
}
LP.BIS_PREVIEW_OVERRIDES = {
    ["WARLOCK:Affliction:2:MAINHAND"] = 32053,
    ["WARLOCK:Demonology:2:MAINHAND"] = 32053,
    ["WARLOCK:Destruction:2:MAINHAND"] = 32053,
}
LP.BIS_OVERRIDE_SOURCES = {
    ["HUNTER:Survival:2:29298"] = "https://www.wowhead.com/tbc/guide/classes/hunter/survival/dps-bis-gear-pve-phase-2",
    ["WARLOCK:Destruction:2:28968"] = "https://www.wowhead.com/tbc/guide/classes/warlock/destruction/dps-bis-gear-pve-phase-2",
    ["WARLOCK:Affliction:2:22630"] = "https://www.wowhead.com/tbc/guide/classes/warlock/affliction/dps-bis-gear-pve-phase-2",
    ["WARLOCK:Demonology:2:22630"] = "https://www.wowhead.com/tbc/guide/classes/warlock/demonology/dps-bis-gear-pve-phase-2",
    ["WARLOCK:Destruction:2:22630"] = "https://www.wowhead.com/tbc/guide/classes/warlock/destruction/dps-bis-gear-pve-phase-2",
}

LP.SLOTS = {
    {key="HEAD",label="Head",inventory=1},{key="NECK",label="Neck",inventory=2},
    {key="SHOULDER",label="Shoulders",inventory=3},{key="CHEST",label="Chest",inventory=5},
    {key="WAIST",label="Waist",inventory=6},{key="LEGS",label="Legs",inventory=7},
    {key="FEET",label="Feet",inventory=8},{key="WRIST",label="Wrists",inventory=9},
    {key="HANDS",label="Hands",inventory=10},{key="RING",label="Finger",inventory={11,12}},
    {key="TRINKET",label="Trinket",inventory={13,14}},{key="BACK",label="Back",inventory=15},
    {key="MAINHAND",label="Main hand",inventory=16},{key="OFFHAND",label="Off hand",inventory=17},
    {key="RANGED",label="Ranged",inventory=18},
}

LP.SPECS = {
    WARRIOR={{"Arms","STR_MELEE"},{"Fury","STR_MELEE"},{"Protection","TANK"}},
    PALADIN={{"Holy","HEALER"},{"Protection","TANK"},{"Retribution","STR_MELEE"}},
    HUNTER={{"Beast Mastery","AGI_RANGED"},{"Marksmanship","AGI_RANGED"},{"Survival","AGI_RANGED"}},
    ROGUE={{"Assassination","AGI_MELEE"},{"Combat","AGI_MELEE"},{"Subtlety","AGI_MELEE"}},
    PRIEST={{"Discipline","HEALER"},{"Holy","HEALER"},{"Shadow","CASTER"}},
    SHAMAN={{"Elemental","CASTER"},{"Enhancement","AGI_MELEE"},{"Restoration","HEALER"}},
    MAGE={{"Arcane","CASTER"},{"Fire","CASTER"},{"Frost","CASTER"}},
    WARLOCK={{"Affliction","CASTER"},{"Demonology","CASTER"},{"Destruction","CASTER"}},
    DRUID={{"Balance","CASTER"},{"Feral Combat","FERAL"},{"Restoration","HEALER"}},
}
