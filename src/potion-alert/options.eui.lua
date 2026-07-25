local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "PotionAlert"
local PotionAlert = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function PotionAlert:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Potion Alert",
        rows = {
            {
                text = "Displays a text and plays a sound when your combat potion is off CD",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return PotionAlert.db.enabled
                end,
                set = function(value)
                    PotionAlert.db.enabled = value
                    PotionAlert:RefreshConfig()
                end,
            },
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
            {
                type = "input",
                label = "Display text",
                get = function()
                    return PotionAlert.db.displayText
                end,
                set = function(value)
                    PotionAlert.db.displayText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Color",
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
            },
            {
                header = "Font",
                rows = ItruliaQoL:EUIFontRows(PotionAlert.db.font, apply),
            },
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
            {
                type = "select",
                label = "Sound",
                values = LSM:HashTable("sound"),
                disabled = function()
                    return not PotionAlert.db.playSound
                end,
                get = function()
                    return PotionAlert.db.sound
                end,
                set = function(value)
                    PotionAlert.db.sound = value
                end,
            },
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
