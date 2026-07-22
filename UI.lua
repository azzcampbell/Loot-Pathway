local _, LP = ...

local C = {
    bg={0.025,0.031,0.041,.98}, panel={0.052,0.063,0.080,1}, raised={0.075,0.088,0.108,1},
    line={0.17,0.19,0.23,1}, text={.92,.93,.95}, muted={.55,.59,.66}, gold={.84,.67,.36},
    bronze={.56,.44,.26}, green={.25,.90,.38}, raid={.63,.38,.83}, blue={0,.29,.68},
}

local PHASES = {
    [0]={label="PRE-RAID",colour={.28,.72,.56}},
    [1]={label="PHASE 1",colour={.37,.58,.92}},
    [2]={label="PHASE 2",colour={.72,.45,.92}},
}
local COLLAPSED_WIDTH = 520
local DRAWER_WIDTH = 480
local DRAWER_CONTENT_WIDTH = 426

local SLOT_TEXTURES = {
    [1]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Head",[2]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Neck",
    [3]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Shoulder",[5]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest",
    [6]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Waist",[7]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Legs",
    [8]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Feet",[9]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Wrists",
    [10]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Hands",[11]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger",
    [12]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger",[13]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket",
    [14]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket",[15]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest",
    [16]="Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand",[17]="Interface\\PaperDoll\\UI-PaperDoll-Slot-SecondaryHand",
    [18]="Interface\\PaperDoll\\UI-PaperDoll-Slot-Ranged",
}

local DISPLAY_SLOTS = {
    {1,"HEAD","LEFT",20,-120},{2,"NECK","LEFT",20,-172},{3,"SHOULDER","LEFT",20,-224},
    {15,"BACK","LEFT",20,-276},{5,"CHEST","LEFT",20,-328},{9,"WRIST","LEFT",20,-380},
    {10,"HANDS","RIGHT",-20,-104},{6,"WAIST","RIGHT",-20,-152},{7,"LEGS","RIGHT",-20,-200},
    {8,"FEET","RIGHT",-20,-248},{11,"RING","RIGHT",-20,-296,1},{12,"RING","RIGHT",-20,-344,2},
    {13,"TRINKET","RIGHT",-20,-392,1},{14,"TRINKET","RIGHT",-20,-440,2},
    {16,"MAINHAND","BOTTOM",163,18},{17,"OFFHAND","BOTTOM",219,18},{18,"RANGED","BOTTOM",275,18},
}

local function Backdrop(frame, colour, border)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    frame:SetBackdropColor(unpack(colour)); frame:SetBackdropBorderColor(unpack(border or C.line))
end

local function Text(parent,size,colour,justify,outline)
    local fs=parent:CreateFontString(nil,"OVERLAY"); fs:SetFont(STANDARD_TEXT_FONT,size,outline and "OUTLINE" or "")
    fs:SetTextColor(unpack(colour or C.text)); fs:SetJustifyH(justify or "LEFT"); return fs
end

local function Button(parent,label,width,height)
    local button=CreateFrame("Button",nil,parent,"BackdropTemplate"); button:SetSize(width,height); Backdrop(button,C.raised)
    button.label=Text(button,10,C.muted,"CENTER",true); button.label:SetPoint("CENTER"); button.label:SetText(label)
    button:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(C.gold)); self.label:SetTextColor(unpack(C.text)) end)
    button:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(C.line)); self.label:SetTextColor(unpack(C.muted)) end)
    return button
end

local function RegisterEscapeClose(frameName)
    if not UISpecialFrames then return end
    for _,registeredName in ipairs(UISpecialFrames) do
        if registeredName==frameName then return end
    end
    table.insert(UISpecialFrames,frameName)
end

local function CloseButton(parent,size)
    local button=Button(parent,"",size,size); button.closeBorder={}
    button.closeGlyph=Text(button,13,C.muted,"CENTER",true); button.closeGlyph:SetPoint("CENTER",0,0); button.closeGlyph:SetText("X")
    local edges={
        {"TOPLEFT",1,-1,size-2,2},
        {"BOTTOMLEFT",1,1,size-2,2},
        {"TOPLEFT",1,-1,2,size-2},
        {"TOPRIGHT",-1,-1,2,size-2},
    }
    for _,edge in ipairs(edges) do
        local border=button:CreateTexture(nil,"OVERLAY"); border:SetColorTexture(unpack(C.line)); border:SetPoint(edge[1],edge[2],edge[3]); border:SetSize(edge[4],edge[5])
        table.insert(button.closeBorder,border)
    end
    button:HookScript("OnEnter",function(self)
        self.closeGlyph:SetTextColor(unpack(C.text))
        for _,border in ipairs(self.closeBorder) do border:SetColorTexture(unpack(C.gold)) end
    end)
    button:HookScript("OnLeave",function(self)
        self.closeGlyph:SetTextColor(unpack(C.muted))
        for _,border in ipairs(self.closeBorder) do border:SetColorTexture(unpack(C.line)) end
    end)
    return button
end

local function ItemIDFromLink(link)
    return link and tonumber(string.match(link,"item:(%d+)")) or nil
end

local function PreviewSocketCount(item)
    if not item or not GetItemStats then return 0 end
    local stats=GetItemStats(item.link or ("item:"..tostring(item.id)))
    if not stats then return 0 end
    return (stats.EMPTY_SOCKET_META or 0)+(stats.EMPTY_SOCKET_RED or 0)+(stats.EMPTY_SOCKET_YELLOW or 0)+(stats.EMPTY_SOCKET_BLUE or 0)
end

local function CreateAugmentBadge(parent,label)
    local badge=CreateFrame("Button",nil,parent,"BackdropTemplate"); badge:SetSize(16,20); Backdrop(badge,{.018,.023,.030,.96},C.line)
    badge.icon=badge:CreateTexture(nil,"ARTWORK"); badge.icon:SetPoint("TOPLEFT",2,-2); badge.icon:SetPoint("BOTTOMRIGHT",-2,2); badge.icon:SetTexCoord(.08,.92,.08,.92)
    badge.letter=Text(badge,8,C.text,"CENTER",true); badge.letter:SetPoint("BOTTOMRIGHT",0,0); badge.letter:SetText(label)
    badge:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(C.gold)); LP:ShowAugmentTooltip(self) end)
    badge:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(C.line)); GameTooltip:Hide() end)
    return badge
end

function LP:PositionMinimapButton()
    if not self.minimapButton or not Minimap then return end
    local angle=self.db.minimapAngle or 0; self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*80,math.sin(angle)*80)
    self.minimapButton:SetShown(not self.db.minimapHidden)
end

local function AngleFromVector(y,x)
    if math.atan2 then return math.atan2(y,x) end
    if x>0 then return math.atan(y/x) end
    if x<0 and y>=0 then return math.atan(y/x)+math.pi end
    if x<0 and y<0 then return math.atan(y/x)-math.pi end
    if y>0 then return math.pi/2 end
    if y<0 then return -math.pi/2 end
    return 0
end

