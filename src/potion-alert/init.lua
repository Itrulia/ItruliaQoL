local addonName, ItruliaQoL = ...
local moduleName = "PotionAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local PotionAlert = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 300)
frame:SetSize(28, 28)

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 14, "OUTLINE")
frame.text:SetTextColor(1, 1, 1, 1)
frame.text:SetJustifyH("CENTER")
frame.text:Hide();

frame.onCD = false
frame.potions = {
    -- TWW
    212263, -- Tempered Potion
    212264, -- Tempered Potion
    212265, -- Tempered Potion
    -- Midnight
    241292, -- Draught of Rampant Abandon
    241293, -- Draught of Rampant Abandon
    241308, -- Light's Potential
    241309, -- Light's Potential
}

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(PotionAlert.db.point.point, PotionAlert.db.point.x, PotionAlert.db.point.y)
        end

        self:SetFrameStrata(PotionAlert.db.font.frameStrata or "BACKGROUND")
        self:SetFrameLevel(PotionAlert.db.font.frameLevel or 1)
        self.text:ClearAllPoints()
        self.text:SetPoint(PotionAlert.db.font.justifyH or "CENTER")
        self.text:SetJustifyH(PotionAlert.db.font.justifyH or "CENTER")
        self.text:SetText(PotionAlert.db.displayText)
        self.text:SetTextColor(PotionAlert.db.color.r, PotionAlert.db.color.g, PotionAlert.db.color.b, PotionAlert.db.color.a)
        if PotionAlert.db.font.fontOutline ~= ItruliaQoL.OutlineSettings.OUTLINESLUG then
            self.text:SetShadowColor(PotionAlert.db.font.fontShadowColor.r, PotionAlert.db.font.fontShadowColor.g, PotionAlert.db.font.fontShadowColor.b, PotionAlert.db.font.fontShadowColor.a)
            self.text:SetShadowOffset(PotionAlert.db.font.fontShadowXOffset, PotionAlert.db.font.fontShadowYOffset)
        else
            self.text:SetShadowColor(0, 0, 0, 0)
            self.text:SetShadowOffset(0, 0)
        end
        self.text:SetFont(LSM:Fetch("font", PotionAlert.db.font.fontFamily), PotionAlert.db.font.fontSize, PotionAlert.db.font.fontOutline)
        self:SetSize(math.max(self.text:GetStringWidth(), 28), math.max(self.text:GetStringHeight(), 28))
    end
end

local function OnEvent(self, event, ...)
    self.text:Hide()

    if event == "ENCOUNTER_START" then
        -- Makes it so at the start of a boss fight you wont be told it's off cd
        self.onCD = false
    end

    if ItruliaQoL.testMode then
        self.text:Show()
        return
    end

    local potion
    for _, v in ipairs(self.potions) do
        local _, _, enabled = C_Container.GetItemCooldown(v)

        if enabled then
            potion = v
            break;
        end
    end

    if not potion then
        return
    end

    if 
        (PotionAlert.db.enabledInDungeons and ItruliaQoL:InMythicDungeon()) 
        or (PotionAlert.db.enabledInRaids and ItruliaQoL:InRaid() and PlayerIsInCombat()) 
    then
        local start = C_Container.GetItemCooldown(potion)

        if start == 0 then
            if self.onCD then
                if PotionAlert.db.playSound and PotionAlert.db.sound then
                    PlaySoundFile(LSM:Fetch("sound", PotionAlert.db.sound), "Master")
                elseif PotionAlert.db.playTTS and PotionAlert.db.tts then
                    C_VoiceChat.SpeakText(0, PotionAlert.db.tts, 1, PotionAlert.db.ttsVolume, true)
                end
            end

            self.onCD = false
            self.text:Show()
        else
            self.onCD = true
        end
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("BAG_UPDATE_COOLDOWN") -- doesn't fire often in dungeons/raids
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("ENCOUNTER_START")

function PotionAlert:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.PotionAlert = profile.PotionAlert or self:GetDefaults()
    self.db = profile.PotionAlert
end

function PotionAlert:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.PotionAlert = profile.PotionAlert or self:GetDefaults()
    self.db = profile.PotionAlert

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
        OnEvent(frame)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function PotionAlert:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    self.db.font.justifyH = font.justifyH
    frame:UpdateStyles()
end

function PotionAlert:OnEnable()
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

function PotionAlert:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function PotionAlert:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
        OnEvent(frame)
    end)
end
