local addonName, ItruliaQoL = ...
local moduleName = "RaidConsumesAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local RaidConsumesAlert = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 100)
frame:SetSize(28, 28)

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetTextColor(1, 1, 1)
frame.text:SetJustifyH("CENTER")
-- needs a non empty text to restore frame position
frame.text:SetText(" ")

frame.anim = frame.text:CreateAnimationGroup()
frame.anim:SetScript("OnFinished", function() 
    frame.text:SetText(" ") 
    frame.text:SetAlpha(0) 
end)
frame.alpha = frame.anim:CreateAnimation("Alpha")
frame.alpha:SetFromAlpha(1)
frame.alpha:SetToAlpha(0)
frame.alpha:SetDuration(1)
frame.alpha:SetStartDelay(4)

frame.spells = {
    [698] = "SUMMONING_STONE",
    [29893] = "SOULWELL",

    [199109] = "REPAIR_BOT", -- Auto-Hammer
    [67826] = "REPAIR_BOT", -- Jeeves

    -- TWW
    [457285] = "FEAST", -- Midnight Masquerade
    [462213] = "HEARTY_FEAST", -- Hearty Midnight Masquerade

    [457283] = "FEAST", -- Divine Day
    [462212] = "HEARTY_FEAST", -- Hearty Divine Day

    [433292] = "CAULDRON", -- Algari Potion Cauldron
    [432877] = "CAULDRON", -- Algari Flask Cauldron

    -- Midnight
    [1259657] = "FEAST", -- Quel'dorei Medley	
    [1278915] = "HEARTY_FEAST", -- Hearty Quel'dorei Medley	

    [1259658] = "FEAST", -- Harandar Celebration
    [1278929] = "HEARTY_FEAST", -- Hearty Rootland Celebration

    [1237104] = "FEAST", -- Blooming Feast
    [1278909] = "HEARTY_FEAST", -- Hearty Blooming Feast

    [1259659] = "FEAST", -- Silvermoon Parade
    [1278895] = "HEARTY_FEAST", -- Hearty Silvermoon Parade

    [1240267] = "CAULDRON", -- Voidlight Potion Cauldron
    [1240195] = "CAULDRON", -- Voidlight of Sin'dorei Flasks
}

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(RaidConsumesAlert.db.point.point, RaidConsumesAlert.db.point.x, RaidConsumesAlert.db.point.y)
        end

        self:SetFrameStrata(RaidConsumesAlert.db.frameStrata or "BACKGROUND")
        self:SetFrameLevel(RaidConsumesAlert.db.frameLevel or 1)
        self.text:SetTextColor(RaidConsumesAlert.db.color.r, RaidConsumesAlert.db.color.g, RaidConsumesAlert.db.color.b, RaidConsumesAlert.db.color.a)
        self.text:SetFont(LSM:Fetch("font", RaidConsumesAlert.db.font.fontFamily), RaidConsumesAlert.db.font.fontSize, RaidConsumesAlert.db.font.fontOutline)
        self.text:SetShadowColor(RaidConsumesAlert.db.font.fontShadowColor.r, RaidConsumesAlert.db.font.fontShadowColor.g, RaidConsumesAlert.db.font.fontShadowColor.b, RaidConsumesAlert.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(RaidConsumesAlert.db.font.fontShadowXOffset, RaidConsumesAlert.db.font.fontShadowYOffset)

        self:SetSize(frame.text:GetStringWidth(), frame.text:GetStringHeight())
    end
end

local function OnEvent(self, event, unitTarget, castGUID, spellId)
    if ItruliaQoL.testMode then
        self.text:SetText(RaidConsumesAlert.db.feast.displayText)
        self.text:SetAlpha(1)
    elseif not event then 
        -- disabling of testMode
        self.text:SetAlpha(0)
        frame.text:SetText(" ") 
    elseif InCombatLockdown() then
        self.text:SetAlpha(0)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local laundredSpellId = ItruliaQoL:LaunderSecretValue(spellId)

        if not canaccessvalue(laundredSpellId) then
            return
        end

        local type = self.spells[laundredSpellId]

        if not type then
            return
        end

        if not UnitInParty(unitTarget) and not UnitInRaid(unitTarget) and not unitTarget == "player" then
            return
        end

        local settings;
        if type == "SOULWELL" then
            settings = RaidConsumesAlert.db.soulwell
        elseif type == "SUMMONING_STONE" then
            settings = RaidConsumesAlert.db.summonStone
        elseif type == "CAULDRON" then
            settings = RaidConsumesAlert.db.cauldron
        elseif type == "REPAIR_BOT" then
            settings = RaidConsumesAlert.db.repairBot
        elseif type == "HEARTY_FEAST" then
            settings = RaidConsumesAlert.db.heartyFeast
        elseif type == "FEAST" then
            settings = RaidConsumesAlert.db.feast
        else
            return
        end

        if not settings.enabled then
            return
        end

        self.text:SetText(settings.displayText)
        self.text:SetAlpha(1)
        self.anim:Stop()
        self.anim:Play()

        if settings.playSound and settings.sound then
            PlaySoundFile(LSM:Fetch("sound", settings.sound), "Master")
        elseif settings.playTTS and settings.tts then
            C_VoiceChat.SpeakText(0, settings.tts, 1, settings.ttsVolume, true)
        end
    end

    self:UpdateStyles()
end

frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

function RaidConsumesAlert:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.RaidConsumesAlert = profile.RaidConsumesAlert or self:GetDefaults()
    self.db = profile.RaidConsumesAlert

    -- Migrate new consume types
    self.db.repairBot = self.db.repairBot or self:GetDefaults().repairBot;
end

function RaidConsumesAlert:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.RaidConsumesAlert = profile.RaidConsumesAlert or self:GetDefaults()
    self.db = profile.RaidConsumesAlert

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function RaidConsumesAlert:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    frame:UpdateStyles()
end

function RaidConsumesAlert:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil, nil, nil, nil, nil)
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end
end

function RaidConsumesAlert:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function RaidConsumesAlert:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end)
end