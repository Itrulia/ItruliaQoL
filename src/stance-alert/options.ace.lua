local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "StanceAlert"
local StanceAlert = ItruliaQoL:GetModule(moduleName)

function StanceAlert:GetOptions(onChange)
    return {
        order = 2,
        type = "group",
        name = "Stance Alert",
        args = {
            preview = ItruliaQoL:CreatePreviewOption(StanceAlert),
            description = {
                type = "description",
                name = "Shows an indicator text while you are in the wrong druid form (combat only) or warrior stance\n\n",
                width = "full",
                order = 1,
            },
            enable = {
                order = 2,
                type = "toggle",
                width = "full",
                name = "Enable",
                get = function()
                    return StanceAlert.db.enabled
                end,
                set = function(_, value)
                    StanceAlert.db.enabled = value
                    StanceAlert:RefreshConfig()
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
                            return StanceAlert.db.displayText
                        end,
                        set = function(_, value)
                            StanceAlert.db.displayText = value
                            onChange()
                        end
                    },
                    color = {
                        order = 2,
                        type = "color",
                        name = "Color",
                        width = 0.4,
                        hasAlpha = true,
                        get = function()
                            local c = StanceAlert.db.color
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            StanceAlert.db.color = {
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
                args = ItruliaQoL:createFontOptions(StanceAlert.db.font, function()
                    onChange()
                end)
            },
        }
    }
end