function LP:CreateMinimapButton()
    if self.minimapButton or not Minimap then return end
    local button=CreateFrame("Button","LootPathwayMinimapButton",Minimap); self.minimapButton=button
    button:SetSize(32,32); button:SetFrameStrata("MEDIUM"); button:SetFrameLevel((Minimap:GetFrameLevel() or 0)+8)
    button:RegisterForClicks("LeftButtonUp","RightButtonUp"); button:RegisterForDrag("LeftButton")
    button.icon=button:CreateTexture(nil,"BACKGROUND"); button.icon:SetSize(22,22); button.icon:SetPoint("CENTER"); button.icon:SetTexture("Interface\\AddOns\\LootPathway\\Assets\\Brand\\LootPathway-Minimap"); button.icon:SetTexCoord(0,1,0,1)
    button.border=button:CreateTexture(nil,"OVERLAY"); button.border:SetSize(52,52); button.border:SetPoint("TOPLEFT"); button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.highlight=button:CreateTexture(nil,"HIGHLIGHT"); button.highlight:SetSize(28,28); button.highlight:SetPoint("CENTER"); button.highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"); button.highlight:SetBlendMode("ADD")
    button:SetScript("OnClick",function(_,mouseButton)
        if mouseButton=="RightButton" and IsControlKeyDown and IsControlKeyDown() then
            LP.db.minimapHidden=true; LP:PositionMinimapButton(); LP:Print("Minimap button hidden. Use /lpw options to show it again.")
        elseif mouseButton=="RightButton" then
            LP.db.minimapAngle=0; LP:PositionMinimapButton(); LP:Print("Minimap button reset to 3 o'clock.")
        else LP:Toggle() end
    end)
    button:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_LEFT"); GameTooltip:SetText("Loot Pathway",unpack(C.gold)); GameTooltip:AddLine("Left-click to open or close",1,1,1); GameTooltip:AddLine("Drag to move - Right-click to reset",unpack(C.muted)); GameTooltip:AddLine("Ctrl-right-click to hide",C.green[1],C.green[2],C.green[3]); GameTooltip:Show() end)
    button:SetScript("OnLeave",function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart",function(self) self:SetScript("OnUpdate",function()
        local scale=Minimap:GetEffectiveScale() or 1; local cx,cy=GetCursorPosition(); local mx,my=Minimap:GetCenter(); cx,cy=cx/scale,cy/scale
        LP.db.minimapAngle=AngleFromVector(cy-my,cx-mx); LP:PositionMinimapButton()
    end) end)
    button:SetScript("OnDragStop",function(self) self:SetScript("OnUpdate",nil) end)
    self:PositionMinimapButton()
end

function LP:UpdateOptions()
    if not self.optionsFrame then return end
    local shown=not self.db.minimapHidden
    self.optionsTick:SetShown(shown)
    self.optionsStatus:SetText(shown and "The minimap button is visible." or "The minimap button is hidden.")
    self.optionsStatus:SetTextColor(unpack(shown and C.green or C.muted))
end

function LP:CreateOptionsUI()
    if self.optionsFrame then return end
    local frame=CreateFrame("Frame","LootPathwayOptionsFrame",UIParent,"BackdropTemplate"); self.optionsFrame=frame
    RegisterEscapeClose("LootPathwayOptionsFrame")
    frame:SetSize(340,184); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(self) self:StartMoving() end); frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end); Backdrop(frame,C.bg,C.bronze)
    local top=frame:CreateTexture(nil,"ARTWORK"); top:SetColorTexture(unpack(C.gold)); top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(3)
    local title=Text(frame,16,C.text); title:SetPoint("TOPLEFT",18,-17); title:SetText("LOOT PATHWAY OPTIONS")
    local close=CloseButton(frame,26); close:SetPoint("TOPRIGHT",-13,-13); close:SetScript("OnClick",function() frame:Hide() end)
    local description=Text(frame,10,C.muted); description:SetPoint("TOPLEFT",18,-48); description:SetWidth(300); description:SetText("Choose whether Loot Pathway keeps a button around the minimap.")
    local check=CreateFrame("Button",nil,frame,"BackdropTemplate"); check:SetSize(26,26); check:SetPoint("TOPLEFT",18,-80); Backdrop(check,{.03,.04,.05,1},C.gold)
    self.optionsTick=check:CreateTexture(nil,"OVERLAY"); self.optionsTick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check"); self.optionsTick:SetVertexColor(unpack(C.green)); self.optionsTick:SetAllPoints()
    local label=Text(frame,11,C.text); label:SetPoint("LEFT",check,"RIGHT",10,0); label:SetText("Show the minimap button")
    local hit=CreateFrame("Button",nil,frame); hit:SetPoint("TOPLEFT",check); hit:SetSize(260,28); hit:SetFrameLevel(check:GetFrameLevel()+2)
    hit:SetScript("OnClick",function() LP.db.minimapHidden=not LP.db.minimapHidden; LP:PositionMinimapButton(); LP:UpdateOptions() end)
    hit:SetScript("OnEnter",function() label:SetTextColor(unpack(C.gold)) end); hit:SetScript("OnLeave",function() label:SetTextColor(unpack(C.text)) end)
    self.optionsStatus=Text(frame,10,C.muted); self.optionsStatus:SetPoint("TOPLEFT",18,-112)
    local reset=Button(frame,"RESET MINIMAP POSITION",156,24); reset:SetPoint("TOPLEFT",18,-132); reset:SetScript("OnClick",function() LP.db.minimapAngle=0; LP:PositionMinimapButton(); LP:Print("Minimap button reset to 3 o'clock.") end)
    local hint=Text(frame,9,C.muted); hint:SetPoint("BOTTOMLEFT",18,9); hint:SetText("Ctrl-right-click the minimap button to hide it quickly.")
    self:UpdateOptions(); frame:Hide()
end

function LP:ToggleOptions()
    self:CreateOptionsUI()
    if self.optionsFrame:IsShown() then self.optionsFrame:Hide() else self:UpdateOptions(); self.optionsFrame:Show() end
end

function LP:SetDrawerOpen(open)
    self.drawerOpen=open and true or false
    if not self.frame then return end
    if self.drawerOpen and self.pathPane then
        self.pathPane:ClearAllPoints()
        local frameLeft,frameRight=self.frame:GetLeft(),self.frame:GetRight()
        local availableLeft=UIParent:GetLeft() or 0
        local availableRight=UIParent:GetRight() or GetScreenWidth()
        local uiScale=UIParent:GetEffectiveScale() or 1
        local frameScale=self.frame:GetEffectiveScale() or uiScale
        local drawerScreenWidth=DRAWER_WIDTH*(frameScale/uiScale)
        if frameRight and frameRight+drawerScreenWidth<=availableRight then
            self.pathPane:SetPoint("TOPLEFT",self.frame,"TOPRIGHT",-2,-68)
            self.pathPane:SetFrameLevel(self.frame:GetFrameLevel()+1)
        elseif frameLeft and frameLeft-drawerScreenWidth>=availableLeft then
            self.pathPane:SetPoint("TOPRIGHT",self.frame,"TOPLEFT",2,-68)
            self.pathPane:SetFrameLevel(self.frame:GetFrameLevel()+1)
        else
            self.pathPane:SetPoint("CENTER",UIParent,"CENTER",0,0)
            self.pathPane:SetFrameLevel(self.frame:GetFrameLevel()+20)
        end
    end
    if self.pathPane then self.pathPane:SetShown(self.drawerOpen) end
