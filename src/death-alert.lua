local addonName, ItruliaQoL = ...
local moduleName = "DeathAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local DeathAlert = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 300)
frame:SetSize(28, 28)
frame.lastSoundPlayedAt = nil

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetTextColor(1, 1, 1)
frame.text:SetJustifyH("CENTER")

frame.text.anim = frame.text:CreateAnimationGroup()
frame.text.anim:SetScript("OnFinished", function() 
    frame.text:SetText("") 
end)
frame.alpha = frame.text.anim:CreateAnimation("Alpha")
frame.alpha:SetFromAlpha(1)
frame.alpha:SetToAlpha(0)
frame.alpha:SetDuration(1)
frame.alpha:SetStartDelay(4)

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(DeathAlert.db.point.point, DeathAlert.db.point.x, DeathAlert.db.point.y)
        end

        self.text:SetTextColor(DeathAlert.db.color.r, DeathAlert.db.color.g, DeathAlert.db.color.b, DeathAlert.db.color.a)
        self.text:SetFont(LSM:Fetch("font", DeathAlert.db.font.fontFamily), DeathAlert.db.font.fontSize, DeathAlert.db.font.fontOutline)
        self.text:SetShadowColor(DeathAlert.db.font.fontShadowColor.r, DeathAlert.db.font.fontShadowColor.g, DeathAlert.db.font.fontShadowColor.b, DeathAlert.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(DeathAlert.db.font.fontShadowXOffset, DeathAlert.db.font.fontShadowYOffset)
        self.alpha:SetStartDelay(DeathAlert.db.messageDuration)
        self:SetSize(frame.text:GetStringWidth(), frame.text:GetStringHeight())
    end
end

local function OnEvent(self, event, deadGUID, ...)
    if ItruliaQoL.testMode then
        local name = UnitName("player")
        local _, class = UnitClass("player")
        
        local color = C_ClassColor.GetClassColor(class);
        local displayText = CreateColor(
            DeathAlert.db.color.r,
            DeathAlert.db.color.g, 
            DeathAlert.db.color.b, 
            DeathAlert.db.color.a
        ):WrapTextInColorCode(DeathAlert.db.displayText)
        local nameText = color:WrapTextInColorCode(name)

        self.text:SetText(nameText .. " " .. displayText)
        self.text:SetAlpha(1)

        return self:UpdateStyles()
    end

    if event == "UNIT_DIED" then
        if not canaccessvalue(deadGUID) or not canaccessvalue(UnitTokenFromGUID(deadGUID)) then
            return;
        end

        local unitId = UnitTokenFromGUID(deadGUID)

        if not unitId or not UnitIsDead(unitId) then
            -- well hunters in your party feign deathing is causing the event to fire without actually dying
            return 
        end

        if UnitInParty(unitId) or UnitInRaid(unitId) or unitId == "player" then
            local showText = true;
            local sound = DeathAlert.db.sound;
            local playSound = DeathAlert.db.playSound and sound;
            local tts = DeathAlert.db.TTS;
            local playTTS = DeathAlert.db.playTTS and tts;

            local name = UnitName(unitId)

            if canaccessvalue(name) then
                if DeathAlert.db.whitelist and DeathAlert.db.whitelist ~= "" then
                    local allowedNames = ItruliaQoL:SplitAndTrim(DeathAlert.db.whitelist)
                    local found = false

                    for _, v in ipairs(allowedNames) do
                        if v == name then
                            found = true
                            break
                        end
                    end

                    if not found then
                        return
                    end
                elseif DeathAlert.db.blacklist and DeathAlert.db.blacklist ~= "" then
                    local blockedNames = ItruliaQoL:SplitAndTrim(DeathAlert.db.blacklist)
                    local found = false

                    for _, v in ipairs(blockedNames) do
                        if v == name then
                            found = true
                            break
                        end
                    end

                    if found then
                        return
                    end
                end
            end

            -- Only do role based configuration inside a raid
            if ItruliaQoL:InRaid() then
                local role = UnitGroupRolesAssigned(unitId)

                if role == "NONE" then
                    role = "DAMAGER"
                end

                showText = DeathAlert.db.byRole.display[role].enabled
                sound = DeathAlert.db.byRole.sound[role].sound or sound
                playSound = playSound and DeathAlert.db.byRole.sound[role].enabled and sound
                tts = DeathAlert.db.byRole.sound[role].tts or tts
                playTTS = playTTS and DeathAlert.db.byRole.tts[role].enabled and tts
            end

            if showText then
                local name = UnitName(unitId)
                local _, class = UnitClass(unitId)
                local classColor = C_ClassColor.GetClassColor(class)

                local displayText = CreateColor(
                    DeathAlert.db.color.r,
                    DeathAlert.db.color.g, 
                    DeathAlert.db.color.b, 
                    DeathAlert.db.color.a
                ):WrapTextInColorCode(DeathAlert.db.displayText)
                local nameText = classColor:WrapTextInColorCode(name)

                self.text:SetText(nameText .. " " .. displayText)
                self.text:SetAlpha(1)
                self.text.anim:Stop()
                self.text.anim:Play()
            end

            if not self.lastSoundPlayedAt or (GetTime() - self.lastSoundPlayedAt) > 2 then
                if playSound then
                    self.lastSoundPlayedAt = GetTime()
                    PlaySoundFile(LSM:Fetch("sound", sound), "Master")
                elseif playTTS then
                    self.lastSoundPlayedAt = GetTime()
                    C_VoiceChat.SpeakText(0, tts, 1, DeathAlert.db.TTSVolume, true)
                end
            end
        else
            self.text:SetText("")
        end
    else
        self.text:SetText("")
    end

    self:UpdateStyles()
end

frame:RegisterEvent("UNIT_DIED")

local defaults = {
    enabled = true,
    whitelist = nil,
    blacklist = nil,
    displayText = "died",
    color = {r = 1, g = 1, b = 1, a = 1},
    messageDuration = 2,
    point = {point = "CENTER", x = 0, y = 200},

    playSound = false,
    sound = "Exit",
    playTTS = false,
    TTS = "",
    TTSVolume = 50,

    font = {
        fontFamily = "Expressway",
        fontSize = 28,
        fontOutline = "OUTLINE",
        fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
        fontShadowXOffset = 1,
        fontShadowYOffset = -1,
    },

    byRole = {
        display = {
            DAMAGER = {
                enabled = true
            },
            HEALER = {
                enabled = true
            },
            TANK = {
                enabled = true
            },
        },
        sound = {
            DAMAGER = {
                enabled = true,
                sound = nil
            },
            HEALER = {
                enabled = true,
                sound = nil
            },
            TANK = {
                enabled = true,
                sound = nil
            },
        },
        tts = {
            DAMAGER = {
                enabled = true,
                tts = nil
            },
            HEALER = {
                enabled = true,
                tts = nil
            },
            TANK = {
                enabled = true,
                tts = nil
            },
        }
    },
};

function DeathAlert:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.DeathAlert = profile.DeathAlert or defaults
    self.db = profile.DeathAlert

    -- Migration
    self.db.byRole = self.db.byRole or defaults.byRole
end

function DeathAlert:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.DeathAlert = profile.DeathAlert or defaults
    self.db = profile.DeathAlert

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function DeathAlert:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    frame:UpdateStyles()
end

function DeathAlert:OnEnable()
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

function DeathAlert:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

local function optionsForRole(role) 
    return {
        showAlert = {
            order = 1,
            type = "toggle",
            width = "full",
            name = "Show alert",
            get = function()
                return DeathAlert.db.byRole.display[role].enabled
            end,
            set = function(_, value)
                DeathAlert.db.byRole.display[role].enabled = value
            end
        },
        soundGroup = {
            order = 2,
            type = "group",
            name = "",
            inline = true,
            args = {
                playSound = {
                    order = 1,
                    type = "toggle",
                    name = "Play sound",
                    get = function() 
                        return DeathAlert.db.byRole.sound[role].enabled
                    end,
                    set = function(_, value)
                        DeathAlert.db.byRole.sound[role].enabled = value
                    end,
                    disabled = function()
                        return not DeathAlert.db.playSound
                    end
                },
                sound = {
                    order = 2,
                    type = "select",
                    dialogControl = "LSM30_Sound", 
                    name = "Sound",
                    values = LSM:HashTable("sound"),
                    get = function()
                        return DeathAlert.db.byRole.sound[role].sound
                    end,
                    set = function(_, value)
                        DeathAlert.db.byRole.sound[role].sound = value
                    end,
                    disabled = function()
                        return not DeathAlert.db.playSound or not DeathAlert.db.byRole.sound[role].enabled
                    end
                },
                clear = {
                    order = 3,
                    type = "execute",
                    name = "Clear",
                    width = 0.5,
                    func = function()
                        DeathAlert.db.byRole.sound[role].sound = nil
                    end,
                    disabled = function()
                        return not DeathAlert.db.playSound or not DeathAlert.db.byRole.sound[role].enabled
                    end
                },
            }
        },
        ttsGroup = {
            order = 3,
            type = "group",
            name = "",
            inline = true,
            args = {
                playTTS = {
                    order = 1,
                    type = "toggle",
                    name = "Play a TTS sound",
                    get = function() 
                        return DeathAlert.db.byRole.tts[role].enabled
                    end,
                    set = function(_, value)
                        DeathAlert.db.byRole.tts[role].enabled = value
                    end,
                    disabled = function()
                        return DeathAlert.db.playSound or not DeathAlert.db.playTTS
                    end
                },
                TTS = {
                    order = 2,
                    type = "input",
                    name = "TTS Message",
                    get = function()
                        return DeathAlert.db.byRole.tts[role].TTS
                    end,
                    set = function(_, value)
                        if value == "" then
                            value = nil
                        end

                        DeathAlert.db.byRole.tts[role].TTS = value
                    end,
                    disabled = function()
                        return DeathAlert.db.playSound or not DeathAlert.db.playTTS or not DeathAlert.db.byRole.sound[role].enabled
                    end
                },
            }
        }
    }
end

local options = {
    order = 2,
    type = "group",
    name = "Death Alert",
    args = {
        description = {
            type = "description",
            name = "Shows an alert when someone in your party or raid dies \n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function()
                return DeathAlert.db.enabled
            end,
            set = function(_, value)
                DeathAlert.db.enabled = value

                DeathAlert:RefreshConfig()
                if value then
                    OnEvent(frame)
                end
            end
        },
        displaySettings = {
            type = "group",
            name = "",
            order = 4,
            inline = true,
            args = {
                displayText = {
                    order = 1,
                    type = "input",
                    name = "Suffix",
                    get = function()
                        return DeathAlert.db.displayText
                    end,
                    set = function(_, value)
                        DeathAlert.db.displayText = value
                        frame:UpdateStyles()
                    end
                },
                color = {
                    order = 2,
                    type = "color",
                    name = "Color",
                    hasAlpha = true,
                    get = function()
                        local c = DeathAlert.db.color
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        DeathAlert.db.color = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        frame:UpdateStyles()
                    end
                },
                messageDuration = {
                    order = 3,
                    type = "range",
                    min = 1,
                    max = 10,
                    step = 1,
                    name = "Display duration",
                    get = function()
                        return DeathAlert.db.messageDuration
                    end,
                    set = function(_, value)
                        DeathAlert.db.messageDuration = value
                        frame:UpdateStyles()
                    end
                },
            }
        },
        fontSettings = {
            type = "group",
            name = "",
            order = 5,
            inline = true,
            args = {
                font = {
                    order = 1,
                    type = "select",
                    dialogControl = "LSM30_Font",
                    name = "Font",
                    values = LSM:HashTable("font"),
                    get = function()
                        return DeathAlert.db.font.fontFamily
                    end,
                    set = function(_, value)
                        DeathAlert.db.font.fontFamily = value
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
                        return DeathAlert.db.font.fontSize
                    end,
                    set = function(_, value)
                        DeathAlert.db.font.fontSize = value
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
                        return DeathAlert.db.font.fontOutline
                    end,
                    set = function(_, value)
                        DeathAlert.db.font.fontOutline = value ~= "NONE" and value or nil
                        frame:UpdateStyles()
                    end
                },
                fontShadowColor = {
                    order = 4,
                    type = "color",
                    name = "Shadow Color",
                    hasAlpha = true,
                    get = function()
                        local c = DeathAlert.db.font.fontShadowColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        DeathAlert.db.font.fontShadowColor = {
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
                        return DeathAlert.db.font.fontShadowXOffset
                    end,
                    set = function(_, value)
                        DeathAlert.db.font.fontShadowXOffset = value
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
                        return DeathAlert.db.font.fontShadowYOffset
                    end,
                    set = function(_, value)
                        DeathAlert.db.font.fontShadowYOffset = value
                        frame:UpdateStyles()
                    end
                },
            }
        },
        soundGroup = {
            type = "group",
            name = "",
            order = 6,
            inline = true,
            args = {
                playSound = {
                    order = 1,
                    type = "toggle",
                    name = "Play sound",
                    get = function() 
                        return DeathAlert.db.playSound
                    end,
                    set = function(_, value)
                        DeathAlert.db.playSound = value
                    end,
                },
                sound = {
                    order = 2,
                    type = "select",
                    dialogControl = "LSM30_Sound", 
                    name = "Sound",
                    values = LSM:HashTable("sound"),
                    get = function()
                        return DeathAlert.db.sound
                    end,
                    set = function(_, value)
                        DeathAlert.db.sound = value
                    end,
                    disabled = function()
                        return not DeathAlert.db.playSound
                    end,
                },
            }
        },
        ttsGroup = {
            type = "group",
            name = "",
            order = 7,
            inline = true,
            args = {
                playTTS = {
                    order = 1,
                    type = "toggle",
                    name = "Play a TTS sound",
                    get = function() 
                        return DeathAlert.db.playTTS
                    end,
                    set = function(_, value)
                        DeathAlert.db.playTTS = value
                    end,
                },
                TTS = {
                    order = 2,
                    type = "input",
                    name = "TTS Message",
                    get = function()
                        return DeathAlert.db.TTS
                    end,
                    set = function(_, value)
                        DeathAlert.db.TTS = value
                    end,
                    disabled = function()
                        return not DeathAlert.db.playTTS
                    end,
                },
                TTSVolume = {
                    order = 3,
                    type = "range",
                    min = 0,
                    max = 100,
                    step = 1,
                    name = "TTS Volume",
                    get = function()
                        return DeathAlert.db.TTSVolume
                    end,
                    set = function(_, value)
                        DeathAlert.db.TTSVolume = value
                    end,
                    disabled = function()
                        return not DeathAlert.db.playTTS
                    end,
                },
            },
            disabled = function()
                return DeathAlert.db.playSound
            end,
        },
        boosterSettings = {
            type = "group",
            name = "",
            order = 8,
            inline = true,
            args = {
                whitelist = {
                    order = 1,
                    type = "input",
                    multiline = true,
                    name = "Whitelist names",
                    desc = "Comma seperated list of names",
                    get = function()
                        return DeathAlert.db.whitelist
                    end,
                    set = function(_, value)
                        DeathAlert.db.whitelist = value
                    end
                },
                spacer = {
                    type = "description",
                    name = " ",
                    width = 0.1,
                    order = 2,
                },
                blacklist = {
                    order = 3,
                    type = "input",
                    multiline = true,
                    name = "Blacklist names",
                    desc = "Comma seperated list of names",
                    get = function()
                        return DeathAlert.db.blacklist
                    end,
                    set = function(_, value)
                        DeathAlert.db.blacklist = value
                    end,
                    disabled = function()
                        return DeathAlert.db.whitelist and DeathAlert.db.whitelist ~= ""
                    end
                },
            }
        },
        byRole = {
            type = "group",
            name = "Settings based on dead player's role",
            order = 9,
            inline = true,
            args = {
                description = {
                    type = "description",
                    name = "These settings only work while in a raid as you might not care about a dps standing in fire ;) \n" 
                    .. "Empty settings will fallback to the settings above \n\n",
                    width = "full",
                    order = 1,
                },
                dpsConfig = {
                    type = "group",
                    name = "DPS",
                    order = 2,
                    inline = true,
                    args = optionsForRole("DAMAGER")
                },
                healerConfig = {
                    type = "group",
                    name = "Healer",
                    order = 3,
                    inline = true,
                    args = optionsForRole("HEALER")
                },
                tankConfig = {
                    type = "group",
                    name = "Tank",
                    order = 4,
                    inline = true,
                    args = optionsForRole("TANK")
                }
            },
        },
    }
}

function DeathAlert:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = options;
end