local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "FocusInterruptIndicator"
local FocusInterruptIndicator = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function FocusInterruptIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Focus Interrupt",
        rows = {
            {
                text = "Shows an alert when your focus casts an interruptible spell and your interrupt is ready.",
            },
            {
                type = "input",
                label = "Display text",
                get = function()
                    return FocusInterruptIndicator.db.displayText
                end,
                set = function(value)
                    FocusInterruptIndicator.db.displayText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = FocusInterruptIndicator.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    FocusInterruptIndicator.db.color = {
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
                rows = ItruliaQoL:EUIFontRows(FocusInterruptIndicator.db.font, apply),
            },
            {
                header = "Sound",
            },
            {
                text = "This sound plays even when your interrupt is unavailable or the cast is not interruptible (API limitation).",
            },
            {
                type = "toggle",
                label = "Play sound",
                refresh = true,
                get = function()
                    return FocusInterruptIndicator.db.playSound
                end,
                set = function(value)
                    FocusInterruptIndicator.db.playSound = value
                end,
            },
            {
                type = "select",
                label = "Sound",
                values = LSM:HashTable("sound"),
                disabled = function()
                    return not FocusInterruptIndicator.db.playSound
                end,
                get = function()
                    return FocusInterruptIndicator.db.sound
                end,
                set = function(value)
                    FocusInterruptIndicator.db.sound = value
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
                    return FocusInterruptIndicator.db.playSound
                end,
                get = function()
                    return FocusInterruptIndicator.db.playTTS
                end,
                set = function(value)
                    FocusInterruptIndicator.db.playTTS = value
                end,
            },
            {
                type = "input",
                label = "TTS message",
                disabled = function()
                    return FocusInterruptIndicator.db.playSound or not FocusInterruptIndicator.db.playTTS
                end,
                get = function()
                    return FocusInterruptIndicator.db.TTS
                end,
                set = function(value)
                    FocusInterruptIndicator.db.TTS = value
                end,
            },
            {
                type = "slider",
                label = "TTS volume",
                min = 0,
                max = 100,
                step = 1,
                disabled = function()
                    return FocusInterruptIndicator.db.playSound or not FocusInterruptIndicator.db.playTTS
                end,
                get = function()
                    return FocusInterruptIndicator.db.TTSVolume
                end,
                set = function(value)
                    FocusInterruptIndicator.db.TTSVolume = value
                end,
            },
        },
    }
end
