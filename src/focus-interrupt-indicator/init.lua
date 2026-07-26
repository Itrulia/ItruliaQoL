local addonName, ItruliaQoL = ...
local moduleName = "FocusInterruptIndicator"
local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local FocusInterruptIndicator = ItruliaQoL:NewModule(moduleName)

local function OnEvent(self, event, unit, ...)
    self.active = false

    if ItruliaQoL.testMode then
        self.text:Show()
        self.text:SetAlpha(1)
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        self:CacheInterruptId()
        return
    end

    if unit and UnitCanAttack("player", unit) then
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "PLAYER_FOCUS_CHANGED" then
            self:UpdateFocusInterruptIndicator(true)
        end
    end
end

local function OnUpdate(self)
    if ItruliaQoL.testMode then
        self:SetAlpha(1)
        self.text:Show()
        return
    end

    if not self.active then
        self.text:Hide()
        self.text:SetAlpha(0)
        return
    end

    if self.interruptId then
        self.text:Show()
        self.text:SetAlphaFromBoolean(C_Spell.GetSpellCooldownDuration(self.interruptId):IsZero())
        self:SetAlphaFromBoolean(self.notInterruptible, 0, 1)
    end
end

function FocusInterruptIndicator:GenerateFrame(frameName, parent)
    local f = CreateFrame("frame", frameName, parent or UIParent)
    f:SetPoint("CENTER", parent or UIParent, 0, 150)
    f:SetSize(28, 28)
    f.active = false
    f.interruptId = nil
    f.notInterruptible = nil;

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("CENTER")
    f.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
    f.text:SetTextColor(1, 1, 1)
    f.text:SetJustifyH("CENTER")
    f.text:SetText("INTERRUPT")
    f.text:Hide()

    function f:UpdateFocusInterruptIndicator(active)
        self.active = active

        if not self.active then
            return
        end

        local name, _, _, _, _, _, _, notInterruptible = UnitChannelInfo("focus")
        if not name then
            name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("focus")
        end

        if not name then
            self.active = false
            return
        end

        self.notInterruptible = notInterruptible;

        if FocusInterruptIndicator.db.playSound and FocusInterruptIndicator.db.sound then
            PlaySoundFile(LSM:Fetch("sound", FocusInterruptIndicator.db.sound), "Master")
        elseif FocusInterruptIndicator.db.playTTS and FocusInterruptIndicator.db.TTS then
            C_VoiceChat.SpeakText(0, FocusInterruptIndicator.db.TTS, 1, FocusInterruptIndicator.db.TTSVolume, true)
        end
    end

    function f:CacheInterruptId()
        self.interruptId = ItruliaQoL:GetInterruptSpell()
    end

    function f:UpdateStyles()
        if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
            if not E then
                self:ClearAllPoints()
                self:SetPoint(FocusInterruptIndicator.db.point.point, FocusInterruptIndicator.db.point.x, FocusInterruptIndicator.db.point.y)
            end

            self:SetFrameStrata(FocusInterruptIndicator.db.font.frameStrata or "BACKGROUND")
            self:SetFrameLevel(FocusInterruptIndicator.db.font.frameLevel or 1)
            self.text:ClearAllPoints()
            self.text:SetPoint(FocusInterruptIndicator.db.font.justifyH or "CENTER")
            self.text:SetJustifyH(FocusInterruptIndicator.db.font.justifyH or "CENTER")
            self.text:SetText(FocusInterruptIndicator.db.displayText)
            self.text:SetTextColor(FocusInterruptIndicator.db.color.r, FocusInterruptIndicator.db.color.g, FocusInterruptIndicator.db.color.b, FocusInterruptIndicator.db.color.a)
            if FocusInterruptIndicator.db.font.fontOutline ~= "OUTLINESLUG" then
                self.text:SetShadowColor(FocusInterruptIndicator.db.font.fontShadowColor.r, FocusInterruptIndicator.db.font.fontShadowColor.g, FocusInterruptIndicator.db.font.fontShadowColor.b, FocusInterruptIndicator.db.font.fontShadowColor.a)
                self.text:SetShadowOffset(FocusInterruptIndicator.db.font.fontShadowXOffset, FocusInterruptIndicator.db.font.fontShadowYOffset)
            else
                self.text:SetShadowColor(0, 0, 0, 0)
                self.text:SetShadowOffset(0, 0)
            end
            self.text:SetFont(LSM:Fetch("font", FocusInterruptIndicator.db.font.fontFamily), FocusInterruptIndicator.db.font.fontSize, FocusInterruptIndicator.db.font.fontOutline)
            self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
        end
    end

    return f
end

function FocusInterruptIndicator:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    f:RegisterEvent("PLAYER_FOCUS_CHANGED")
    f:RegisterUnitEvent("UNIT_SPELLCAST_START", "focus")
    f:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "focus")
    f:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "focus")
    f:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "focus")
    f:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "focus")
    f:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "focus")

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

function FocusInterruptIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.FocusInterruptIndicator = profile.FocusInterruptIndicator or self:GetDefaults()
    self.db = profile.FocusInterruptIndicator
end

function FocusInterruptIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.FocusInterruptIndicator = profile.FocusInterruptIndicator or self:GetDefaults()
    self.db = profile.FocusInterruptIndicator

    if self.db.enabled then
        local f = self:EnsureFrame()

        f:UpdateStyles()
        f:CacheInterruptId()
        f:SetScript("OnEvent", OnEvent)
        f:SetScript("OnUpdate", OnUpdate)
        OnEvent(f)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
        self.frame:SetScript("OnUpdate", nil)
        self.frame.text:Hide()
    end
end

function FocusInterruptIndicator:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    self.db.font.justifyH = font.justifyH

    if self.frame then
        self.frame:UpdateStyles()
    end
end

function FocusInterruptIndicator:OnEnable()
    self:RefreshConfig()
end

function FocusInterruptIndicator:ToggleTestMode()
    if not self.db.enabled or not self.frame then
        return
    end

    OnEvent(self.frame)
end

function FocusInterruptIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
        end

        ItruliaQoL:RefreshPreview(self)
    end);
end
