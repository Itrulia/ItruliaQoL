local addonName, ItruliaQoL = ...

local moduleName = "PotionAlert"
local PotionAlert = ItruliaQoL:GetModule(moduleName)

PotionAlert.EUIPages = { "Display", "Sound Alert", "Filters" }

function PotionAlert:GetEUIOptions(pageName)
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    if pageName == "Sound Alert" then
        return {
            name = "Potion Alert",
            rows = {
                {
                    header = "Sound",
                },
                {
                    type = "toggle",
                    label = "Play sound",
                    refresh = true,
                    get = function()
                        return PotionAlert.db.playSound
                    end,
                    set = function(value)
                        PotionAlert.db.playSound = value
                    end,
                },
                ItruliaQoL:EUISoundRow({
                    disabled = function()
                        return not PotionAlert.db.playSound
                    end,
                    get = function()
                        return PotionAlert.db.sound
                    end,
                    set = function(value)
                        PotionAlert.db.sound = value
                    end,
                }),
                {
                    header = "Text-to-Speech",
                },
                {
                    type = "toggle",
                    label = "Play TTS",
                    refresh = true,
                    disabled = function()
                        return PotionAlert.db.playSound
                    end,
                    get = function()
                        return PotionAlert.db.playTTS
                    end,
                    set = function(value)
                        PotionAlert.db.playTTS = value
                    end,
                },
                {
                    type = "input",
                    label = "TTS Message",
                    disabled = function()
                        return PotionAlert.db.playSound or not PotionAlert.db.playTTS
                    end,
                    get = function()
                        return PotionAlert.db.TTS
                    end,
                    set = function(value)
                        PotionAlert.db.TTS = value
                    end,
                },
                {
                    type = "slider",
                    label = "TTS Volume",
                    min = 0,
                    max = 100,
                    step = 1,
                    disabled = function()
                        return PotionAlert.db.playSound or not PotionAlert.db.playTTS
                    end,
                    get = function()
                        return PotionAlert.db.TTSVolume
                    end,
                    set = function(value)
                        PotionAlert.db.TTSVolume = value
                    end,
                },
            },
        }
    end

    if pageName == "Filters" then
        return {
            name = "Potion Alert",
            rows = {
                {
                    header = "Instances",
                },
                {
                    pair = {
                        {
                            type = "toggle",
                            label = "Enable in m0/m+",
                            get = function()
                                return PotionAlert.db.enabledInDungeons
                            end,
                            set = function(value)
                                PotionAlert.db.enabledInDungeons = value
                                apply()
                            end,
                        },
                        {
                            type = "toggle",
                            label = "Enable in raids",
                            get = function()
                                return PotionAlert.db.enabledInRaids
                            end,
                            set = function(value)
                                PotionAlert.db.enabledInRaids = value
                                apply()
                            end,
                        },
                    },
                },
            },
        }
    end

    local displayRow = {
        type = "color",
        label = "Display",
        hasAlpha = true,
        get = function()
            local c = PotionAlert.db.color
            return c.r, c.g, c.b, c.a
        end,
        set = function(r, g, b, a)
            PotionAlert.db.color = {
                r = r,
                g = g,
                b = b,
                a = a,
            }
            apply()
        end,
        cog = {
            title = "Alert Text",
            rows = {
                {
                    type = "input",
                    label = "Text",
                    width = 120,
                    get = function()
                        return PotionAlert.db.displayText or ""
                    end,
                    set = function(value)
                        PotionAlert.db.displayText = value
                        apply()
                    end,
                },
            },
        },
    }

    return {
        name = "Potion Alert",
        rows = ItruliaQoL:EUIFontRows(PotionAlert.db.font, apply, nil, { displayRow }),
    }
end
