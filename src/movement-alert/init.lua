local addonName, ItruliaQoL = ...
local moduleName = "MovementAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local MovementAlert = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 300)
frame:SetSize(28, 28)
frame.movementId = nil;
frame.movementName = nil;
frame.ignoreMovementCd = false
frame.spellsToIgnoreGlowsFrom = {}
frame.timeSpiralOn = false;
frame.ignoreGlow = false

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 14, "OUTLINE")
frame.text:SetTextColor(1, 1, 1, 1)
frame.text:SetJustifyH("CENTER")
frame.text:Hide();

frame.movementAbilities = {
    DEATHKNIGHT = {[250] = {48265}, [251] = {48265}, [252] = {48265}},
    DEMONHUNTER = {[577] = {195072}, [581] = {189110}, [1480] = {1234796}},
    DRUID = {[102] = {102401, 252216, 1850}, [103] = {102401, 252216, 1850}, [104] = {102401, 106898}, [105] = {102401, 252216, 1850}},
    EVOKER = {[1467] = {358267}, [1468] = {358267}, [1473] = {358267}},
    HUNTER = {[253] = {781}, [254] = {781}, [255] = {781}},
    MAGE = {[62] = {212653, 1953}, [63] = {212653, 1953}, [64] = {212653, 1953}},
    MONK = {[268] = {115008, 109132}, [269] = {109132}, [270] = {109132}},
    PALADIN = {[65] = {190784} , [66] = {190784} , [70] = {190784} },
    PRIEST = {[256] = {121536,73325}, [257] = {121536,73325}, [258] = {121536,73325}},
    ROGUE = {[259] = {36554}, [260] = {195457}, [261] = {36554}},
    SHAMAN = {[262] = {79206, 90328, 192063}, [263] = {90328, 192063}, [264] = {79206, 90328, 192063}},
    WARLOCK = {[265] = {48020}, [266] = {48020}, [267] = {48020}},
    WARRIOR = {[71] = {6544}, [72] = {6544}, [73] = {6544}}
}

-- List taken from: https://www.curseforge.com/wow/addons/time-spiral-tracker
frame.timeSpiralAbilities = {
    -- DK
    [48265] = true, -- Death's Advance
    -- DH
    [195072] = true, -- Fel Rush
    [189110] = true, -- Infernal Strike
    [1234796] = true, -- Shift
    -- Druid
    [1850] = true, -- Dash
    [252216] = true, -- Tiger Dash
    -- Evoker
    [358267] = true, -- Hover
    -- Hunter
    [186257] = true, -- Aspect of the Cheetah
    -- Mage
    [212653] = true, -- Shimmer
    [1953] = true, -- Blink
    -- Monk
    [119085] = true, -- Chi Torpedo
    [361138] = true, -- Roll
    -- Paladin
    [190784] = true, -- Divine Steed
    -- Priest lmao
    [73325] = false, -- Leap of Faith
    -- Rogue
    [2983] = true, -- Sprint
    -- Shaman
    [192063] = true, -- Gust of Wind
    [58875] = true, -- Spirit Walk
    [79206] = true, -- Spiritwalker's Grace
    -- Warlock
    [48020] = true, -- Demonic Circle: Teleport
    -- Warrior
    [6544] = true, -- Heroic Leap
}

frame.spellsThatTriggerGlows = {
	DEMONHUNTER = {
        [577] = {
            { talent = 427640, spellId = 370965, delay = 1 }, -- Inertia / The hunt
            { talent = 427640, spellId = 198793 }, -- Inertia / Vengeful retreat
            { talent = 427794, spellId = 195072 }, -- Dash of Chaos / Fel Rush
        },
	},
    WARLOCK = {
        [265] = { talent = 385899, spellId = 385899 }, -- Soulburn 
        [266] = { talent = 385899, spellId = 385899 }, -- Soulburn
        [267] = { talent = 385899, spellId = 385899 }, -- Soulburn
    },
}

frame.spellsThatHaveTheirOwnGCD = {
	[1234796] = 0.8
}

function frame:GetSpellToCheck()
    local class = select(2, UnitClass("player"))
    local specId = select(1, GetSpecializationInfo(GetSpecialization()))
    local spells = self.movementAbilities[class]

    if not spells or not specId then 
        return nil
    end

    local spellIds = spells[specId]
    if not spellIds then
        return nil
    end

    local spellId
    for _, s in ipairs(spellIds) do
        if s and ItruliaQoL:IsSpellKnown(s) then
            spellId = s
            break
        end
    end

    if not spellId then
        return nil
    end

    local spellInfo = C_Spell.GetSpellInfo(spellId)
    if not spellInfo then
        return nil
    end

    return spellId
end

function frame:GetSpellsToIgnoreGlowsFrom()
    local class = select(2, UnitClass("player"))
    local specId = select(1, GetSpecializationInfo(GetSpecialization()))
    local specs = self.spellsThatTriggerGlows[class]

    if not specs or not specId then 
        return nil
    end

    local ignoreList = specs[specId]
    if not ignoreList then
        return nil
    end

    local ignoredList = {}
    for _, s in ipairs(specs[specId]) do
        if ItruliaQoL:IsSpellKnown(s.talent) then
            ignoredList[s.spellId] = 0.05 + (s.delay or 0)
        end
    end

    return ignoredList
