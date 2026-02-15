local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "RaidConsumesAlert"
local RaidConsumesAlert = ItruliaQoL:GetModule(moduleName)

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
                    width = 0.75,
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

function RaidConsumesAlert:GetOptions(onChange)
    return {
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
                end
            },
            color = {
                order = 3,
                type = "color",
                name = "Color",
                width = 0.4,
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
                    onChange()
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
                            onChange()
                        end
                    },
                    fontSize = {
                        order = 2,
                        type = "range",
                        width = 0.75,
                        name = "Size",
                        min = 1,
                        max = 68,
                        step = 1,
                        get = function()
                            return RaidConsumesAlert.db.font.fontSize
                        end,
                        set = function(_, value)
                            RaidConsumesAlert.db.font.fontSize = value
                            onChange()
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
                            onChange()
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
                            onChange()
                        end
                    },
                    fontShadowXOffset = {
                        order = 6,
                        type = "range",
                        width = 0.75,
                        name = "Shadow X Offset",
                        min = -5,
                        max = 5,
                        step = 1,
                        get = function()
                            return RaidConsumesAlert.db.font.fontShadowXOffset
                        end,
                        set = function(_, value)
                            RaidConsumesAlert.db.font.fontShadowXOffset = value
                            onChange()
                        end
                    },
                    fontShadowYOffset = {
                        order = 57,
                        type = "range",
                        width = 0.75,
                        name = "Shadow Y Offset",
                        min = -5,
                        max = 5,
                        step = 1,
                        get = function()
                            return RaidConsumesAlert.db.font.fontShadowYOffset
                        end,
                        set = function(_, value)
                            RaidConsumesAlert.db.font.fontShadowYOffset = value
                            onChange()
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
                    repairBot = {
                        type = "group",
                        name = "Repair Bot",
                        order = 4,
                        inline = true,
                        args = createConsumeTypeOptions("repairBot"),
                    },
                    soulwell = {
                        type = "group",
                        name = "Soulwell",
                        order = 5,
                        inline = true,
                        args = createConsumeTypeOptions("soulwell"),
                    },
                    summonStone = {
                        type = "group",
                        name = "Summon stone",
                        order = 6,
                        inline = true,
                        args = createConsumeTypeOptions("summonStone"),
                    },
                },
            },
        }
    }
end