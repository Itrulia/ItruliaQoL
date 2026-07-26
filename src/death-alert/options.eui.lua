local addonName, ItruliaQoL = ...

local moduleName = "DeathAlert"
local DeathAlert = ItruliaQoL:GetModule(moduleName)

-- Per-role settings block, mirroring options.ace.lua's optionsForRole(role).
local function roleRows(role)
    return {
        {
            type = "toggle",
            label = "Show alert",
            get = function()
                return DeathAlert.db.byRole.display[role].enabled
            end,
            set = function(value)
                DeathAlert.db.byRole.display[role].enabled = value
            end,
        },
        {
            type = "toggle",
            label = "Play sound",
            refresh = true,
            disabled = function()
                return not DeathAlert.db.playSound
            end,
            get = function()
                return DeathAlert.db.byRole.sound[role].enabled
            end,
            set = function(value)
                DeathAlert.db.byRole.sound[role].enabled = value
            end,
        },
        ItruliaQoL:EUISoundRow({
            disabled = function()
                return not DeathAlert.db.playSound or not DeathAlert.db.byRole.sound[role].enabled
            end,
            get = function()
                return DeathAlert.db.byRole.sound[role].sound
            end,
            set = function(value)
                DeathAlert.db.byRole.sound[role].sound = value
            end,
        }),
        {
            type = "execute",
            label = "Clear",
            refresh = true,
            disabled = function()
                return not DeathAlert.db.playSound or not DeathAlert.db.byRole.sound[role].enabled
            end,
            func = function()
                DeathAlert.db.byRole.sound[role].sound = nil
            end,
        },
        {
            type = "toggle",
            label = "Play TTS",
            disabled = function()
                return DeathAlert.db.playSound or not DeathAlert.db.playTTS
            end,
            get = function()
                return DeathAlert.db.byRole.tts[role].enabled
            end,
            set = function(value)
                DeathAlert.db.byRole.tts[role].enabled = value
            end,
        },
        {
            type = "input",
            label = "TTS Message",
            disabled = function()
                return DeathAlert.db.playSound or not DeathAlert.db.playTTS or not DeathAlert.db.byRole.tts[role].enabled
            end,
            get = function()
                return DeathAlert.db.byRole.tts[role].TTS
            end,
            set = function(value)
                if value == "" then
                    value = nil
                end
                DeathAlert.db.byRole.tts[role].TTS = value
            end,
        },
    }
end


DeathAlert.EUIPages = { "Display", "Sound Alert", "Filters" }

function DeathAlert:GetEUIOptions(pageName)
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    if pageName == "Sound Alert" then
        return {
            name = "Death Alert",
            rows = {
                {
                    header = "Sound",
                },
                {
                    type = "toggle",
                    label = "Play sound",
                    refresh = true,
                    get = function()
                        return DeathAlert.db.playSound
                    end,
                    set = function(value)
                        DeathAlert.db.playSound = value
                    end,
                },
                ItruliaQoL:EUISoundRow({
                    disabled = function()
                        return not DeathAlert.db.playSound
                    end,
                    get = function()
                        return DeathAlert.db.sound
                    end,
                    set = function(value)
                        DeathAlert.db.sound = value
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
                        return DeathAlert.db.playSound
                    end,
                    get = function()
                        return DeathAlert.db.playTTS
                    end,
                    set = function(value)
                        DeathAlert.db.playTTS = value
                    end,
                },
                {
                    type = "input",
                    label = "TTS Message",
                    disabled = function()
                        return DeathAlert.db.playSound or not DeathAlert.db.playTTS
                    end,
                    get = function()
                        return DeathAlert.db.TTS
                    end,
                    set = function(value)
                        DeathAlert.db.TTS = value
                    end,
                },
                {
                    type = "slider",
                    label = "TTS Volume",
                    min = 0,
                    max = 100,
                    step = 1,
                    disabled = function()
                        return DeathAlert.db.playSound or not DeathAlert.db.playTTS
                    end,
                    get = function()
                        return DeathAlert.db.TTSVolume
                    end,
                    set = function(value)
                        DeathAlert.db.TTSVolume = value
                    end,
                },
            },
        }
    end

    if pageName == "Filters" then
        return {
            name = "Death Alert",
            rows = {
                {
                    header = "Names",
                },
                {
                    type = "input",
                    label = "Whitelist names",
                    tooltip = "Comma seperated list of names",
                    get = function()
                        return DeathAlert.db.whitelist
                    end,
                    set = function(value)
                        DeathAlert.db.whitelist = value
                    end,
                },
                {
                    type = "input",
                    label = "Blacklist names",
                    tooltip = "Comma seperated list of names",
                    disabled = function()
                        return DeathAlert.db.whitelist ~= nil and DeathAlert.db.whitelist ~= ""
                    end,
                    get = function()
                        return DeathAlert.db.blacklist
                    end,
                    set = function(value)
                        DeathAlert.db.blacklist = value
                    end,
                },
                {
                    header = "Settings based on dead player's role",
                },
                {
                    text = "These settings only work while in a raid as you might not care about a dps standing in fire ;)",
                },
                {
                    text = "Empty settings will fallback to the settings above",
                },
                {
                    header = "DPS",
                    rows = roleRows("DAMAGER"),
                },
                {
                    header = "Healer",
                    rows = roleRows("HEALER"),
                },
                {
                    header = "Tank",
                    rows = roleRows("TANK"),
                },
            },
        }
    end

    return {
        name = "Death Alert",
        rows = {
            {
                type = "input",
                label = "Suffix",
                get = function()
                    return DeathAlert.db.displayText
                end,
                set = function(value)
                    DeathAlert.db.displayText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = DeathAlert.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    DeathAlert.db.color = {
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
                label = "Display duration",
                min = 1,
                max = 10,
                step = 1,
                get = function()
                    return DeathAlert.db.messageDuration
                end,
                set = function(value)
                    DeathAlert.db.messageDuration = value
                    apply()
                end,
            },
            {
                header = "Font",
                rows = ItruliaQoL:EUIFontRows(DeathAlert.db.font, apply),
            },
        },
    }
end
