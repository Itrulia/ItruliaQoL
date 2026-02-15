local addonName, ItruliaQoL = ...
local moduleName = "FocusInterruptIndicator"
local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local FocusInterruptIndicator = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", UIParent, 0, 150)
frame:SetSize(28, 28)
frame.active = false
frame.interruptId = nil
frame.notInterruptible = nil;

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetTextColor(1, 1, 1)
frame.text:SetJustifyH("CENTER")
frame.text:SetText("INTERRUPT")
frame.text:Hide()

frame.interruptSpells = {
    DEATHKNIGHT = {[250] = 47528, [251] = 47528, [252] = 47528},
    DEMONHUNTER = {[577] = 183752, [581] = 183752, [1480] = 183752},
    DRUID = {[102] = 78675, [103] = 106839, [104] = 106839, [105] = nil},
    EVOKER = {[1467] = 351338, [1468] = 351338, [1473] = 351338},
    HUNTER = {[253] = 147362, [254] = 147362, [255] = 187707},
    MAGE = {[62] = 2139, [63] = 2139, [64] = 2139},
    MONK = {[268] = 116705, [269] = 116705, [270] = nil},
    PALADIN = {[65] = nil, [66] = 96231, [70] = 96231},
    PRIEST = {[256] = nil, [257] = nil, [258] = 15487},
    ROGUE = {[259] = 1766, [260] = 1766, [261] = 1766},
    SHAMAN = {[262] = 57994, [263] = 57994, [264] = 57994},
    WARLOCK = {[265] = 19647, [266] = 119914, [267] = 19647},
    WARRIOR = {[71] = 6552, [72] = 6552, [73] = 6552}
}

function frame:UpdateFocusInterruptIndicator(active)
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

function frame:GetSpellToCheck()
    local class = select(2, UnitClass("player"))
    local specId = select(1, GetSpecializationInfo(GetSpecialization()))

    return self.interruptSpells[class][specId]
end

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(FocusInterruptIndicator.db.point.point, FocusInterruptIndicator.db.point.x, FocusInterruptIndicator.db.point.y)
        end

        self:SetFrameStrata(FocusInterruptIndicator.db.frameStrata or "BACKGROUND")
        self:SetFrameLevel(FocusInterruptIndicator.db.frameLevel or 1)
        self.text:SetText(FocusInterruptIndicator.db.displayText)
        self.text:SetTextColor(FocusInterruptIndicator.db.color.r, FocusInterruptIndicator.db.color.g, FocusInterruptIndicator.db.color.b, FocusInterruptIndicator.db.color.a)
        self.text:SetFont(LSM:Fetch("font", FocusInterruptIndicator.db.font.fontFamily), FocusInterruptIndicator.db.font.fontSize, FocusInterruptIndicator.db.font.fontOutline)
        self.text:SetShadowColor(FocusInterruptIndicator.db.font.fontShadowColor.r, FocusInterruptIndicator.db.font.fontShadowColor.g, FocusInterruptIndicator.db.font.fontShadowColor.b, FocusInterruptIndicator.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(FocusInterruptIndicator.db.font.fontShadowXOffset, FocusInterruptIndicator.db.font.fontShadowYOffset)
        self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
    end
end

function frame:CacheInterruptId()
    self.interruptId = self:GetSpellToCheck()
end

local function OnEvent(self, event, unit, ...)
    self.active = false
    self:UpdateStyles()

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

    self.text:Show()
    self.text:SetAlphaFromBoolean(C_Spell.GetSpellCooldownDuration(self.interruptId):IsZero())
    self:SetAlphaFromBoolean(self.notInterruptible, 0, 1)
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "focus")
frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "focus")
frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "focus")
frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "focus")
frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "focus")
frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "focus")

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
        frame:UpdateStyles()
        frame:CacheInterruptId()
        frame:SetScript("OnEvent", OnEvent)
        frame:SetScript("OnUpdate", OnUpdate)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function FocusInterruptIndicator:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    frame:UpdateStyles()
end

function FocusInterruptIndicator:OnEnable()
    if self.db.enabled then
        frame:SetScript("OnEvent", OnEvent)
        frame:SetScript("OnUpdate", OnUpdate)
    end

    if E then
        E:CreateMover(
            frame,               
            frame:GetName() .. "Mover",   
            frame:GetName(),
            nil, 
            nil, 
            nil, 
            nil, 
            nil
        )
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, { point = "CENTER", x = 0, y = 150 })
    end
end

function FocusInterruptIndicator:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function FocusInterruptIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end);
end