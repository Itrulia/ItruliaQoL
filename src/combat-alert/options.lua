local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "CombatAlert"
local CombatAlert = ItruliaQoL:GetModule(moduleName)

function CombatAlert:GetOptions(onChange)
    return {
        order = 2,
        type = "group",
        name = "Combat Alert",
        args = {
            description = {
                type = "description",
                name = "Shows an alert when entering or leaving combat \n\n",
                width = "full",
                order = 1,
            },
            enable = {
                order = 2,
                type = "toggle",
                width = "full",
                name = "Enable",
                get = function()
                    return CombatAlert.db.enabled
                end,
                set = function(_, value)
                    CombatAlert.db.enabled = value
                    CombatAlert:RefreshConfig()
                end
            },
            displaySettings = {
                type = "group",
                name = "",
                order = 4,
                inline = true,
                args = {
                    combatStartsText = {
                        order = 1,
                        type = "input",
                        name = "Combat starts text",
                        get = function()
                            return CombatAlert.db.combatStartsText
                        end,
                        set = function(_, value)
                            CombatAlert.db.combatStartsText = value
                            onChange()
                        end
                    },
                    combatStartsColor = {
                        order = 2,
                        type = "color",
                        name = "Combat starts color",
                        hasAlpha = true,
                        get = function()
                            local c = CombatAlert.db.combatStartsColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            CombatAlert.db.combatStartsColor = {
                                r = r,
                                g = g,
                                b = b,
                                a = a
                            }
                            onChange()
                        end
                    },
                    spacer = {
                        type = "description",
                        name = "",
                        width = "full",
                        order = 3,
                    },
                    combatEndsText = {
                        order = 3,
                        type = "input",
                        name = "Combat ends text",
                        get = function()
                            return CombatAlert.db.combatEndsText
                        end,
                        set = function(_, value)
                            CombatAlert.db.combatEndsText = value
                            onChange()
                        end
                    },
                    combatEndsColor = {
                        order = 4,
                        type = "color",
                        name = "Combat ends color",
                        hasAlpha = true,
                        get = function()
                            local c = CombatAlert.db.combatEndsColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            CombatAlert.db.combatEndsColor = {
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
                args = ItruliaQoL:createFontOptions(CombatAlert.db.font, function() 
                    onChange()
                end)
            },
        }
    }
end