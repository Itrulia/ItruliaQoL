local addonName, ItruliaQoL = ...
local moduleName = "PotionAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local PotionAlert = ItruliaQoL:NewModule(moduleName)

local POTIONS = {
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
                elseif PotionAlert.db.playTTS and PotionAlert.db.TTS then
                    C_VoiceChat.SpeakText(0, PotionAlert.db.TTS, 1, PotionAlert.db.TTSVolume, true)
                end
            end

            self.onCD = false
            self.text:Show()
        else
            self.onCD = true
        end
    end
end

function PotionAlert:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)
    f:SetPoint("CENTER", 0, 300)
    f:SetSize(28, 28)

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("CENTER")
    f.text:SetFont(LSM:Fetch("font", "Expressway"), 14, "OUTLINE")
    f.text:SetTextColor(1, 1, 1, 1)
    f.text:SetJustifyH("CENTER")
    f.text:Hide();

    f.onCD = false
    f.potions = POTIONS

    function f:UpdateStyles()
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
            if PotionAlert.db.font.fontOutline ~= "OUTLINESLUG" then
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

    return f
end

function PotionAlert:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("BAG_UPDATE_COOLDOWN") -- doesn't fire often in dungeons/raids
    f:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("ENCOUNTER_START")

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
        local f = self:EnsureFrame()

        f:UpdateStyles()
        f:SetScript("OnEvent", OnEvent)
        OnEvent(f)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
        self.frame:SetScript("OnUpdate", nil)
        self.frame.text:Hide()
    end
end

function PotionAlert:ApplyFontSettings(font)
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

function PotionAlert:OnEnable()
    self:RefreshConfig()
end

function PotionAlert:ToggleTestMode()
    if not self.db.enabled or not self.frame then
        return
    end

    OnEvent(self.frame)
end

function PotionAlert:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
            OnEvent(self.frame)
        end
    end)
end
