local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "RebuffReminder"
local RebuffReminder = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function RebuffReminder:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Rebuff Reminder",
        rows = {
            {
                text = "Displays a text and/or plays a sound/tts when it's rebuff time (during combat/ready check)",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return RebuffReminder.db.enabled
                end,
                set = function(value)
                    RebuffReminder.db.enabled = value
                    RebuffReminder:RefreshConfig()
                end,
            },
            {
                type = "toggle",
                label = "Alert out of combat",
                get = function()
                    return RebuffReminder.db.alertWhenIdle
                end,
                set = function(value)
                    RebuffReminder.db.alertWhenIdle = value
                    apply()
                end,
            },
            {
                type = "input",
                label = "Display text",
                get = function()
                    return RebuffReminder.db.displayText
                end,
                set = function(value)
                    RebuffReminder.db.displayText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = RebuffReminder.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    RebuffReminder.db.color = {
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
                rows = ItruliaQoL:EUIFontRows(RebuffReminder.db.font, apply),
            },
            {
                header = "Sound",
            },
            {
                type = "toggle",
                label = "Play sound",
                refresh = true,
                get = function()
                    return RebuffReminder.db.playSound
                end,
                set = function(value)
                    RebuffReminder.db.playSound = value
                end,
            },
            {
                type = "select",
                label = "Sound",
                values = LSM:HashTable("sound"),
                disabled = function()
                    return not RebuffReminder.db.playSound
                end,
                get = function()
                    return RebuffReminder.db.sound
                end,
                set = function(value)
                    RebuffReminder.db.sound = value
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
                    return RebuffReminder.db.playSound
                end,
                get = function()
                    return RebuffReminder.db.playTTS
                end,
                set = function(value)
                    RebuffReminder.db.playTTS = value
                end,
            },
            {
                type = "input",
                label = "TTS Message",
                disabled = function()
                    return RebuffReminder.db.playSound or not RebuffReminder.db.playTTS
                end,
                get = function()
                    return RebuffReminder.db.tts
                end,
                set = function(value)
                    RebuffReminder.db.tts = value
                end,
            },
            {
                type = "slider",
                label = "TTS Volume",
                min = 0,
                max = 100,
                step = 1,
                disabled = function()
                    return RebuffReminder.db.playSound or not RebuffReminder.db.playTTS
                end,
                get = function()
                    return RebuffReminder.db.ttsVolume
                end,
                set = function(value)
                    RebuffReminder.db.ttsVolume = value
                end,
            },
        },
    }
end
