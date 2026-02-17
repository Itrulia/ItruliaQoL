local addonName, ItruliaQoL = ...
local moduleName = "RebuffReminder"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local RebuffReminder = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 300)
frame:SetSize(28, 28)
frame.needsRebuff = false

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 14, "OUTLINE")
frame.text:SetTextColor(1, 1, 1, 1)
frame.text:SetJustifyH("CENTER")
frame.text:Hide();

frame.buffAbilities = {
    [1459] = true, -- arcane intellect
    [6673] = true, -- battle shout
    [1126] = true, -- mark of the wild
    [462854] = true, -- skyfury
    [21562] = true, -- power word: fortitute
}

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(RebuffReminder.db.point.point, RebuffReminder.db.point.x, RebuffReminder.db.point.y)
        end

        self:SetFrameStrata(RebuffReminder.db.font.frameStrata or "BACKGROUND")
        self:SetFrameLevel(RebuffReminder.db.font.frameLevel or 1)
        self.text:SetText(RebuffReminder.db.displayText)
        self.text:SetJustifyH(RebuffReminder.db.font.justifyH or "CENTER")
        self.text:SetTextColor(RebuffReminder.db.color.r, RebuffReminder.db.color.g, RebuffReminder.db.color.b, RebuffReminder.db.color.a)
        self.text:SetFont(LSM:Fetch("font", RebuffReminder.db.font.fontFamily), RebuffReminder.db.font.fontSize, RebuffReminder.db.font.fontOutline)
        self.text:SetShadowColor(RebuffReminder.db.font.fontShadowColor.r, RebuffReminder.db.font.fontShadowColor.g, RebuffReminder.db.font.fontShadowColor.b, RebuffReminder.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(RebuffReminder.db.font.fontShadowXOffset, RebuffReminder.db.font.fontShadowYOffset);
        self:SetSize(math.max(self.text:GetStringWidth(), 28), math.max(self.text:GetStringHeight(), 28))
    end
end

local function OnEvent(self, event, ...)
    if ItruliaQoL.testMode then
        print("LMAO")
        self.text:Show()
        return
    elseif not event then
        self.text:Hide()
        return
    end

    local spellId = ...
    if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
        if self.buffAbilities[spellId] then
            self.needsRebuff = true
        end
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        if self.buffAbilities[spellId] then
            self.needsRebuff = false
        end
    end

    if self.needsRebuff and (
        event == "READY_CHECK" 
        or event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" 
        or event == "PLAYER_REGEN_ENABLED"
        or event == "PLAYER_REGEN_DISABLED"
    ) then
        if PlayerIsInCombat() or RebuffReminder.db.alertWhenIdle then
            self.text:Show()

            if RebuffReminder.db.playSound and RebuffReminder.db.sound then
                PlaySoundFile(LSM:Fetch("sound", RebuffReminder.db.sound), "Master")
            elseif RebuffReminder.db.playTTS and RebuffReminder.db.tts then
                C_VoiceChat.SpeakText(0, RebuffReminder.db.tts, 1, RebuffReminder.db.ttsVolume, true)
            end
        else
            self.text:Hide()
        end
    elseif not self.needsRebuff then
        self.text:Hide()
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
frame:RegisterEvent("READY_CHECK")

function RebuffReminder:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.RebuffReminder = profile.RebuffReminder or self:GetDefaults()
    self.db = profile.RebuffReminder
end

function RebuffReminder:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.RebuffReminder = profile.RebuffReminder or self:GetDefaults()
    self.db = profile.RebuffReminder

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function RebuffReminder:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    self.db.font.justifyH = font.justifyH
    frame:UpdateStyles()
end

function RebuffReminder:OnEnable()
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
                return self.db.enable
            end,
            addonName .. "," .. moduleName
        )
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end
end

function RebuffReminder:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function RebuffReminder:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end)
end
