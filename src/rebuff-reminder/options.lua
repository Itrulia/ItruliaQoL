local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "RebuffReminder"
local RebuffReminder = ItruliaQoL:GetModule(moduleName)

function RebuffReminder:GetOptions(onChange)
    return {
        order = 2,
        type = "group",
        name = "Rebuff Reminder",
        args = {
            description = {
                type = "description",
                name =  "Displays a text and/or plays a sound/tts when it's rebuff time (during combat/ready check) \n\n",
                width = "full",
                order = 1,
            },
            enableSettings = {
                type = "group",
                name = "",
                order = 2,
                inline = true,
                args = {
                    enable = {
                        order = 1,
                        type = "toggle",
                        width = 0.4,
                        name = "Enable",
                        get = function()
                            return RebuffReminder.db.enabled
                        end,
                        set = function(_, value)
                            RebuffReminder.db.enabled = value
                            RebuffReminder:RefreshConfig()
                        end
                    },
                    alertWhenIdle = {
                        order = 2,
                        type = "toggle",
                        width = 1,
                        name = "Alert out of combat",
                        get = function()
                            return RebuffReminder.db.alertWhenIdle
                        end,
                        set = function(_, value)
                            RebuffReminder.db.alertWhenIdle = value
                            onChange()
                        end
                    },
                }
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
                        name = "Display text",
                        get = function()
                            return RebuffReminder.db.displayText
                        end,
                        set = function(_, value)
                            RebuffReminder.db.displayText = value
                            onChange()
                        end,
                    },
                    color = {
                        order = 2,
                        type = "color",
                        name = "Color",
                        width = 0.4,
                        hasAlpha = true,
                        get = function()
                            local c = RebuffReminder.db.color
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            RebuffReminder.db.color = {
                                r = r,
                                g = g,
                                b = b,
                                a = a
                            }
                            onChange()
                        end
                    },
                }
            },
            fontSettings = {
                type = "group",
                name = "",
                order = 5,
                inline = true,
                args = ItruliaQoL:createFontOptions(RebuffReminder.db.font, function() 
                    onChange()
                end)
            },
            spacer = {
                type = "description",
                name = " ",
                width = "full",
                order = 6,
            },
            soundGroup = {
                type = "group",
                name = "",
                order = 7,
                inline = true,
                args = {
                    playSound = {
                        order = 1,
                        type = "toggle",
                        name = "Play sound",
                        get = function() 
                            return RebuffReminder.db.playSound
                        end,
                        set = function(_, value)
                            RebuffReminder.db.playSound = value
                        end,
                    },
                    sound = {
                        order = 2,
                        type = "select",
                        dialogControl = "LSM30_Sound", 
                        name = "Sound",
                        values = LSM:HashTable("sound"),
                        get = function()
                            return RebuffReminder.db.sound
                        end,
                        set = function(_, value)
                            RebuffReminder.db.sound = value
                        end,
                        disabled = function()
                            return not RebuffReminder.db.playSound
                        end,
                    },
                },
            },
            ttsGroup = {
                type = "group",
                name = "",
                order = 8,
                inline = true,
                args = {
                    playTTS = {
                        order = 1,
                        type = "toggle",
                        name = "Play TTS",
                        get = function() 
                            return RebuffReminder.db.playTTS
                        end,
                        set = function(_, value)
                            RebuffReminder.db.playTTS = value
                        end,
                    },
                    tts = {
                        order = 2,
                        type = "input",
                        name = "TTS Message",
                        get = function()
                            return RebuffReminder.db.tts
                        end,
                        set = function(_, value)
                            RebuffReminder.db.tts = value
                        end,
                        disabled = function()
                            return not RebuffReminder.db.playTTS
                        end,
                    },
                    ttsVolume = {
                        order = 3,
                        type = "range",
                        width = 0.75,
                        min = 0,
                        max = 100,
                        step = 1,
                        name = "TTS Volume",
                        get = function()
                            return RebuffReminder.db.ttsVolume
                        end,
                        set = function(_, value)
                            RebuffReminder.db.ttsVolume = value
                        end,
                        disabled = function()
                            return not RebuffReminder.db.playTTS
                        end,
                    },
                },
                disabled = function()
                    return RebuffReminder.db.playSound
                end,
            },
        }
    }
end