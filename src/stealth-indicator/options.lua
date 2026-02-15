local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "StealthIndicator"
local StealthIndicator = ItruliaQoL:GetModule(moduleName)

function StealthIndicator:GetOptions(onChange)
    return {
        order = 2,
        type = "group",
        name = "Stealth Indicator",
        args = {
            description = {
                type = "description",
                name = "Shows an indicator text when stealthed (not invisible) \n\n",
                width = "full",
                order = 1,
            },
            enable = {
                order = 2,
                type = "toggle",
                width = "full",
                name = "Enable",
                get = function()
                    return StealthIndicator.db.enabled
                end,
                set = function(_, value)
                    StealthIndicator.db.enabled = value
                    StealthIndicator:RefreshConfig()
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
                            return StealthIndicator.db.displayText
                        end,
                        set = function(_, value)
                            StealthIndicator.db.displayText = value
                            onChange()
                        end
                    },
                    color = {
                        order = 2,
                        type = "color",
                        name = "Color",
                        hasAlpha = true,
                        get = function()
                            local c = StealthIndicator.db.color
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            StealthIndicator.db.color = {
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
                args = ItruliaQoL:createFontOptions(StealthIndicator.db.font, function() 
                    onChange()
                end)
            },
        }
    }
end