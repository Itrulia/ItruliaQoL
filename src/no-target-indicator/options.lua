local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "NoTargetIndicator"
local NoTargetIndicator = ItruliaQoL:GetModule(moduleName)

function NoTargetIndicator:GetOptions(onChange)
    return {
        order = 2,
        type = "group",
        name = "No Target Indicator",
        args = {
            description = {
                type = "description",
                name = "Shows an indicator text when player doesn't have a target when in combat \n\n",
                width = "full",
                order = 1,
            },
            enable = {
                order = 2,
                type = "toggle",
                width = "full",
                name = "Enable",
                get = function()
                    return NoTargetIndicator.db.enabled
                end,
                set = function(_, value)
                    NoTargetIndicator.db.enabled = value
                    NoTargetIndicator:RefreshConfig()
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
                        name = "Display text",
                        get = function()
                            return NoTargetIndicator.db.displayText
                        end,
                        set = function(_, value)
                            NoTargetIndicator.db.displayText = value
                            onChange()
                        end
                    },
                    color = {
                        order = 2,
                        type = "color",
                        name = "Color",
                        hasAlpha = true,
                        get = function()
                            local c = NoTargetIndicator.db.color
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            NoTargetIndicator.db.color = {
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
                args = ItruliaQoL:createFontOptions(NoTargetIndicator.db.font, function() 
                    onChange()
                end)
            },
        }
    }
end