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

local function OnUpdate(self)
    local isGliding, _, forwardSpeed = C_PlayerInfo.GetGlidingInfo()

    if isGliding then
        self.speed:SetValue(forwardSpeed / BASE_MOVEMENT_SPEED * 100 + 0.5, Enum.StatusBarInterpolation.ExponentialEaseOut)
    else
        self.speed:SetValue(0, Enum.StatusBarInterpolation.ExponentialEaseOut)
    end
end

local function OnEvent(self)
    local canGlide = select(2, C_PlayerInfo.GetGlidingInfo())
    self:SetAlphaFromBoolean(canGlide, 1, 0)

    if canGlide then
        self:SetScript("OnUpdate", OnUpdate)
    else
        self:SetScript("OnUpdate", nil)
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
            bar:SetTimerDuration(vigorDuration, Enum.StatusBarInterpolation.ExponentialEaseOut)
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


function FlyingBar:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)
    f:SetAlpha(0)
    f:SetPoint("CENTER")

    f.surge = CreateFrame("frame", "$parent_WhirlingSurge", f)
    f.surge:SetPoint("TOPLEFT")
    f.surge:SetPoint("BOTTOMLEFT")

    f.surge.icon = f.surge:CreateTexture(nil, 'ARTWORK')
    f.surge.icon:SetAllPoints()
    f.surge.icon:SetTexture(C_Spell.GetSpellTexture(FlyingBar.whirlingSurgeSpellId))
    f.surge.icon:SetTexCoord(.08, .92, .08, .92)

    f.surge.cd = CreateFrame('Cooldown', nil, f.surge, 'CooldownFrameTemplate') ---@diagnostic disable-line: generic-constraint-mismatch
    f.surge.cd:SetAllPoints()
    f.surge.cd:SetHideCountdownNumbers(true)

    f.surge.border = FlyingBar:CreateBorder(f.surge)

    f.vigor = CreateFrame("StatusBar", "$parent_Vigor", f)
    f.vigor:SetPoint("TOPLEFT", f.surge, "TOPRIGHT", 1, 0)
    f.vigor:SetPoint("TOPRIGHT")

    for index = 1, C_Spell.GetSpellCharges(FlyingBar.vigorSpellId).maxCharges do
        local bar = CreateFrame("StatusBar", "$parent_" .. index, f.vigor)
        bar:SetMinMaxValues(0, 100)
        bar:SetPoint("TOP")
        bar:SetPoint("BOTTOM")
        bar.border = FlyingBar:CreateBorder(bar)
        bar.bg = FlyingBar:CreateBackground(bar)
        bar.textureBorder = FlyingBar:CreateTextureBorder(bar)

        if index == 1 then
            bar:SetPoint('LEFT', f.vigor, 0, 0)
        else
            bar:SetPoint('LEFT', f.vigor[index - 1], 'RIGHT', 1, 0)
        end

        f.vigor[index] = bar
    end

    f.speed = CreateFrame("StatusBar", "$parent_Speed", f)
    f.speed:SetPoint("TOPLEFT", f.vigor, "BOTTOMLEFT", 0, -1)
    f.speed:SetPoint("TOPRIGHT", f.vigor, "BOTTOMRIGHT", 0, -1)
    f.speed:SetMinMaxValues(0, 1440)
    f.speed.border = FlyingBar:CreateBorder(f.speed)
    f.speed.bg = FlyingBar:CreateBackground(f.speed)
    f.speed.textureBorder = FlyingBar:CreateTextureBorder(f.speed)
    f.speed.tick = f.speed:CreateTexture(nil, "OVERLAY")
    f.speed.tick:SetWidth(1)
    f.speed.tick:SetColorTexture(0, 0, 0, 1)

    -- `self`, not the live frame's tick: a preview instance must place its own.
    function f.speed.tick:UpdatePosition()
        -- `owner`, not `parent`: GenerateFrame's own `parent` is in scope here.
        local owner = self:GetParent();
        local width = owner:GetWidth();
        local pixelPerPower = width / select(2, owner:GetMinMaxValues())

        self:ClearAllPoints()
        self:SetPoint('TOP', owner)
        self:SetPoint('BOTTOM', owner)
        self:SetPoint('LEFT', owner, pixelPerPower * (select(2, owner:GetMinMaxValues()) / 2) - math.ceil(self:GetWidth() / 2), 0)
    end

    f.secondWind = CreateFrame("StatusBar", "$parent_SecondWind", f)
    f.secondWind:SetPoint("TOPLEFT", f.speed, "BOTTOMLEFT", 0, -1)
    f.secondWind:SetPoint("TOPRIGHT", f.speed, "BOTTOMRIGHT", 0, -1)

    for index = 1, C_Spell.GetSpellCharges(FlyingBar.secondWindSpellId).maxCharges do
        local bar = CreateFrame("StatusBar", "$parent_" .. index, f.secondWind)
        bar:SetMinMaxValues(0, 100)
        bar:SetPoint("TOP")
        bar:SetPoint("BOTTOM")
        bar.border = FlyingBar:CreateBorder(bar)
        bar.bg = FlyingBar:CreateBackground(bar)
        bar.textureBorder = FlyingBar:CreateTextureBorder(bar)

        if index == 1 then
            bar:SetPoint('LEFT', f.secondWind, 0, 0)
        else
            bar:SetPoint('LEFT', f.secondWind[index - 1], 'RIGHT', 1, 0)
        end

        f.secondWind[index] = bar
    end

    function f:UpdateStyles()
        if not E then
            self:ClearAllPoints()
            self:SetPoint(FlyingBar.db.point.point, FlyingBar.db.point.x, FlyingBar.db.point.y)
        end

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

    return f
end

-- Returns the live instance, building it on the first call and reusing it after that.
--
-- The mover is registered here rather than in OnEnable so a module switched on later
-- in the session still gets one; ElvUI, EllesmereUI and LibEditMode all accept a
-- late registration.
function FlyingBar:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent('SPELL_UPDATE_COOLDOWN')
    f:RegisterEvent('SPELL_UPDATE_CHARGES')
    f:RegisterEvent('PLAYER_ENTERING_WORLD')
    f:RegisterEvent("PLAYER_CAN_GLIDE_CHANGED")
    f:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    f:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")

    if E then
        E:CreateMover(f, f:GetName() .. "Mover", moduleName, nil,
            nil,
            nil,
            "ALL,ITRULIA",
            function()
                return self.db.enabled
            end,
            addonName .. "," .. moduleName
        )
    elseif ItruliaQoL.EUI then
        ItruliaQoL:CreateEUIMover(self, f, moduleName)
    else
        LEM:AddFrame(f, function(_, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end

    return f
end

function FlyingBar:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile[moduleName] = profile[moduleName] or self:GetDefaults()
    self.db = profile[moduleName]

    if not self.db.point then
        self.db.point = self:GetDefaults().point
    end
end

function FlyingBar:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile[moduleName] = profile[moduleName] or self:GetDefaults()
    self.db = profile[moduleName]

    if self.db.enabled then
        local f = self:EnsureFrame()

        f:Show()
        f:UpdateStyles()
        f:SetScript("OnEvent", OnEvent)
        OnEvent(f)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
        self.frame:SetScript("OnUpdate", nil)
        self.frame:Hide()
    end
end

function FlyingBar:OnEnable()
    self:RefreshConfig()
end

function FlyingBar:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
        end
    end)
end
