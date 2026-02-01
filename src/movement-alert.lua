local addonName, ItruliaQoL = ...
local moduleName = "MovementAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E
local C = ItruliaQoL.C
local CD = ItruliaQoL.CD

local MovementAlert = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 300)
frame:SetSize(28, 28)
frame.movementId = nil;
frame.movementName = nil;
frame.timeSpiralOn = false;

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 14, "OUTLINE")
frame.text:SetTextColor(1, 1, 1, 1)
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
    [73325] = true, -- Leap of Faith
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

function frame:GetSpellToCheck()
    local class = select(2, UnitClass("player"))
    local specId = select(1, GetSpecializationInfo(GetSpecialization()))
    local spells = frame.movementAbilities[class]

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

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(MovementAlert.db.point.point, MovementAlert.db.point.x, MovementAlert.db.point.y)
        end

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
                ):WrapTextInColorCode(MovementAlert.db.timeSpiralText)
                self.text:SetText(timeSpiralText)
                self.text:Show()
            elseif self.movementId then
                local cdInfo = C_Spell.GetSpellCooldown(self.movementId)

                -- cdInfo.isOnGCD is nil when double jumping (evoker / dh)
                if cdInfo and cdInfo.timeUntilEndOfStartRecovery and not cdInfo.isOnGCD and cdInfo.isOnGCD ~= nil then
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
end

local function OnEvent(self, event, ...)
    self:UpdateStyles()

    if not InCombatLockdown() then
        self:CacheMovementId()
    end

    if ItruliaQoL.testMode then
        self.text:SetText("No " .. self.movementName .. "\n" .. string.format("%." .. MovementAlert.db.precision .. "f", 15.3))
        self.text:Show()
        return
    end

    if MovementAlert.db.showTimeSpiral then
        local spellId = ...
        if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
            if self.timeSpiralAbilities[spellId] then
                self.timeSpiralOn = true;

                if MovementAlert.db.showTimeSpiral and MovementAlert.db.timeSpiralPlaySound and MovementAlert.db.timeSpiralSound then
                    PlaySoundFile(LSM:Fetch("sound", MovementAlert.db.timeSpiralSound), "Master")
                end
            end
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
            if self.timeSpiralAbilities[spellId] then
                self.timeSpiralOn = false;
            end
        else
            self.timeSpiralOn = false;
        end
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
frame:RegisterUnitEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
frame:RegisterUnitEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")

local defaults = {
    enabled = true,
    precision = 0,
    color = {r = 1, g = 1, b = 1, a = 1},
    updateInterval = 0.1,
    point = {point = "CENTER", x = 0, y = 50},
    showTimeSpiral = true,
    timeSpiralText = "Free Movement",
    timeSpiralColor = {r = 0.5333333611488342, g = 1, b = 0, a = 1},
    timeSpiralPlaySound = false,
    timeSpiralSound = nil,

    font = {
        fontFamily = "Expressway",
        fontSize = 14,
        fontOutline = "OUTLINE",
        fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
        fontShadowXOffset = 1,
        fontShadowYOffset = -1,
    }
}

function MovementAlert:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.MovementAlert = profile.MovementAlert or defaults
    self.db = profile.MovementAlert
end

function MovementAlert:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.MovementAlert = profile.MovementAlert or defaults
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
        end, {point = "CENTER", x = 0, y = 50})
    end
end

function MovementAlert:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