end

function LP:HideGuideMenu()
    if self.guideMenu then self.guideMenu:Hide() end
end

function LP:ToggleGuideMenu()
    if not self.guideMenu then return end
    if self.guideMenu:IsShown() then self.guideMenu:Hide(); return end

    local class, talentSpec = self:GetPlayerBuild()
    local automatic = self.BIS_SPEC_MAP[class] and self.BIS_SPEC_MAP[class][talentSpec]
    local selected = self:GetEmbeddedSpec(class, talentSpec)
    local classChoices = self:GetClassGuideChoices(class)
    local choices, added = {}, {}
    local function addChoice(guideName)
        if guideName and not added[guideName] then added[guideName]=true; table.insert(choices,guideName) end
    end
    addChoice(automatic); if selected~=automatic then addChoice(selected) end
    for _,guideName in ipairs(classChoices) do addChoice(guideName) end
    for _, option in ipairs(self.guideOptions) do option:Hide() end

    for index, guideName in ipairs(choices) do
        local option = self.guideOptions[index]
        if not option then
            option = Button(self.guideMenu,"",306,24); option:SetPoint("TOPLEFT",2,-2-((index-1)*25)); self.guideOptions[index]=option
        end
        option.guideName=guideName
        local label=guideName
        if guideName==automatic then label=label.." (Auto)"
        elseif guideName==selected then label=label.." (Selected)" end
        option.label:SetText(label)
        local isSelected=guideName==selected
        option.isSelected=isSelected
        Backdrop(option,isSelected and {.14,.11,.055,1} or C.raised,isSelected and C.gold or C.line)
        option:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(C.gold)); self.label:SetTextColor(unpack(C.text)) end)
        option:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(self.isSelected and C.gold or C.line)); self.label:SetTextColor(unpack(C.muted)) end)
        option:SetScript("OnClick",function(self)
            LP:SetGuideOverride(talentSpec,self.guideName==automatic and nil or self.guideName)
            LP:HideGuideMenu(); LP:RefreshModel(); LP:Refresh()
        end)
        option:Show()
    end
    self.guideMenu:SetHeight(math.max(28,#choices*25+4)); self.guideMenu:Show()
end

function LP:CreatePhaseButton(parent,phase,label,x,width)
    local button=CreateFrame("Button",nil,parent,"BackdropTemplate"); button:SetSize(width,28); button:SetPoint("TOPLEFT",x,-61)
    button.phase=phase; button.baseLabel=label; button.label=Text(button,9,C.muted,"CENTER",true); button.label:SetPoint("CENTER")
    button.rule=button:CreateTexture(nil,"OVERLAY"); button.rule:SetPoint("BOTTOMLEFT",1,1); button.rule:SetPoint("BOTTOMRIGHT",-1,1); button.rule:SetHeight(2)
    button:SetScript("OnClick",function(self)
        LP.db.displayPhase=self.phase
        LP.db.selectedSource="ALL"
        if self.phase>=0 then LP.db.collapsedPhases[self.phase]=false end
        LP.previewItem=nil
        LP:RefreshModel()
        LP:Refresh()
    end)
    button:SetScript("OnEnter",function(self)
        self:SetBackdropBorderColor(1,1,1,1); GameTooltip:SetOwner(self,"ANCHOR_TOP")
        GameTooltip:SetText(self.phase<0 and "Show your equipped gear" or "Preview this phase's guide items")
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function() GameTooltip:Hide(); LP:UpdatePhaseButtons() end)
    self.phaseButtons[phase]=button
end

function LP:UpdatePhaseButtons()
    local current=tonumber(self.db.displayPhase) or -1
    for phase,button in pairs(self.phaseButtons) do
        local colour=phase<0 and C.muted or PHASES[phase].colour; local selected=current==phase
        Backdrop(button,selected and {colour[1]*.30,colour[2]*.30,colour[3]*.30,1} or C.raised,colour)
        button.label:SetText(button.baseLabel); button.label:SetTextColor(unpack(selected and C.text or colour)); button.rule:SetColorTexture(unpack(colour)); button.rule:SetShown(selected)
    end
    if self.metLegend then self.metLegend:Show() end
end

function LP:ShowAugmentTooltip(badge)
    local button=badge.owner
    if not button then return end
    GameTooltip:SetOwner(badge,button.anchor=="LEFT" and "ANCHOR_RIGHT" or "ANCHOR_LEFT")
    if badge.kind=="GEM" then
        GameTooltip:SetText("Recommended gems",unpack(C.gold))
        if button.socketCount and button.socketCount>0 then GameTooltip:AddLine(button.socketCount.." socket"..(button.socketCount==1 and "" or "s").." on this item",1,1,1) end
        for _,gem in ipairs(button.gemRecommendations or {}) do
            local name,link,quality=GetItemInfo(gem[1]); local colour=quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
            GameTooltip:AddLine(link or name or gem[2],colour and colour.r or 1,colour and colour.g or 1,colour and colour.b or 1)
        end
        if not button.gemRecommendations or #button.gemRecommendations==0 then GameTooltip:AddLine("Recommendation not yet recorded.",unpack(C.muted)) end
    else
        GameTooltip:SetText("Recommended enchant",unpack(C.gold))
        local enchant=button.enchantRecommendation
        GameTooltip:AddLine(enchant and enchant[3] or "No standard enchant applies to this slot.",enchant and 1 or C.muted[1],enchant and 1 or C.muted[2],enchant and 1 or C.muted[3],true)
    end
    GameTooltip:Show()
end

function LP:CreateGearButton(parent,inventory,slotKey,anchor,x,y,ordinal)
    local button=CreateFrame("Button",nil,parent,"BackdropTemplate"); button:SetSize(46,46)
    if anchor=="LEFT" then button:SetPoint("TOPLEFT",x,y) elseif anchor=="RIGHT" then button:SetPoint("TOPRIGHT",x,y) else button:SetPoint("BOTTOMLEFT",x,y) end
    Backdrop(button,{.025,.03,.038,1},C.line); button.inventory,button.slotKey,button.anchor,button.ordinal=inventory,slotKey,anchor,ordinal or 1
    button.icon=button:CreateTexture(nil,"ARTWORK"); button.icon:SetPoint("TOPLEFT",3,-3); button.icon:SetPoint("BOTTOMRIGHT",-3,3); button.icon:SetTexCoord(.08,.92,.08,.92)
    button.shade=button:CreateTexture(nil,"OVERLAY"); button.shade:SetColorTexture(0,0,0,.55); button.shade:SetPoint("TOPLEFT",3,-3); button.shade:SetPoint("BOTTOMRIGHT",-3,3); button.shade:Hide()
    button.tickBack=button:CreateTexture(nil,"OVERLAY"); button.tickBack:SetColorTexture(.01,.04,.02,.92); button.tickBack:SetSize(19,19); button.tickBack:SetPoint("TOPRIGHT",-1,-1); button.tickBack:Hide()
    button.tick=button:CreateTexture(nil,"OVERLAY"); button.tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check"); button.tick:SetVertexColor(unpack(C.green)); button.tick:SetSize(21,21); button.tick:SetPoint("CENTER",button.tickBack); button.tick:Hide()
    button.level=Text(button,9,C.gold,"RIGHT",true); button.level:SetPoint("BOTTOMRIGHT",-4,3)
    button.rank=Text(button,8,C.gold,"LEFT",true); button.rank:SetPoint("TOPLEFT",3,-2)
    button.marker=button:CreateTexture(nil,"OVERLAY"); button.marker:SetColorTexture(unpack(C.gold)); button.marker:SetSize(5,5); button.marker:SetPoint("TOPRIGHT",-2,-2)
    button.qualityFrame=CreateFrame("Frame",nil,button,"BackdropTemplate"); button.qualityFrame:SetAllPoints(); button.qualityFrame:SetFrameLevel(button:GetFrameLevel()+4); button.qualityFrame:EnableMouse(false)
    button.qualityFrame:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2}); button.qualityFrame:SetBackdropColor(0,0,0,0); button.qualityFrame:Hide()
    button.augmentRail=CreateFrame("Frame",nil,parent)
    if anchor=="LEFT" then button.augmentRail:SetSize(16,42); button.augmentRail:SetPoint("LEFT",button,"RIGHT",2,0)
    elseif anchor=="RIGHT" then button.augmentRail:SetSize(16,42); button.augmentRail:SetPoint("RIGHT",button,"LEFT",-2,0)
    else button.augmentRail:SetSize(34,20); button.augmentRail:SetPoint("BOTTOM",button,"TOP",0,2) end
    button.gemBadge=CreateAugmentBadge(button.augmentRail,"G"); button.gemBadge.owner,button.gemBadge.kind=button,"GEM"
    button.enchantBadge=CreateAugmentBadge(button.augmentRail,"E"); button.enchantBadge.owner,button.enchantBadge.kind=button,"ENCHANT"
    if anchor=="BOTTOM" then button.gemBadge:SetPoint("LEFT"); button.enchantBadge:SetPoint("RIGHT")
    else button.gemBadge:SetPoint("TOP"); button.enchantBadge:SetPoint("BOTTOM") end
    button:SetScript("OnClick",function(self)
        local close=LP.drawerOpen and LP.db.selectedSlot==self.slotKey
        LP.db.selectedSlot=self.slotKey; LP:SetDrawerOpen(not close); LP:Refresh()
    end)
    button:SetScript("OnEnter",function(self)
        self:SetBackdropBorderColor(unpack(C.gold)); GameTooltip:SetOwner(self,self.anchor=="LEFT" and "ANCHOR_RIGHT" or "ANCHOR_LEFT")
        if self.displayItem and self.displayItem.link then GameTooltip:SetHyperlink(self.displayItem.link)
        elseif self.displayItem then GameTooltip:SetText(self.displayItem.name)
        else local link=GetInventoryItemLink("player",self.inventory); if link then GameTooltip:SetHyperlink(link) else GameTooltip:SetText(LP:GetSlot(self.slotKey).label) end end
        if self.targetMet then GameTooltip:AddLine(self.metReason or "This guide item is equipped.",C.green[1],C.green[2],C.green[3]) end
        if self.priorBISPhase then local label=self.priorBISPhase==0 and "Pre-Raid" or ("Phase "..self.priorBISPhase); GameTooltip:AddLine("Best-ranked in "..label.."; not a current Phase 2 target.",C.gold[1],C.gold[2],C.gold[3]) end
        if self.gemBadge:IsShown() or self.enchantBadge:IsShown() then GameTooltip:AddLine("Recommended gems and enchant for this guide preview.",C.gold[1],C.gold[2],C.gold[3]) end
        GameTooltip:AddLine("Click to see this slot's guide choices.",C.gold[1],C.gold[2],C.gold[3]); GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function(self) GameTooltip:Hide(); LP:UpdateGearButton(self) end)
    table.insert(self.gearButtons,button)
