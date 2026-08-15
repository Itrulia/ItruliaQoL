local addonName, ItruliaQoL = ...
local moduleName = "MovementAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local MovementAlert = ItruliaQoL:NewModule(moduleName)

local movementAbilities = {
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
local timeSpiralAbilities = {
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

local spellsThatTriggerGlows = {
	DEMONHUNTER = {
        [577] = {
            { talent = 427640, spellId = 370965, delay = 1 }, -- Inertia / The hunt
            { talent = 427640, spellId = 198793 }, -- Inertia / Vengeful retreat
            { talent = 427794, spellId = 195072 }, -- Dash of Chaos / Fel Rush
        },
	},
    WARLOCK = {
        [265] = {
            { talent = 385899, spellId = 385899 } -- Soulburn
        },
        [266] = {
            { talent = 385899, spellId = 385899 } -- Soulburn
        },
        [267] = {
            { talent = 385899, spellId = 385899 } -- Soulburn
        },
    },
}

local spellsWithOwnGCD = {
	[1234796] = 0.8
}

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

                if
                    not self.ignoreMovementCd
                    and cdInfo
                    and cdInfo.timeUntilEndOfStartRecovery
                    and not cdInfo.isOnGCD
                    -- cdInfo.isOnGCD is nil when double jumping (evoker / dh)
                    -- WL teleport isOnGCD exists while on gcd and then is nil
                    and (cdInfo.isOnGCD ~= nil or ItruliaQoL.PlayerClass == "WARLOCK")
                then
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

local function OnEvent(self, event, ...)
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
                    C_VoiceChat.SpeakText(MovementAlert.db.timeSpiralTTSVoice, MovementAlert.db.timeSpiralTTS, 1, MovementAlert.db.timeSpiralTTSVolume, true)
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

function MovementAlert:GenerateFrame(name, parent)
    local frame = CreateFrame("frame", name, parent or UIParent)
    PixelUtil.SetPoint(frame, "CENTER", frame:GetParent() or UIParent, "CENTER", 0, 300)
    PixelUtil.SetSize(frame, 28, 28)
    frame.movementId = nil;
    frame.movementName = nil;
    frame.ignoreMovementCd = false
    frame.spellsToIgnoreGlowsFrom = {}
    frame.timeSpiralOn = false;
    frame.ignoreGlow = false

    frame.movementAbilities = movementAbilities
    frame.timeSpiralAbilities = timeSpiralAbilities
    frame.spellsThatTriggerGlows = spellsThatTriggerGlows
    frame.spellsThatHaveTheirOwnGCD = spellsWithOwnGCD

    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetPoint("CENTER")
    frame.text:SetFont(LSM:Fetch("font", "Expressway"), 14, "OUTLINE")
    frame.text:SetTextColor(1, 1, 1, 1)
    frame.text:SetJustifyH("CENTER")
    frame.text:Hide();

    function frame:GetSpellToCheck()
        local class = ItruliaQoL.PlayerClass
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
        for _, spell in ipairs(spellIds) do
            if spell and ItruliaQoL:IsSpellKnown(spell) then
                spellId = spell
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
        local class = ItruliaQoL.PlayerClass
        local specId = select(1, GetSpecializationInfo(GetSpecialization()))
        local specs = self.spellsThatTriggerGlows[class]

        if not specs or not specId then
            return nil
        end

        if not specs[specId] then
            return nil
        end

        local ignoredList = {}
        for _, entry in ipairs(specs[specId]) do
            if ItruliaQoL:IsSpellKnown(entry.talent) then
                ignoredList[entry.spellId] = 0.05 + (entry.delay or 0)
            end
        end

        return ignoredList
    end

    function frame:CacheMovementId()
        self.movementId = self:GetSpellToCheck()
        local spellInfo = self.movementId and C_Spell.GetSpellInfo(self.movementId)
        self.movementName = spellInfo and spellInfo.name
        self.spellsToIgnoreGlowsFrom = self:GetSpellsToIgnoreGlowsFrom()
    end

    function frame:UpdateStyles()
        if not E then
            self:ClearAllPoints()
            PixelUtil.SetPoint(self, MovementAlert.db.point.point, self:GetParent() or UIParent, MovementAlert.db.point.point, MovementAlert.db.point.x, MovementAlert.db.point.y)
        end

        self:SetFrameStrata(MovementAlert.db.font.frameStrata or "BACKGROUND")
        self:SetFrameLevel(MovementAlert.db.font.frameLevel or 1)
        self.text:ClearAllPoints()
        self.text:SetPoint(MovementAlert.db.font.justifyH or "CENTER")
        self.text:SetJustifyH(MovementAlert.db.font.justifyH or "CENTER")
        self.text:SetTextColor(MovementAlert.db.color.r, MovementAlert.db.color.g, MovementAlert.db.color.b, MovementAlert.db.color.a)
        if MovementAlert.db.font.fontOutline ~= "OUTLINESLUG" then
            self.text:SetShadowColor(MovementAlert.db.font.fontShadowColor.r, MovementAlert.db.font.fontShadowColor.g, MovementAlert.db.font.fontShadowColor.b, MovementAlert.db.font.fontShadowColor.a)
            self.text:SetShadowOffset(MovementAlert.db.font.fontShadowXOffset, MovementAlert.db.font.fontShadowYOffset)
        else
            self.text:SetShadowColor(0, 0, 0, 0)
            self.text:SetShadowOffset(0, 0)
        end
        self.text:SetFont(LSM:Fetch("font", MovementAlert.db.font.fontFamily), MovementAlert.db.font.fontSize, MovementAlert.db.font.fontOutline)

        if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
            PixelUtil.SetSize(self, math.max(self.text:GetStringWidth(), 28), math.max(self.text:GetStringHeight(), 28))
        end
    end

    return frame
end

function MovementAlert:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local frame = self:GenerateFrame(addonName .. moduleName)
    self.frame = frame

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("PLAYER_TALENT_UPDATE")
    frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")

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
    elseif ItruliaQoL.EUI then
        ItruliaQoL:CreateEUIMover(self, frame, moduleName)
    else
        LEM:AddFrame(frame, function(_, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end

    return frame
end

function MovementAlert:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.MovementAlert = profile.MovementAlert or self:GetDefaults()
    self.db = profile.MovementAlert

    -- Migration
    self.db.timeSpiralTTSVoice = self.db.timeSpiralTTSVoice or self:GetDefaults().timeSpiralTTSVoice
end

function MovementAlert:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.MovementAlert = profile.MovementAlert or self:GetDefaults()
    self.db = profile.MovementAlert

    if self.db.enabled then
        local frame = self:EnsureFrame()

        frame:UpdateStyles()
        frame:CacheMovementId()
        frame:SetScript("OnEvent", OnEvent)
        frame:SetScript("OnUpdate", OnUpdate)
        OnEvent(frame)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
        self.frame:SetScript("OnUpdate", nil)
        self.frame.text:Hide()
    end
end

function MovementAlert:ApplyFontSettings(font)
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

function MovementAlert:OnEnable()
    self:RefreshConfig()
end

function MovementAlert:ToggleTestMode()
    if not self.db.enabled or not self.frame then
        return
    end

    OnEvent(self.frame)
end

function MovementAlert:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
        end

        ItruliaQoL:RefreshPreview(self)
    end)
end