local options = {
    type = "group",
    name = "Movement Alert",
    order = 2,
    args = {
        description = {
            type = "description",
            name =  "Displays a text when your most important movement ability is on cooldown or time spiral is active\n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function(info)
                return MovementAlert.db.enabled
            end,
            set = function(info, value)
                MovementAlert.db.enabled = value
                MovementAlert:RefreshConfig()
            end
        },
        displaySettings = {
            type = "group",
            name = "",
            order = 4,
            guiInline = true,
            args = {
                color = {
                    order = 2,
                    type = "color",
                    name = "Color",
                    hasAlpha = true,
                    get = function()
                        local c = MovementAlert.db.color
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        MovementAlert.db.color = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        frame:UpdateStyles()
                    end
                },
                decimals = {
                    order = 3,
                    type = "range",
                    min = 0,
                    max = 1,
                    step = 1,
                    name = "Decimal precision",
                    get = function()
                        return MovementAlert.db.precision
                    end,
                    set = function(_, value)
                        MovementAlert.db.precision = value
                        frame:UpdateStyles()
                    end
                },
            }
        },
        fontSettings = {
            type = "group",
            name = "",
            order = 5,
            guiInline = true,
            args = {
                font = {
                    order = 1,
                    type = "select",
                    dialogControl = "LSM30_Font",
                    name = "Font",
                    values = LSM:HashTable("font"),
                    get = function()
                        return MovementAlert.db.font.fontFamily
                    end,
                    set = function(_, value)
                        MovementAlert.db.font.fontFamily = value
                        frame:UpdateStyles()
                    end
                },
                fontSize = {
                    order = 2,
                    type = "range",
                    name = "Size",
                    min = 1,
                    max = 68,
                    step = 1,
                    get = function()
                        return MovementAlert.db.font.fontSize
                    end,
                    set = function(_, value)
                        MovementAlert.db.font.fontSize = value
                        frame:UpdateStyles()
                    end
                },
                fontOutline = {
                    order = 3,
                    type = "select",
                    name = "Outline",
                    values = {
                        NONE = "None",
                        OUTLINE = "Outline",
                        THICKOUTLINE = "Thick Outline",
                        MONOCHROME = "Monochrome"
                    },
                    get = function()
                        return MovementAlert.db.font.fontOutline
                    end,
                    set = function(_, value)
                        MovementAlert.db.font.fontOutline = value ~= "NONE" and value or nil
                        frame:UpdateStyles()
                    end
                },
                fontShadowColor = {
                    order = 4,
                    type = "color",
                    name = "Shadow Color",
                    hasAlpha = true,
                    get = function()
                        local c = MovementAlert.db.font.fontShadowColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        MovementAlert.db.font.fontShadowColor = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        frame:UpdateStyles()
                    end
                },
                fontShadowXOffset = {
                    order = 5,
                    type = "range",
                    name = "Shadow X Offset",
                    min = -5,
                    max = 5,
                    step = 1,
                    get = function()
                        return MovementAlert.db.font.fontShadowXOffset
                    end,
                    set = function(_, value)
                        MovementAlert.db.font.fontShadowXOffset = value
                        frame:UpdateStyles()
                    end
                },
                fontShadowYOffset = {
                    order = 5,
                    type = "range",
                    name = "Shadow Y Offset",
                    min = -5,
                    max = 5,
                    step = 1,
                    get = function()
                        return MovementAlert.db.font.fontShadowYOffset
                    end,
                    set = function(_, value)
                        MovementAlert.db.font.fontShadowYOffset = value
                        frame:UpdateStyles()
                    end
                },
            }
        },
        spacer = {
            type = "description",
            name = " ",
            width = "full",
            order = 6,
        },
        timeSpiralSettings = {
            type = "group",
            name = "Time spiral",
            order = 7,
            guiInline = true,
            args = {
                showTimeSpiral = {
                    order = 1,
                    type = "toggle",
                    width = "full",
                    name = "Enable",
                    get = function(info)
                        return MovementAlert.db.showTimeSpiral
                    end,
                    set = function(info, value)
                        MovementAlert.db.showTimeSpiral = value
                    end
                },
                timeSpiralText = {
                    order = 2,
                    type = "input",
                    name = "Time spiral text",
                    get = function()
                        return MovementAlert.db.timeSpiralText
                    end,
                    set = function(_, value)
                        MovementAlert.db.timeSpiralText = value
                    end,
                    disabled = function()
                        return not MovementAlert.db.showTimeSpiral
                    end,
                },
                timeSpiralColor = {
                    order = 3,
                    type = "color",
                    name = "Time spiral color",
                    hasAlpha = true, 
                    get = function()
                        local c = MovementAlert.db.timeSpiralColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        MovementAlert.db.timeSpiralColor = {
                            r = r,
                            g = g,
                            b = b,
                            a = a,
                        }
                    end,
                    disabled = function()
                        return not MovementAlert.db.showTimeSpiral
                    end,
                },
                soundGroup = {
                    type = "group",
                    name = "",
                    order = 4,
                    guiInline = true,
                    args = {
                        timeSpiralPlaySound = {
                            order = 1,
                            type = "toggle",
                            name = "Play sound when time spiral becomes active",
                            get = function() 
                                return MovementAlert.db.timeSpiralPlaySound
                            end,
                            set = function(_, value)
                                MovementAlert.db.timeSpiralPlaySound = value
                            end,
                        },
                        timeSpiralSound = {
                            order = 2,
                            type = "select",
                            dialogControl = "LSM30_Sound", 
                            name = "Sound",
                            values = LSM:HashTable("sound"),
                            get = function()
                                return MovementAlert.db.timeSpiralSound
                            end,
                            set = function(_, value)
                                MovementAlert.db.timeSpiralSound = value
                            end,
                            disabled = function()
                                return not MovementAlert.db.timeSpiralPlaySound
                            end,
                        },
                    },
                    disabled = function()
                        return not MovementAlert.db.showTimeSpiral
                    end,
                },
            }
        }
    }
}

function MovementAlert:RegisterOptions(parentCategory, parentOptions)
    if E then
        E.Options.args[addonName].args[moduleName] = options
        C:RegisterOptionsTable(moduleName, options)
    else
        parentOptions.args[moduleName] = options;
        CD:AddToBlizOptions(moduleName, "Movement Alert", parentCategory)
    end
end