end

function LP:UpdateGearButton(button)
    local phase=tonumber(self.db.displayPhase) or -1; local texture,level,quality,itemID,displayItem,targetMet,priorBISPhase
    if phase>=0 then
        displayItem=self:GetPhaseDisplayTarget(button.slotKey,phase,button.ordinal)
        if displayItem then
            texture,level,quality,itemID=displayItem.icon,displayItem.level,displayItem.quality,displayItem.id; targetMet,button.metReason=self:IsTargetMet(displayItem,phase,button.inventory)
            local bisPhase=self:GetItemBISPhase(itemID,button.slotKey); if bisPhase and bisPhase<(self.BIS_DATA_META.currentPhase or 2) then priorBISPhase=bisPhase end
        end
    else
        texture=GetInventoryItemTexture("player",button.inventory); local link=GetInventoryItemLink("player",button.inventory)
        level=link and select(4,GetItemInfo(link)) or 0; quality=link and select(3,GetItemInfo(link)); itemID=(GetInventoryItemID and GetInventoryItemID("player",button.inventory)) or ItemIDFromLink(link)
        local bisPhase=self:GetItemBISPhase(itemID,button.slotKey)
        if bisPhase==(self.BIS_DATA_META.currentPhase or 2) then targetMet=true; button.metReason="Current Phase 2 guide target equipped."
        elseif bisPhase then priorBISPhase=bisPhase end
    end
    button.displayItem,button.targetMet,button.priorBISPhase=displayItem,targetMet,priorBISPhase; if not targetMet then button.metReason=nil end
    button.icon:SetTexture(texture or SLOT_TEXTURES[button.inventory] or "Interface\\Icons\\INV_Misc_QuestionMark"); button.icon:SetDesaturated((not texture) or targetMet)
    button.icon:SetVertexColor(targetMet and .46 or 1,targetMet and .46 or 1,targetMet and .46 or 1)
    button.shade:SetShown(targetMet); button.tickBack:SetShown(targetMet); button.tick:SetShown(targetMet); button.level:SetText(level and level>0 and level or "")
    button.rank:SetText(targetMet and "MET" or (priorBISPhase and (priorBISPhase==0 and "PR BEST" or ("P"..priorBISPhase.." BEST")) or (phase>=0 and displayItem and self:GetRankDisplayLabel(displayItem.listRank) or ""))); button.rank:SetTextColor(unpack(targetMet and C.green or C.gold))
    local borderColour=quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]; local br,bg,bb=C.gold[1],C.gold[2],C.gold[3]
    if borderColour then br,bg,bb=borderColour.r,borderColour.g,borderColour.b end
    button.qualityFrame:SetBackdropBorderColor(br,bg,bb,1); button.qualityFrame:SetShown(priorBISPhase~=nil and not targetMet)
    local gems,enchant={},nil
    if phase>=0 and displayItem then gems,enchant=self:GetPhaseAugments(button.slotKey,phase) end
    button.gemRecommendations,button.enchantRecommendation=gems,enchant; button.socketCount=PreviewSocketCount(displayItem)
    local showGem=phase>=0 and displayItem and button.socketCount>0 and #gems>0
    local showEnchant=phase>=0 and displayItem and enchant~=nil
    button.gemBadge:SetShown(showGem); button.enchantBadge:SetShown(showEnchant); button.augmentRail:SetShown(showGem or showEnchant)
    if showGem then button.gemBadge.icon:SetTexture(GetItemIcon(gems[1][1]) or "Interface\\Icons\\INV_Misc_Gem_Ruby_02") end
    if showEnchant then
        local textureID=tonumber(enchant[4]); button.enchantBadge.icon:SetTexture((textureID and GetItemIcon(textureID)) or (GetSpellTexture and GetSpellTexture(enchant[1])) or "Interface\\Icons\\INV_Enchant_Disenchant")
    end
    button.marker:SetShown(self.drawerOpen and self.db.selectedSlot==button.slotKey)
    if targetMet then button:SetBackdropColor(.025,.055,.032,1); button:SetBackdropBorderColor(unpack(C.green))
    elseif self.drawerOpen and self.db.selectedSlot==button.slotKey then button:SetBackdropColor(.17,.13,.065,1); button:SetBackdropBorderColor(unpack(C.gold))
    else
        button:SetBackdropColor(.025,.03,.038,1)
        local qc=quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        if qc then button:SetBackdropBorderColor(qc.r,qc.g,qc.b,1) else button:SetBackdropBorderColor(unpack(C.line)) end
    end
