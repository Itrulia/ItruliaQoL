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
        if not canaccessvalue(spellId) then
            return
        end

        local type = self.spells[spellId]

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

local defaults = {
    enabled = false,
    color = {r = 1, g = 1, b = 1, a = 1},
    point = {point = "CENTER", x = 0, y = 100},

    feast = {
        enabled = true,
        displayText = "Eat feast",
        playSound = false,
        sound = nil,
        playTTS = false,
        tts = nil,
        ttsVolume = 50,
    },
    heartyFeast = {
        enabled = true,
        displayText = "Eat **hearty** feast",
        playSound = false,
        sound = nil,
        playTTS = false,
        tts = nil,
        ttsVolume = 50,
    },
    cauldron = {
        enabled = true,
        displayText = "Grab flask and potions",
        playSound = false,
        sound = nil,
        playTTS = false,
        tts = nil,
        ttsVolume = 50,
    },
    soulwell = {
        enabled = true,
        displayText = "Grab healthstone",
        playSound = false,
        sound = nil,
        playTTS = false,
        tts = nil,
        ttsVolume = 50,
    },
    summonStone = {
        enabled = true,
        displayText = "Help summon",
        playSound = false,
        sound = nil,
        playTTS = false,
        tts = nil,
        ttsVolume = 50,
    },

    font = {
        fontFamily = "Expressway",
        fontSize = 28,
        fontOutline = "OUTLINE",
        fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
        fontShadowXOffset = 1,
        fontShadowYOffset = -1,
    }
};

function RaidConsumesAlert:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.RaidConsumesAlert = profile.RaidConsumesAlert or defaults
    self.db = profile.RaidConsumesAlert
end

function RaidConsumesAlert:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.RaidConsumesAlert = profile.RaidConsumesAlert or defaults
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
        end, defaults.point)
    end
end

function RaidConsumesAlert:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

local createConsumeTypeOptions = function (consumeType)
   return {
        enable = {
            order = 1,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function()
                return RaidConsumesAlert.db[consumeType].enabled
            end,
            set = function(_, value)
                RaidConsumesAlert.db[consumeType].enabled = value
            end
        },
        displayText = {
            order = 2,
            type = "input",
            name = "Display text",
            width = "full",
            get = function()
                return RaidConsumesAlert.db[consumeType].displayText
            end,
            set = function(_, value)
                RaidConsumesAlert.db[consumeType].displayText = value
            end,
        },
        soundGroup = {
            type = "group",
            name = "",
            order = 3,
            inline = true,
            args = {
                playSound = {
                    order = 1,
                    type = "toggle",
                    name = "Play sound",
                    get = function() 
                        return RaidConsumesAlert.db[consumeType].playSound
                    end,
                    set = function(_, value)
                        RaidConsumesAlert.db[consumeType].playSound = value
                    end,
                },
                sound = {
                    order = 2,
                    type = "select",
                    dialogControl = "LSM30_Sound", 
                    name = "Sound",
                    values = LSM:HashTable("sound"),
                    get = function()
                        return RaidConsumesAlert.db[consumeType].sound
                    end,
                    set = function(_, value)
                        RaidConsumesAlert.db[consumeType].sound = value
                    end,
                    disabled = function()
                        return not RaidConsumesAlert.db[consumeType].playSound
                    end,
                },
                clear = {
                    order = 3,
                    type = "execute",
                    name = "Clear",
                    width = 0.5,
                    func = function()
                        RaidConsumesAlert.db[consumeType].sound = nil
                    end,
                    disabled = function()
                        return not RaidConsumesAlert.db[consumeType].playSound or not RaidConsumesAlert.db[consumeType].enabled
                    end
                },
            }
        },
        ttsGroup = {
            type = "group",
            name = "",
            order = 4,
            inline = true,
            args = {
                playTTS = {
                    order = 1,
                    type = "toggle",
                    name = "Play a TTS sound",
                    get = function() 
                        return RaidConsumesAlert.db[consumeType].playTTS
                    end,
                    set = function(_, value)
                        RaidConsumesAlert.db[consumeType].playTTS = value
                    end,
                },
                tts = {
                    order = 2,
                    type = "input",
                    name = "TTS Message",
                    get = function()
                        return RaidConsumesAlert.db[consumeType].tts
                    end,
                    set = function(_, value)
                        RaidConsumesAlert.db[consumeType].tts = value
                    end,
                    disabled = function()
                        return not RaidConsumesAlert.db[consumeType].playTTS
                    end,
                },
                ttsVolume = {
                    order = 3,
                    type = "range",
                    min = 0,
                    max = 100,
                    step = 1,
                    name = "TTS Volume",
                    get = function()
                        return RaidConsumesAlert.db[consumeType].ttsVolume
                    end,
                    set = function(_, value)
                        RaidConsumesAlert.db[consumeType].ttsVolume = value
                    end,
                    disabled = function()
                        return not RaidConsumesAlert.db[consumeType].playTTS
                    end,
                },
            },
            disabled = function()
                return RaidConsumesAlert.db[consumeType].playSound
            end,
        },
   } 
