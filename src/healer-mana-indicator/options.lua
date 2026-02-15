local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "HealerManaIndicator"
local HealerManaIndicator = ItruliaQoL:GetModule(moduleName)

function HealerManaIndicator:GetOptions(onChange)
    return {
        order = 2,
        type = "group",
        name = "Healer Mana Indicator",
        args = {
            description = {
                type = "description",
                name = "Shows the mana of your healers \n\n",
                width = "full",
                order = 1,
            },
            enable = {
                order = 2,
                width = 0.4,
                type = "toggle",
                name = "Enable",
                get = function()
                    return HealerManaIndicator.db.enabled
                end,
                set = function(_, value)
                    HealerManaIndicator.db.enabled = value
                    HealerManaIndicator:RefreshConfig()
                end
            },
            enableInDungeons = {
                order = 3,
                width = 0.8,
                type = "toggle",
                name = "Enable in dungeons",
                get = function()
                    return HealerManaIndicator.db.enableInDungeons
                end,
                set = function(_, value)
                    HealerManaIndicator.db.enableInDungeons = value
                    onChange()
                end,
                disabled = function()
                    return not HealerManaIndicator.db.enabled
                end
            },
            enableInRaids = {
                order = 4,
                width = 0.75,
                type = "toggle",
                name = "Enable in raids",
                get = function()
                    return HealerManaIndicator.db.enableInRaids
                end,
                set = function(_, value)
                    HealerManaIndicator.db.enableInRaids = value
                    onChange()
                end,
                disabled = function()
                    return not HealerManaIndicator.db.enabled
                end
            },
            displaySettings = {
                type = "group",
                name = "",
                order = 5,
                inline = true,
                args = {
                    color = {
                        order = 1,
                        type = "color",
                        name = "Color",
                        hasAlpha = true,
                        get = function()
                            local c = HealerManaIndicator.db.color
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            HealerManaIndicator.db.color = {
                                r = r,
                                g = g,
                                b = b,
                                a = a
                            }
                            onChange()
                        end
                    },
                    growUpwards = {
                        order = 2,
                        type = "toggle",
                        width = "full",
                        name = "Grow upwards",
                        get = function()
                            return HealerManaIndicator.db.growUpwards
                        end,
                        set = function(_, value)
                            HealerManaIndicator.db.growUpwards = value
                            onChange()
                        end
                    },
                }
            },
            fontSettings = {
                type = "group",
                name = "",
                order = 6,
                inline = true,
                args = ItruliaQoL:createFontOptions(HealerManaIndicator.db.font, function() 
                    onChange()
                end)
            },
        }
    }
end