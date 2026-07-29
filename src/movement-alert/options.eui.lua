local addonName, ItruliaQoL = ...

local moduleName = "MovementAlert"
local MovementAlert = ItruliaQoL:GetModule(moduleName)

MovementAlert.EUIPages = { MovementAlert.pageDisplay, MovementAlert.pageTimeSpiral }

function MovementAlert:GetEUIOptions(pageName)
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    if pageName == MovementAlert.pageTimeSpiral then
        local function spiralOff()
            return not MovementAlert.db.showTimeSpiral
        end

        return {
            name = "Movement Alert",
            rows = {
                {
                    pair = {
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
                            type = "color",
                            label = "Display",
                            hasAlpha = true,
                            disabled = spiralOff,
                            disabledTooltip = "Time spiral",
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
                            cog = {
                                title = "Alert Text",
                                rows = {
                                    {
                                        type = "input",
                                        label = "Text",
                                        width = 120,
                                        disabled = spiralOff,
                                        disabledTooltip = "Time spiral",
                                        get = function()
                                            return MovementAlert.db.timeSpiralText or ""
                                        end,
                                        set = function(value)
                                            MovementAlert.db.timeSpiralText = value
                                            apply()
                                        end,
                                    },
                                },
                            },
                        },
                    },
                },
                {
                    header = "Sound",
                },
                {
                    type = "toggle",
                    label = "Play sound when time spiral becomes active",
                    refresh = true,
                    disabled = spiralOff,
                    disabledTooltip = "Time spiral",
                    get = function()
                        return MovementAlert.db.timeSpiralPlaySound
                    end,
                    set = function(value)
                        MovementAlert.db.timeSpiralPlaySound = value
                        apply()
                    end,
                },
                ItruliaQoL:EUISoundRow({
                    disabled = function()
                        return spiralOff() or not MovementAlert.db.timeSpiralPlaySound
                    end,
                    get = function()
                        return MovementAlert.db.timeSpiralSound
                    end,
                    set = function(value)
                        MovementAlert.db.timeSpiralSound = value
                        apply()
                    end,
                }),
                {
                    header = "Text-to-Speech",
                },
                {
                    type = "toggle",
                    label = "Play TTS when time spiral becomes active",
                    refresh = true,
                    disabled = function()
                        return spiralOff() or MovementAlert.db.timeSpiralPlaySound
                    end,
                    disabledTooltip = "Time spiral",
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
                        return spiralOff() or MovementAlert.db.timeSpiralPlaySound or not MovementAlert.db.timeSpiralPlayTTS
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
                        return spiralOff() or MovementAlert.db.timeSpiralPlaySound or not MovementAlert.db.timeSpiralPlayTTS
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

    -- pageDisplay, and the fallback for any caller that passes no page name
    local displayRow = {
        type = "color",
        label = "Display",
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
        cog = {
            title = "Timer Text",
            rows = {
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
            },
        },
    }

    return {
        name = "Movement Alert",
        rows = ItruliaQoL:EUIFontRows(MovementAlert.db.font, apply, nil, { displayRow }),
    }
end