end

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(MovementAlert.db.point.point, MovementAlert.db.point.x, MovementAlert.db.point.y)
        end

        self:SetFrameStrata(MovementAlert.db.font.frameStrata or "BACKGROUND")
        self:SetFrameLevel(MovementAlert.db.font.frameLevel or 1)
        self.text:SetTextColor(MovementAlert.db.color.r, MovementAlert.db.color.g, MovementAlert.db.color.b, MovementAlert.db.color.a)
        self.text:SetFont(LSM:Fetch("font", MovementAlert.db.font.fontFamily), MovementAlert.db.font.fontSize, MovementAlert.db.font.fontOutline)
        self.text:SetShadowColor(MovementAlert.db.font.fontShadowColor.r, MovementAlert.db.font.fontShadowColor.g, MovementAlert.db.font.fontShadowColor.b, MovementAlert.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(MovementAlert.db.font.fontShadowXOffset, MovementAlert.db.font.fontShadowYOffset);
        self:SetSize(math.max(self.text:GetStringWidth(), 28), math.max(self.text:GetStringHeight(), 28))
    end
end

local function OnUpdate(self, elapsed, ...)
    if not self.timeSinceLastUpdate then 
        self.timeSinceLastUpdate = 0 
    end

    self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
    
    if self.timeSinceLastUpdate > MovementAlert.db.updateInterval then
        if not ItruliaQoL.testMode then
            if self.timeSpiralOn then
                local timeSpiralText = CreateColor(
                    MovementAlert.db.timeSpiralColor.r,
                    MovementAlert.db.timeSpiralColor.g, 
                    MovementAlert.db.timeSpiralColor.b, 
                    MovementAlert.db.timeSpiralColor.a
                ):WrapTextInColorCode(MovementAlert.db.timeSpiralText .. "\n" .. string.format(
                    "%." .. MovementAlert.db.precision .. "f", 10 - (GetTime() - self.timeSpiralOn)
                ))
                self.text:SetText(timeSpiralText)
                self.text:Show()
            elseif self.movementId and self.movementName then
                local cdInfo = C_Spell.GetSpellCooldown(self.movementId)

                -- cdInfo.isOnGCD is nil when double jumping (evoker / dh)
                if not self.ignoreMovementCd and cdInfo and cdInfo.timeUntilEndOfStartRecovery and not cdInfo.isOnGCD and cdInfo.isOnGCD ~= nil then
                    self.text:SetText("No " .. self.movementName .. "\n" .. string.format("%." .. MovementAlert.db.precision .. "f", cdInfo.timeUntilEndOfStartRecovery))
                    self.text:Show()
                else
                    self.text:Hide()
                end
            else
                self.text:Hide()
            end
        end

        self.timeSinceLastUpdate = 0
    end
end

function frame:CacheMovementId()
    self.movementId = self:GetSpellToCheck()
    local spellInfo = self.movementId and C_Spell.GetSpellInfo(self.movementId)
    self.movementName = spellInfo and spellInfo.name
    self.spellsToIgnoreGlowsFrom = self:GetSpellsToIgnoreGlowsFrom()
end

local function OnEvent(self, event, ...)
    self:UpdateStyles()

    if not InCombatLockdown() then
        self:CacheMovementId()
    end

    if ItruliaQoL.testMode then
        self.text:SetText("No " .. (self.movementName or "movement ability") .. "\n" .. string.format("%." .. MovementAlert.db.precision .. "f", 15.3))
        self.text:Show()
        return
    end

    if MovementAlert.db.showTimeSpiral then
        local spellId = ...
        if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" and not self.ignoreGlow then
            if self.timeSpiralAbilities[spellId] then
                self.timeSpiralOn = GetTime();

                if MovementAlert.db.timeSpiralPlaySound and MovementAlert.db.timeSpiralSound then
                    PlaySoundFile(LSM:Fetch("sound", MovementAlert.db.timeSpiralSound), "Master")
                elseif MovementAlert.db.timeSpiralPlayTTS and MovementAlert.db.timeSpiralTTS then
                    C_VoiceChat.SpeakText(0, MovementAlert.db.timeSpiralTTS, 1, MovementAlert.db.timeSpiralTTSVolume, true)
                end
            end
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
            if self.timeSpiralAbilities[spellId] then
                self.timeSpiralOn = nil;
            end
        elseif event == "UNIT_SPELLCAST_SENT" then
            local spellId = select(4, ...)

            if self.spellsToIgnoreGlowsFrom and self.spellsToIgnoreGlowsFrom[spellId] then
                self.ignoreGlow = true

                C_Timer.After(self.spellsToIgnoreGlowsFrom[spellId], function() 
                    self.ignoreGlow = false;
                end)
            end

            if self.spellsThatHaveTheirOwnGCD[spellId] then
                self.ignoreMovementCd = true

                C_Timer.After(self.spellsThatHaveTheirOwnGCD[spellId], function() 
                    self.ignoreMovementCd = false;
                end)
            end
        else
            self.timeSpiralOn = nil;
        end
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")

function MovementAlert:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.MovementAlert = profile.MovementAlert or self:GetDefaults()
    self.db = profile.MovementAlert
end

function MovementAlert:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.MovementAlert = profile.MovementAlert or self:GetDefaults()
    self.db = profile.MovementAlert

    if self.db.enabled then
        frame:UpdateStyles()
        frame:CacheMovementId()
        frame:SetScript("OnEvent", OnEvent)
        frame:SetScript("OnUpdate", OnUpdate) 
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function MovementAlert:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    frame:UpdateStyles()
end

function MovementAlert:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
        frame:SetScript("OnUpdate", OnUpdate) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil, nil, nil, nil, nil)
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end
end

function MovementAlert:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function MovementAlert:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end)
end