end

function LP:CreateSourceFilter(parent,key,label,x,width)
    local button=CreateFrame("Button",nil,parent,"BackdropTemplate"); button:SetSize(width,28); button:SetPoint("TOPLEFT",x,-119); button.key=key; button.baseLabel=label
    button.label=Text(button,10,C.muted,"CENTER",true); button.label:SetPoint("CENTER")
    button:SetScript("OnClick",function(self) LP.db.selectedSource=self.key; LP:Refresh() end)
    button:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(1,1,1,1) end); button:SetScript("OnLeave",function() LP:UpdateSourceFilters() end)
    self.sourceFilters[key]=button
end

function LP:UpdateSourceFilters()
    for key,button in pairs(self.sourceFilters) do
        local colour=key=="ALL" and C.gold or self.TIERS[key].colour; local selected=(self.db.selectedSource or "ALL")==key
        Backdrop(button,selected and {colour[1]*.3,colour[2]*.3,colour[3]*.3,1} or C.raised,colour)
        button.label:SetText(button.baseLabel); button.label:SetTextColor(unpack(selected and C.text or colour))
    end
end

function LP:CreateBrandFooter(frame)
    local line=frame:CreateTexture(nil,"ARTWORK"); line:SetColorTexture(unpack(C.line)); line:SetPoint("BOTTOMLEFT",18,62); line:SetPoint("BOTTOMRIGHT",-18,62); line:SetHeight(1)
    local brand=CreateFrame("Frame",nil,frame); brand:SetSize(170,34); brand:SetPoint("BOTTOM",0,14)
    local mark=brand:CreateTexture(nil,"ARTWORK"); mark:SetTexture("Interface\\AddOns\\LootPathway\\Assets\\Brand\\NorthernStack-Mark"); mark:SetSize(24,24); mark:SetPoint("LEFT",5,0); mark:SetTexCoord(0,1,0,1)
    local studio=Text(brand,9,C.text,"LEFT",true); studio:SetPoint("LEFT",mark,"RIGHT",7,0); studio:SetPoint("RIGHT",-5,0); studio:SetText("Northern Stack Studios")
end

local function SetModelFacing(model,facing)
    if model.SetFacing then pcall(model.SetFacing,model,facing)
    elseif model.SetRotation then pcall(model.SetRotation,model,facing) end
end

function LP:EnableModelRotation(model,hint)
    model:EnableMouse(true); model:RegisterForDrag("LeftButton"); model:SetScript("OnDragStart",function(self) self.dragX=GetCursorPosition() end)
    model:SetScript("OnUpdate",function(self) if not self.dragX then return end; local x=GetCursorPosition(); local scale=UIParent:GetEffectiveScale() or 1; LP.db.modelFacing=(LP.db.modelFacing or 0)+((x-self.dragX)/scale)*.012; self.dragX=x; SetModelFacing(self,LP.db.modelFacing) end)
    model:SetScript("OnDragStop",function(self) self.dragX=nil end)
    model:SetScript("OnMouseDown",function(self,button) if button=="RightButton" then LP.db.modelFacing=0; SetModelFacing(self,0); if hint then hint:SetText("Facing reset") end end end)
end

function LP:StartModelLoading()
    if not self.playerModel or not self.modelLoading then return end
    self.playerModel:SetAlpha(0)
    self.modelLoading.elapsed,self.modelLoading.total,self.modelLoading.step=0,0,0
    self.modelLoading.text:SetText("Loading")
    self.modelLoading:Show()
    self.modelLoading:SetScript("OnUpdate",function(loading,elapsed)
        loading.elapsed=loading.elapsed+elapsed; loading.total=loading.total+elapsed
        if loading.elapsed>=.28 then loading.elapsed=0; loading.step=(loading.step+1)%4; loading.text:SetText("Loading"..string.rep(".",loading.step)) end
        local ready=false
        if loading.total>=.35 and LP.playerModel.GetModelFileID then local ok,fileID=pcall(LP.playerModel.GetModelFileID,LP.playerModel); ready=ok and fileID and fileID~=0 end
        if ready or loading.total>=3 then
            LP.playerModel:SetAlpha(1); loading:Hide(); loading:SetScript("OnUpdate",nil)
        end
    end)
end

function LP:RefreshModel()
    if not self.playerModel then return end
    self:StartModelLoading()
    local ok=pcall(self.playerModel.SetUnit,self.playerModel,"player")
    if ok then
        local phase=tonumber(self.db.displayPhase) or -1
        local plan=self:GetModelPreviewPlan(phase,self.previewItem)
        if self.playerModel.UndressSlot then
            if plan.clearMainHand then pcall(self.playerModel.UndressSlot,self.playerModel,INVSLOT_MAINHAND or 16) end
            if plan.clearOffHand then pcall(self.playerModel.UndressSlot,self.playerModel,INVSLOT_OFFHAND or 17) end
        end
        if self.playerModel.TryOn then
            for _,item in ipairs(plan.items) do
                if item.id then pcall(self.playerModel.TryOn,self.playerModel,"item:"..item.id) end
            end
        end
        if self.playerModel.UndressSlot then
            if plan.clearMainHand then pcall(self.playerModel.UndressSlot,self.playerModel,INVSLOT_MAINHAND or 16) end
            if plan.clearOffHand then pcall(self.playerModel.UndressSlot,self.playerModel,INVSLOT_OFFHAND or 17) end
        end
        SetModelFacing(self.playerModel,self.db.modelFacing or 0)
    else self.playerModel:Hide(); self.modelFallback:Show(); if self.modelLoading then self.modelLoading:Hide() end end
end

