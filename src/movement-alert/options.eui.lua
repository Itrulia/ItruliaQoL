local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "MovementAlert"
local MovementAlert = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function MovementAlert:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Movement Alert",
        rows = {
            {
                text = "Displays a text when your most important movement ability is on cooldown or time spiral is active",
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = MovementAlert.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    MovementAlert.db.color = {
                        r = r,
                        g = g,
                        b = b,
                        a = a,
                    }
                    apply()
                end,
            },
            {
                type = "slider",
                label = "Decimal precision",
                min = 0,
                max = 1,
                step = 1,
                get = function()
                    return MovementAlert.db.precision
                end,
                set = function(value)
                    MovementAlert.db.precision = value
                    apply()
                end,
            },
            {
                header = "Font",
                rows = ItruliaQoL:EUIFontRows(MovementAlert.db.font, apply),
            },
            {
                header = "Time spiral",
            },
            {
                type = "toggle",
                label = "Enable",
                refresh = true,
                get = function()
                    return MovementAlert.db.showTimeSpiral
                end,
                set = function(value)
                    MovementAlert.db.showTimeSpiral = value
                    apply()
                end,
            },
            {
                type = "input",
                label = "Time spiral text",
                disabled = function()
                    return not MovementAlert.db.showTimeSpiral
                end,
                get = function()
                    return MovementAlert.db.timeSpiralText
                end,
                set = function(value)
                    MovementAlert.db.timeSpiralText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Time spiral color",
                hasAlpha = true,
                disabled = function()
                    return not MovementAlert.db.showTimeSpiral
                end,
                get = function()
                    local c = MovementAlert.db.timeSpiralColor
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    MovementAlert.db.timeSpiralColor = {
                        r = r,
                        g = g,
                        b = b,
                        a = a,
                    }
                    apply()
                end,
            },
            {
                type = "toggle",
                label = "Play sound when time spiral becomes active",
                refresh = true,
                disabled = function()
                    return not MovementAlert.db.showTimeSpiral
                end,
                get = function()
                    return MovementAlert.db.timeSpiralPlaySound
                end,
                set = function(value)
                    MovementAlert.db.timeSpiralPlaySound = value
                    apply()
                end,
            },
            {
                type = "select",
                label = "Sound",
                values = LSM:HashTable("sound"),
                disabled = function()
                    return not MovementAlert.db.showTimeSpiral or not MovementAlert.db.timeSpiralPlaySound
                end,
                get = function()
                    return MovementAlert.db.timeSpiralSound
                end,
                set = function(value)
                    MovementAlert.db.timeSpiralSound = value
                    apply()
                end,
            },
            {
                type = "toggle",
                label = "Play TTS when time spiral becomes active",
                refresh = true,
                disabled = function()
                    return not MovementAlert.db.showTimeSpiral or MovementAlert.db.timeSpiralPlaySound
                end,
                get = function()
                    return MovementAlert.db.timeSpiralPlayTTS
                end,
                set = function(value)
                    MovementAlert.db.timeSpiralPlayTTS = value
                    apply()
                end,
            },
            {
                type = "input",
                label = "TTS Message",
                disabled = function()
                    return not MovementAlert.db.showTimeSpiral or MovementAlert.db.timeSpiralPlaySound or not MovementAlert.db.timeSpiralPlayTTS
                end,
                get = function()
                    return MovementAlert.db.timeSpiralTTS
                end,
                set = function(value)
                    MovementAlert.db.timeSpiralTTS = value
                    apply()
                end,
            },
            {
                type = "slider",
                label = "TTS Volume",
                min = 0,
                max = 100,
                step = 1,
                disabled = function()
                    return not MovementAlert.db.showTimeSpiral or MovementAlert.db.timeSpiralPlaySound or not MovementAlert.db.timeSpiralPlayTTS
                end,
                get = function()
                    return MovementAlert.db.timeSpiralTTSVolume
                end,
                set = function(value)
                    MovementAlert.db.timeSpiralTTSVolume = value
                end,
            },
        },
    }
end