end

local options = {
    order = 2,
    type = "group",
    name = "Raid Consumes Alert",
    args = {
        description = {
            type = "description",
            name = "Displays an alert when a raid consume has been popped (or a summoning stone) \n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function()
                return RaidConsumesAlert.db.enabled
            end,
            set = function(_, value)
                RaidConsumesAlert.db.enabled = value

                RaidConsumesAlert:RefreshConfig()
                if value then
                    OnEvent(frame)
                end
            end
        },
        color = {
            order = 3,
            type = "color",
            name = "Color",
            hasAlpha = true,
            get = function()
                local c = RaidConsumesAlert.db.color
                return c.r, c.g, c.b, c.a
            end,
            set = function(_, r, g, b, a)
                RaidConsumesAlert.db.color = {
                    r = r,
                    g = g,
                    b = b,
                    a = a
                }
                frame:UpdateStyles()
            end
        },
        fontSettings = {
            type = "group",
            name = "",
            order = 4,
            inline = true,
            args = {
                font = {
                    order = 1,
                    type = "select",
                    dialogControl = "LSM30_Font",
                    name = "Font",
                    values = LSM:HashTable("font"),
                    get = function()
                        return RaidConsumesAlert.db.font.fontFamily
                    end,
                    set = function(_, value)
                        RaidConsumesAlert.db.font.fontFamily = value
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
                        return RaidConsumesAlert.db.font.fontSize
                    end,
                    set = function(_, value)
                        RaidConsumesAlert.db.font.fontSize = value
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
                        return RaidConsumesAlert.db.font.fontOutline
                    end,
                    set = function(_, value)
                        RaidConsumesAlert.db.font.fontOutline = value ~= "NONE" and value or nil
                        frame:UpdateStyles()
                    end
                },
                spacer = {
                    type = "description",
                    name = " ",
                    width = "full",
                    order = 4,
                },
                fontShadowColor = {
                    order = 5,
                    type = "color",
                    name = "Shadow Color",
                    hasAlpha = true,
                    get = function()
                        local c = RaidConsumesAlert.db.font.fontShadowColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        RaidConsumesAlert.db.font.fontShadowColor = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        frame:UpdateStyles()
                    end
                },
                fontShadowXOffset = {
                    order = 6,
                    type = "range",
                    name = "Shadow X Offset",
                    min = -5,
                    max = 5,
                    step = 1,
                    get = function()
                        return RaidConsumesAlert.db.font.fontShadowXOffset
                    end,
                    set = function(_, value)
                        RaidConsumesAlert.db.font.fontShadowXOffset = value
                        frame:UpdateStyles()
                    end
                },
                fontShadowYOffset = {
                    order = 57,
                    type = "range",
                    name = "Shadow Y Offset",
                    min = -5,
                    max = 5,
                    step = 1,
                    get = function()
                        return RaidConsumesAlert.db.font.fontShadowYOffset
                    end,
                    set = function(_, value)
                        RaidConsumesAlert.db.font.fontShadowYOffset = value
                        frame:UpdateStyles()
                    end
                },
            }
        },
        consumeType = {
            type = "group",
            name = "",
            order = 5,
            inline = true,
            args = {
                feast = {
                    type = "group",
                    name = "Feast",
                    order = 1,
                    inline = true,
                    args = createConsumeTypeOptions("feast"),
                },
                heartyFeast = {
                    type = "group",
                    name = "Hearty feast",
                    order = 2,
                    inline = true,
                    args = createConsumeTypeOptions("heartyFeast"),
                },
                cauldron = {
                    type = "group",
                    name = "Cauldron",
                    order = 3,
                    inline = true,
                    args = createConsumeTypeOptions("cauldron"),
                },
                soulwell = {
                    type = "group",
                    name = "Soulwell",
                    order = 4,
                    inline = true,
                    args = createConsumeTypeOptions("soulwell"),
                },
                summonStone = {
                    type = "group",
                    name = "Summon stone",
                    order = 5,
                    inline = true,
                    args = createConsumeTypeOptions("summonStone"),
                },
            },
        },
    }
}

function RaidConsumesAlert:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = options;
end