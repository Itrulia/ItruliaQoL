local addonName, ItruliaQoL = ...
local LEM = ItruliaQoL.LEM
local LSM = ItruliaQoL.LSM
local E = ItruliaQoL.E
local moduleName = "FlyingBar"

local FlyingBar = ItruliaQoL:NewModule(moduleName)
FlyingBar.vigorSpellId = 372610
FlyingBar.secondWindSpellId = 425782
FlyingBar.whirlingSurgeSpellId = 361584

function FlyingBar:CreateBorder(f)
    local border = CreateFrame("frame", nil, f, "BackdropTemplate")
    border:SetPoint("TOPLEFT", f, 0, 0)
    border:SetPoint("BOTTOMRIGHT", f, 0, 0)
    border:SetBackdrop({
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0,0,0,1)
    border:SetBackdropColor(0,0,0,0)
    border:SetFrameStrata(f:GetFrameStrata())
    border:SetFrameLevel(f:GetFrameLevel() + 2)

    return border
end

function FlyingBar:CreateBackground(f)
    local background = CreateFrame("frame", "$parent_Background", f, "BackdropTemplate")
	background:SetAllPoints()
    background:SetFrameStrata(f:GetFrameStrata())
    background:SetFrameLevel(f:GetFrameLevel() - 1)
    background:SetBackdrop({
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        edgeSize = 1,
    })
    background:SetBackdropColor(0, 0, 0, 0.35)

    return background
end

function FlyingBar:CreateTextureBorder(f)
    f:SetClipsChildren(true)
    local border = f:CreateTexture(nil, "OVERLAY")
    border:SetWidth(1)
    border:SetPoint('TOP', f)
    border:SetPoint('BOTTOM', f)
    if f:GetStatusBarTexture() then
        border:SetPoint('RIGHT', f:GetStatusBarTexture(), 'RIGHT', 0, 0)
    end
    border:SetColorTexture(0, 0, 0, 1)

    function border:UpdatePosition()
        border:ClearAllPoints()
        border:SetPoint('TOP', f)
        border:SetPoint('BOTTOM', f)
        border:SetPoint('RIGHT', f:GetStatusBarTexture(), 'RIGHT', 0, 0)
    end

    return border
end

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetAlpha(0)
frame:SetPoint("CENTER")

frame.surge = CreateFrame("frame", "$parent_WhirlingSurge", frame)
frame.surge:SetPoint("TOPLEFT")
frame.surge:SetPoint("BOTTOMLEFT")

frame.surge.icon = frame.surge:CreateTexture(nil, 'ARTWORK')
frame.surge.icon:SetAllPoints()
frame.surge.icon:SetTexture(C_Spell.GetSpellTexture(FlyingBar.whirlingSurgeSpellId))
frame.surge.icon:SetTexCoord(.08, .92, .08, .92)

frame.surge.cd = CreateFrame('Cooldown', nil, frame.surge, 'CooldownFrameTemplate') ---@diagnostic disable-line: generic-constraint-mismatch
frame.surge.cd:SetAllPoints()
frame.surge.cd:SetHideCountdownNumbers(true)

frame.surge.border = FlyingBar:CreateBorder(frame.surge)

frame.secondWind = CreateFrame("StatusBar", "$parent_SecondWind", frame)
frame.secondWind:SetPoint("TOPLEFT", frame.surge, "TOPRIGHT", 1, 0)
frame.secondWind:SetPoint("TOPRIGHT")

for index = 1, C_Spell.GetSpellCharges(FlyingBar.secondWindSpellId).maxCharges do 
    local bar = CreateFrame("StatusBar", "$parent_" .. index, frame.secondWind)
    bar:SetMinMaxValues(0, 100)
    bar:SetPoint("TOP")
    bar:SetPoint("BOTTOM")
    bar.border = FlyingBar:CreateBorder(bar)
    bar.bg = FlyingBar:CreateBackground(bar)
    bar.textureBorder = FlyingBar:CreateTextureBorder(bar)

    if index == 1 then
        bar:SetPoint('LEFT', frame.secondWind, 0, 0)
    else
        bar:SetPoint('LEFT', frame.secondWind[index - 1], 'RIGHT', 1, 0)
    end

    frame.secondWind[index] = bar
end

frame.speed = CreateFrame("StatusBar", "$parent_Speed", frame)
frame.speed:SetPoint("TOPLEFT", frame.secondWind, "BOTTOMLEFT", 0, -1)
frame.speed:SetPoint("TOPRIGHT", frame.secondWind, "BOTTOMRIGHT", 0, -1)
frame.speed:SetMinMaxValues(0, 1440)
frame.speed.border = FlyingBar:CreateBorder(frame.speed)
frame.speed.bg = FlyingBar:CreateBackground(frame.speed)
frame.speed.textureBorder = FlyingBar:CreateTextureBorder(frame.speed)
frame.speed.tick = frame.speed:CreateTexture(nil, "OVERLAY")
frame.speed.tick:SetWidth(1)
frame.speed.tick:SetColorTexture(0, 0, 0, 1)
function frame.speed.tick:UpdatePosition()
    local parent = frame.speed.tick:GetParent();
    local width = parent:GetWidth();
    local pixelPerPower = width / select(2, parent:GetMinMaxValues())

    frame.speed.tick:ClearAllPoints()
    frame.speed.tick:SetPoint('TOP', parent)
    frame.speed.tick:SetPoint('BOTTOM', parent)
    frame.speed.tick:SetPoint('LEFT', parent, pixelPerPower * (select(2, parent:GetMinMaxValues()) / 2) - math.ceil(frame.speed.tick:GetWidth() / 2), 0)
end

frame.vigor = CreateFrame("StatusBar", "$parent_Vigor", frame)
frame.vigor:SetPoint("TOPLEFT", frame.speed, "BOTTOMLEFT", 0, -1)
frame.vigor:SetPoint("TOPRIGHT", frame.speed, "BOTTOMRIGHT", 0, -1)

for index = 1, C_Spell.GetSpellCharges(FlyingBar.vigorSpellId).maxCharges do 
    local bar = CreateFrame("StatusBar", "$parent_" .. index, frame.vigor)
    bar:SetMinMaxValues(0, 100)
    bar:SetPoint("TOP")
    bar:SetPoint("BOTTOM")
    bar.border = FlyingBar:CreateBorder(bar)
    bar.bg = FlyingBar:CreateBackground(bar)
    bar.textureBorder = FlyingBar:CreateTextureBorder(bar)

    if index == 1 then
        bar:SetPoint('LEFT', frame.vigor, 0, 0)
    else
        bar:SetPoint('LEFT', frame.vigor[index - 1], 'RIGHT', 1, 0)
    end

    frame.vigor[index] = bar
end

local function OnUpdate(self)
    local isGliding, _, forwardSpeed = C_PlayerInfo.GetGlidingInfo()

    if isGliding then
        self.speed:SetValue(forwardSpeed / BASE_MOVEMENT_SPEED * 100 + 0.5)
    else
        self.speed:SetValue(0)
    end
end

local function OnEvent(self)
    local canGlide = select(2, C_PlayerInfo.GetGlidingInfo())
    self:SetAlphaFromBoolean(canGlide, 1, 0)

    if canGlide then
        frame:SetScript("OnUpdate", OnUpdate)
    else
        frame:SetScript("OnUpdate", nil)
        return
    end

    local vigorCharges = C_Spell.GetSpellCharges(FlyingBar.vigorSpellId)
    local secondWindCharges = C_Spell.GetSpellCharges(FlyingBar.secondWindSpellId)

    local vigorDuration = C_Spell.GetSpellChargeDuration(FlyingBar.vigorSpellId)
    local secondWindDuration = C_Spell.GetSpellChargeDuration(FlyingBar.secondWindSpellId)

    local whilringSurgeCd = C_Spell.GetSpellCooldown(FlyingBar.whirlingSurgeSpellId)

    if whilringSurgeCd.isEnabled and whilringSurgeCd.duration and whilringSurgeCd.duration then
        self.surge.cd:SetCooldown(whilringSurgeCd.startTime, whilringSurgeCd.duration)
    end

    for i, bar in ipairs(self.vigor) do
        if vigorCharges.currentCharges >= i then
            bar:SetMinMaxValues(0, 1)
            bar:SetValue(1)
        elseif vigorDuration and i == vigorCharges.currentCharges + 1 then
            bar:SetTimerDuration(vigorDuration)
        else
            bar:SetMinMaxValues(0, 1)
            bar:SetValue(0)
        end
	end

    for i, bar in ipairs(self.secondWind) do
        if secondWindCharges.currentCharges >= i then
            bar:SetMinMaxValues(0, 1)
            bar:SetValue(1)
        elseif secondWindDuration and i == secondWindCharges.currentCharges + 1 then
            bar:SetTimerDuration(secondWindDuration)
        else
            bar:SetMinMaxValues(0, 1)
            bar:SetValue(0)
        end
	end
end

frame:RegisterEvent('SPELL_UPDATE_COOLDOWN')
frame:RegisterEvent('SPELL_UPDATE_CHARGES')
frame:RegisterEvent('PLAYER_ENTERING_WORLD')
frame:RegisterEvent("PLAYER_CAN_GLIDE_CHANGED")
frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")

function frame:UpdateStyles()
    self:SetSize(
        FlyingBar.db.width, 
        FlyingBar.db.vigor.height + FlyingBar.db.speed.height + FlyingBar.db.secondWind.height + 2
    )
    self:SetFrameStrata(FlyingBar.db.frameStrata or "BACKGROUND")
    self:SetFrameLevel(FlyingBar.db.frameLevel or 1)

    self.surge:SetWidth(FlyingBar.db.vigor.height + FlyingBar.db.speed.height + FlyingBar.db.secondWind.height + 2)
    self.secondWind:SetHeight(FlyingBar.db.secondWind.height)
    self.speed:SetHeight(FlyingBar.db.speed.height)
    self.vigor:SetHeight(FlyingBar.db.vigor.height)

    self.speed:SetStatusBarTexture(LSM:Fetch("statusbar", FlyingBar.db.speed.statusbarTexture))
    self.speed:SetStatusBarColor(FlyingBar.db.speed.color.r, FlyingBar.db.speed.color.g, FlyingBar.db.speed.color.b, FlyingBar.db.speed.color.a)
    self.speed.tick:UpdatePosition()
    self.speed.textureBorder:UpdatePosition()

    local frameWidth = self.speed:GetWidth()

    for i, bar in ipairs(self.vigor) do
        bar:SetWidth((frameWidth - (#self.vigor - 1)) / #self.vigor)
        bar:SetStatusBarTexture(LSM:Fetch("statusbar", FlyingBar.db.vigor.statusbarTexture))
        bar:SetStatusBarColor(FlyingBar.db.vigor.color.r, FlyingBar.db.vigor.color.g, FlyingBar.db.vigor.color.b, FlyingBar.db.vigor.color.a)
        bar.textureBorder:UpdatePosition()
	end

    for i, bar in ipairs(self.secondWind) do
        bar:SetWidth((frameWidth - (#self.secondWind - 1)) / #self.secondWind)
        bar:SetStatusBarTexture(LSM:Fetch("statusbar", FlyingBar.db.secondWind.statusbarTexture))
        bar:SetStatusBarColor(FlyingBar.db.secondWind.color.r, FlyingBar.db.secondWind.color.g, FlyingBar.db.secondWind.color.b, FlyingBar.db.secondWind.color.a)
        bar.textureBorder:UpdatePosition()
	end
end

function FlyingBar:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile[moduleName] = profile[moduleName] or self:GetDefaults()
    self.db = profile[moduleName]
end

function FlyingBar:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile[moduleName] = profile[moduleName] or self:GetDefaults()
    self.db = profile[moduleName]

    if self.db.enabled then
        frame:Show()
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
        OnEvent(frame)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
    end
end

function FlyingBar:OnEnable()
    if self.db.enabled then 
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil,
            nil,
            nil,
            "ALL,ITRULIA",
            function()
                return self.db.enabled
            end,
            addonName .. "," .. moduleName
        )
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end
end

function FlyingBar:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end)
end