function LP:ToggleItemPreview(item)
    if not item then return end
    if self.previewItem and self.previewItem.id==item.id and self.previewItem.phase==item.phase then self.previewItem=nil
    else self.previewItem={id=item.id,name=item.name,phase=item.phase,slot=item.slot,bisSlot=item.bisSlot} end
    self:RefreshModel()
    self:Refresh()
end

function LP:CreateUI()
    if self.frame then return end
    local frame=CreateFrame("Frame","LootPathwayFrame",UIParent,"BackdropTemplate"); self.frame=frame; frame:Hide(); frame:SetSize(COLLAPSED_WIDTH,630)
    RegisterEscapeClose("LootPathwayFrame")
    frame:SetPoint(self.db.point,UIParent,self.db.relativePoint,self.db.x,self.db.y); frame:SetScale(self.db.scale); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(self) if not LP.db.locked then self:StartMoving() end end); frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); LP:SavePosition() end); Backdrop(frame,C.bg,C.bronze)
    local top=frame:CreateTexture(nil,"ARTWORK"); top:SetColorTexture(unpack(C.gold)); top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(3)
    local title=Text(frame,20,C.text,"CENTER",true); title:SetPoint("TOP",0,-12); title:SetWidth(300); title:SetText("Loot Pathway")
    local titleRuleLeft=frame:CreateTexture(nil,"ARTWORK"); titleRuleLeft:SetColorTexture(C.gold[1],C.gold[2],C.gold[3],.72); titleRuleLeft:SetPoint("TOPRIGHT",frame,"TOP",-86,-25); titleRuleLeft:SetSize(54,2)
    local titleRuleRight=frame:CreateTexture(nil,"ARTWORK"); titleRuleRight:SetColorTexture(C.gold[1],C.gold[2],C.gold[3],.72); titleRuleRight:SetPoint("TOPLEFT",frame,"TOP",86,-25); titleRuleRight:SetSize(54,2)
    local subtitle=Text(frame,10,C.muted,"CENTER"); subtitle:SetPoint("TOP",title,"BOTTOM",0,-2); subtitle:SetWidth(360); subtitle:SetText("Click a gear slot to see its guide choices.")
    local headerDivider=frame:CreateTexture(nil,"ARTWORK"); headerDivider:SetColorTexture(unpack(C.line)); headerDivider:SetPoint("TOPLEFT",18,-59); headerDivider:SetPoint("TOPRIGHT",-18,-59); headerDivider:SetHeight(1)
    local headerAccent=frame:CreateTexture(nil,"OVERLAY"); headerAccent:SetColorTexture(unpack(C.gold)); headerAccent:SetPoint("TOP",0,-58); headerAccent:SetSize(72,2)
    local close=CloseButton(frame,28); close:SetPoint("TOPRIGHT",-16,-16); close:SetScript("OnClick",function() frame:Hide() end)

    local character=CreateFrame("Frame",nil,frame,"BackdropTemplate"); character:SetPoint("TOPLEFT",18,-68); character:SetSize(484,490); Backdrop(character,C.panel,C.line); self.characterPane=character
    self.characterName=Text(character,14,C.text,"CENTER"); self.characterName:SetPoint("TOP",0,-12)
    self.guideButton=Button(character,"",310,20); self.guideButton:SetPoint("TOP",self.characterName,"BOTTOM",0,-2); self.characterBuild=self.guideButton.label
    self.guideButton:SetScript("OnClick",function() LP:ToggleGuideMenu() end)
    self.guideButton:HookScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_TOP")
        GameTooltip:SetText("Gear guide",unpack(C.gold))
        GameTooltip:AddLine("Auto follows your talent tree.",1,1,1)
        GameTooltip:AddLine("Choose another guide if your role differs.",unpack(C.muted))
        GameTooltip:Show()
    end)
    self.guideButton:HookScript("OnLeave",function() GameTooltip:Hide() end)
    self.guideArrow=Text(self.guideButton,10,C.gold,"RIGHT",true); self.guideArrow:SetPoint("RIGHT",-8,0); self.guideArrow:SetText("v")
    self.guideMenu=CreateFrame("Frame",nil,character,"BackdropTemplate"); self.guideMenu:SetPoint("TOP",self.guideButton,"BOTTOM",0,-2); self.guideMenu:SetWidth(310); self.guideMenu:SetFrameLevel(character:GetFrameLevel()+20); Backdrop(self.guideMenu,C.panel,C.gold); self.guideMenu:Hide(); self.guideOptions={}
    self.phaseButtons={}; self:CreatePhaseButton(character,-1,"EQUIPPED",20,76); self:CreatePhaseButton(character,0,"PRE-RAID",102,106); self:CreatePhaseButton(character,1,"PHASE 1",214,106); self:CreatePhaseButton(character,2,"PHASE 2",326,138)

    local modelBackdrop=CreateFrame("Frame",nil,character,"BackdropTemplate"); modelBackdrop:SetPoint("TOPLEFT",84,-96); modelBackdrop:SetPoint("BOTTOMRIGHT",-84,88); Backdrop(modelBackdrop,{.018,.023,.030,1},C.bronze)
    local glow=modelBackdrop:CreateTexture(nil,"BACKGROUND"); glow:SetColorTexture(.04,.075,.10,.32); glow:SetAllPoints()
    self.modelFallback=modelBackdrop:CreateTexture(nil,"ARTWORK"); self.modelFallback:SetSize(150,150); self.modelFallback:SetPoint("CENTER"); SetPortraitTexture(self.modelFallback,"player"); self.modelFallback:Hide()
    self.modelHint=nil
    self.metLegend=Text(character,10,C.green,"CENTER",true); self.metLegend:SetPoint("BOTTOM",0,4); self.metLegend:SetWidth(260); self.metLegend:SetText("MET = THIS GUIDE ITEM IS EQUIPPED")
    local modelOK=pcall(function() self.playerModel=CreateFrame("DressUpModel",nil,modelBackdrop); self.playerModel:SetAllPoints(); if self.playerModel.SetCamDistanceScale then self.playerModel:SetCamDistanceScale(.9) end; self:EnableModelRotation(self.playerModel,self.modelHint) end)
    if not modelOK then if self.playerModel then self.playerModel:Hide() end; self.modelFallback:Show() end
    self.modelLoading=CreateFrame("Frame",nil,modelBackdrop); self.modelLoading:SetAllPoints(); self.modelLoading:SetFrameLevel(modelBackdrop:GetFrameLevel()+10)
    self.modelLoading.shade=self.modelLoading:CreateTexture(nil,"BACKGROUND"); self.modelLoading.shade:SetColorTexture(.01,.015,.022,.98); self.modelLoading.shade:SetAllPoints()
    self.modelLoading.text=Text(self.modelLoading,14,C.gold,"CENTER",true); self.modelLoading.text:SetPoint("CENTER"); self.modelLoading.text:SetText("Loading...")
    self.gearButtons={}; for _,slot in ipairs(DISPLAY_SLOTS) do self:CreateGearButton(character,slot[1],slot[2],slot[3],slot[4],slot[5],slot[6]) end
    if modelOK then self:RefreshModel() else self.modelLoading:Hide() end

    local right=CreateFrame("Frame",nil,frame,"BackdropTemplate"); right:SetPoint("TOPLEFT",518,-68); right:SetSize(DRAWER_WIDTH,490); Backdrop(right,C.panel,C.line); self.pathPane=right
    self.pathLabel=Text(right,10,C.gold); self.pathLabel:SetPoint("TOPLEFT",14,-18); self.pathLabel:SetText("GUIDE CHOICES")
    local drawerClose=Button(right,"<",28,28); drawerClose:SetPoint("TOPRIGHT",-12,-12); drawerClose:SetScript("OnClick",function() LP:SetDrawerOpen(false); LP:Refresh() end)
    self.pathTitle=Text(right,16,C.text); self.pathTitle:SetPoint("TOPLEFT",14,-48)
    self.pathSummary=Text(right,10,C.muted); self.pathSummary:SetPoint("TOPLEFT",self.pathTitle,"BOTTOMLEFT",0,-6); self.pathSummary:SetWidth(440)
    self.sourceFilters={}; self:CreateSourceFilter(right,"ALL","ALL",14,44); self:CreateSourceFilter(right,"QUEST","QUEST",66,56); self:CreateSourceFilter(right,"DUNGEON","DUNGEON / HEROIC",130,132); self:CreateSourceFilter(right,"RAID","RAID",270,54); self:CreateSourceFilter(right,"CRAFTABLE","CRAFTABLE",332,94)
    local scroll=CreateFrame("ScrollFrame","LootPathwayScrollFrame",right,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",14,-160); scroll:SetPoint("BOTTOMRIGHT",-36,16)
    local content=CreateFrame("Frame",nil,scroll); content:SetSize(DRAWER_CONTENT_WIDTH,1); scroll:SetScrollChild(content); self.content=content; self.rows={}; self.stageHeaders={}
    self:CreateBrandFooter(frame); self:CreateMinimapButton(); self:CreateOptionsUI(); self:SetDrawerOpen(false)
end

function LP:AcquireStageHeader(phase)
    if self.stageHeaders[phase] then return self.stageHeaders[phase] end
    local meta=PHASES[phase]; local header=CreateFrame("Button",nil,self.content,"BackdropTemplate"); header:SetSize(DRAWER_CONTENT_WIDTH,30); header.phase=phase; Backdrop(header,{meta.colour[1]*.12,meta.colour[2]*.12,meta.colour[3]*.12,1},meta.colour)
    header.label=Text(header,10,meta.colour); header.label:SetPoint("LEFT",10,0); header.label:SetText(meta.label)
    header.count=Text(header,9,C.muted,"RIGHT"); header.count:SetPoint("RIGHT",-30,0)
    header.toggle=Text(header,14,meta.colour,"CENTER",true); header.toggle:SetPoint("RIGHT",-9,0)
    header:SetScript("OnClick",function(self) LP.db.collapsedPhases[self.phase]=not LP.db.collapsedPhases[self.phase]; LP:Refresh() end)
    header:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(1,1,1,1); GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(LP.db.collapsedPhases[self.phase] and "Click to expand this phase" or "Click to collapse this phase"); GameTooltip:Show() end)
    header:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(PHASES[self.phase].colour)); GameTooltip:Hide() end)
    self.stageHeaders[phase]=header; return header
end

local function CreateChip(row,width)
    local chip=CreateFrame("Frame",nil,row,"BackdropTemplate"); chip:SetSize(width,18); Backdrop(chip,{.04,.05,.06,1},C.line); chip.label=Text(chip,9,C.muted,"CENTER",true); chip.label:SetPoint("CENTER"); return chip
end

function LP:AcquireRow(index)
    if self.rows[index] then return self.rows[index] end
    local row=CreateFrame("Button",nil,self.content,"BackdropTemplate"); row:SetSize(DRAWER_CONTENT_WIDTH,86); row:RegisterForClicks("LeftButtonUp"); Backdrop(row,C.raised,C.line)
    row.rule=row:CreateTexture(nil,"ARTWORK"); row.rule:SetPoint("LEFT"); row.rule:SetSize(3,86)
    row.hoverBorder={}
    local hoverEdges={
        {"TOPLEFT",1,-1,DRAWER_CONTENT_WIDTH-2,2},
        {"BOTTOMLEFT",1,1,DRAWER_CONTENT_WIDTH-2,2},
        {"TOPLEFT",1,-1,2,84},
        {"TOPRIGHT",-1,-1,2,84},
    }
    for _,edge in ipairs(hoverEdges) do
        local border=row:CreateTexture(nil,"OVERLAY"); border:SetColorTexture(unpack(C.gold)); border:SetPoint(edge[1],edge[2],edge[3]); border:SetSize(edge[4],edge[5])
        border:Hide(); table.insert(row.hoverBorder,border)
    end
    row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(44,44); row.icon:SetPoint("LEFT",12,0); row.icon:SetTexCoord(.08,.92,.08,.92)
    row.number=Text(row,11,C.gold,"LEFT",true); row.number:SetPoint("TOPLEFT",64,-11); row.number:SetWidth(28)
    row.rankChip=CreateChip(row,68); row.rankChip:SetPoint("TOPLEFT",96,-10); row.sourceChip=CreateChip(row,120); row.sourceChip:SetPoint("LEFT",row.rankChip,"RIGHT",7,0)
    row.context=Text(row,9,C.gold,"LEFT",true); row.context:SetPoint("TOPLEFT",298,-13); row.context:SetWidth(70)
    row.level=Text(row,10,C.muted,"RIGHT"); row.level:SetPoint("TOPRIGHT",-48,-12)
    row.name=Text(row,12,C.text); row.name:SetPoint("TOPLEFT",64,-35); row.name:SetPoint("RIGHT",-48,0)
    row.source=Text(row,10,C.muted); row.source:SetPoint("BOTTOMLEFT",64,11); row.source:SetPoint("RIGHT",-48,0)
    row.check=CreateFrame("Button",nil,row,"BackdropTemplate"); row.check:SetSize(26,26); row.check:SetPoint("RIGHT",-10,0); Backdrop(row.check,{.03,.04,.05,1},C.line)
    row.tick=row.check:CreateTexture(nil,"OVERLAY"); row.tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check"); row.tick:SetAllPoints()
    row.check:SetScript("OnClick",function() if row.item then LP:ToggleItemCompleted(row.item.id); LP:Refresh() end end)
    row.check:SetScript("OnEnter",function()
        GameTooltip:SetOwner(row.check,"ANCHOR_RIGHT")
        if row.item and row.item.completed then
            GameTooltip:SetText("Marked as owned",unpack(C.gold))
            GameTooltip:AddLine("Click to remove this mark.",1,1,1)
        else
            GameTooltip:SetText("Mark as owned",unpack(C.gold))
            GameTooltip:AddLine("Manual note only; this does not equip the item.",1,1,1)
        end
        GameTooltip:Show()
    end)
    row.check:SetScript("OnLeave",function() GameTooltip:Hide() end)
    row:SetScript("OnClick",function(self) if self.item then LP:ToggleItemPreview(self.item) end end)
    row:SetScript("OnEnter",function(self)
        for _,border in ipairs(self.hoverBorder) do border:Show() end
        if self.item and self.item.link then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetHyperlink(self.item.link); GameTooltip:AddLine("Guide rank: "..tostring(self.item.listRank),1,1,1); GameTooltip:AddLine("Preview on your character.",C.gold[1],C.gold[2],C.gold[3]); GameTooltip:AddLine("Preview only; your equipped gear will not change.",unpack(C.muted)); GameTooltip:Show() end
    end)
    row:SetScript("OnLeave",function(self)
        local selected=self.item and LP.previewItem and self.item.id==LP.previewItem.id and self.item.phase==LP.previewItem.phase
        for _,border in ipairs(self.hoverBorder) do border:SetShown(selected) end
        GameTooltip:Hide()
    end); self.rows[index]=row; return row
end

function LP:Refresh()
    if not self.frame or not self.db then return end
    local _,classToken=UnitClass("player"); local _,spec=self:GetPlayerBuild(); local embeddedSpec,embeddedGuide=self:GetEmbeddedSpec(classToken,spec); local automatic=self.BIS_SPEC_MAP[classToken] and self.BIS_SPEC_MAP[classToken][spec]
    self.characterName:SetText(UnitName("player") or "Your character")
    local guideLabel
    local resolvedGuide=embeddedSpec or spec
    if not resolvedGuide then guideLabel="No guide selected"
    elseif not spec or embeddedSpec==spec then guideLabel=resolvedGuide.." guide"
    else guideLabel=spec.." · "..resolvedGuide.." guide" end
    self.characterBuild:SetText(guideLabel..(embeddedSpec==automatic and " (Auto)" or " (Selected)"))
    local previewPhase=tonumber(self.db.displayPhase) or -1; if self.modelHint then self.modelHint:SetShown(self.playerModel~=nil) end
    self:UpdatePhaseButtons(); self:UpdateSourceFilters()
    for _,button in ipairs(self.gearButtons) do self:UpdateGearButton(button) end
    if not self.drawerOpen then return end

    local selected=self:GetSlot(self.db.selectedSlot); local phase=tonumber(self.db.displayPhase) or -1; local items
    if selected and phase>=0 then items=self:GetPhaseSlotItems(selected.key,phase,true)
    else
        items=self:GetRecommendations()
    end
    self.pathTitle:SetText(selected and selected.label or "Guide choices")
    self.pathSummary:SetText("Guide-ranked as Best, Strong or Option. Filter by source.")

    local ranked={}; for _,item in ipairs(items or {}) do table.insert(ranked,item) end
    table.sort(ranked,function(a,b)
        if a.phase~=b.phase then return a.phase>b.phase end
        if (a.listOrder or 999)~=(b.listOrder or 999) then return (a.listOrder or 999)<(b.listOrder or 999) end
        return a.name<b.name
    end)
    for rank,item in ipairs(ranked) do item.drawerRank=rank end
    for _,header in pairs(self.stageHeaders) do header:Hide() end; for _,row in ipairs(self.rows) do row:Hide() end
    local y,rowIndex=0,0
    for stage=(self.BIS_DATA_META.currentPhase or 2),0,-1 do
        local stageItems={}; for _,item in ipairs(items or {}) do if item.phase==stage then table.insert(stageItems,item) end end
        table.sort(stageItems,function(a,b)
            if a.completed~=b.completed then return not a.completed end
            return (a.drawerRank or 999)<(b.drawerRank or 999)
        end)
        if #stageItems>0 then
            local collapsed=self.db.collapsedPhases[stage]
            local header=self:AcquireStageHeader(stage); header:ClearAllPoints(); header:SetPoint("TOPLEFT",0,-y); header.count:SetText(#stageItems..(#stageItems==1 and " item" or " items")); header.toggle:SetText(collapsed and "+" or "-"); header:Show(); y=y+39
            if not collapsed then
                for _,item in ipairs(stageItems) do
                    rowIndex=rowIndex+1; local row=self:AcquireRow(rowIndex); local tier=self.TIERS[item.tier]; local phaseMeta=PHASES[item.phase]; row.item=item; row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-y); row.icon:SetTexture(item.icon); row.icon:SetDesaturated(item.completed); row.rule:SetColorTexture(unpack(item.completed and C.muted or phaseMeta.colour))
                    local rankTier=self:GetRankTier(item.listRank); local rankColour=rankTier=="BEST" and C.gold or (rankTier=="STRONG" and PHASES[0].colour or C.muted)
                    row.number:SetText("#"..(item.drawerRank or rowIndex)); row.rankChip.label:SetText(self:GetRankDisplayLabel(item.listRank)); row.rankChip:SetBackdropBorderColor(unpack(rankColour)); row.rankChip.label:SetTextColor(unpack(rankColour)); row.context:SetText(item.rankContext or "")
                    row.sourceChip.label:SetText(item.sourceKind); row.sourceChip:SetBackdropBorderColor(unpack(tier.colour)); row.sourceChip.label:SetTextColor(unpack(tier.colour)); row.level:SetText(item.level>0 and ("i"..item.level) or "")
                    row.name:SetText(item.name); local qc=ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[item.quality]; if item.completed then row.name:SetTextColor(unpack(C.muted)) elseif qc then row.name:SetTextColor(qc.r,qc.g,qc.b) else row.name:SetTextColor(unpack(C.text)) end
                    local place=item.place~="" and item.place or item.sourceType; local source=item.boss~="" and item.boss or item.sourceType; local difficulty=item.difficulty~="" and (" "..item.difficulty) or ""; row.source:SetText(place.." - "..source..difficulty); row.tick:SetShown(item.completed); row:SetAlpha(item.completed and .68 or 1); row:Show(); y=y+96
                    local selected=self.previewItem and item.id==self.previewItem.id and item.phase==self.previewItem.phase; row:SetBackdropBorderColor(unpack(C.line)); for _,border in ipairs(row.hoverBorder) do border:SetShown(selected) end
                end
            end
            y=y+10
        end
    end
    if rowIndex==0 then
        if not self.empty then self.empty=Text(self.content,11,C.muted,"CENTER"); self.empty:SetPoint("TOP",0,-48); self.empty:SetWidth(350) end
        local selectedSource=self.db.selectedSource or "ALL"
        if not embeddedGuide then
            self.empty:SetText("No guide is available for this build.\nChoose a different guide above.")
        elseif #(items or {})>0 then
            self.empty:SetText("All phase sections are collapsed.\nOpen a phase to see its choices.")
        elseif selectedSource~="ALL" then
            local sourceLabel=self.TIERS[selectedSource] and self.TIERS[selectedSource].label or selectedSource
            self.empty:SetText("No "..sourceLabel.." choices are listed for "..(selected and selected.label or "this slot")..".\nChoose ALL to see every source.")
        elseif phase<0 then
            self.empty:SetText("No remaining guide choices are listed for "..(selected and selected.label or "this slot")..".\nTry another slot or phase.")
        else
            self.empty:SetText("No guide choices are listed for "..(selected and selected.label or "this slot")..".\nTry another phase or guide.")
        end
        self.empty:Show()
    elseif self.empty then self.empty:Hide() end
    self.content:SetHeight(math.max(360,y))
end
