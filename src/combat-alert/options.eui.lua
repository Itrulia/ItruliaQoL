local addonName, ItruliaQoL = ...

local moduleName = "CombatAlert"
local CombatAlert = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function CombatAlert:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Combat Alert",
        rows = {
            {
                text = "Shows an alert when entering or leaving combat",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return CombatAlert.db.enabled
                end,
                set = function(value)
                    CombatAlert.db.enabled = value
                    CombatAlert:RefreshConfig()
                end,
            },
            {
                type = "input",
                label = "Combat starts text",
                get = function()
                    return CombatAlert.db.combatStartsText
                end,
                set = function(value)
                    CombatAlert.db.combatStartsText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Combat starts color",
                hasAlpha = true,
                get = function()
                    local c = CombatAlert.db.combatStartsColor
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    CombatAlert.db.combatStartsColor = {
                        r = r,
                        g = g,
                        b = b,
                        a = a,
                    }
                    apply()
                end,
            },
            {
                type = "input",
                label = "Combat ends text",
                get = function()
                    return CombatAlert.db.combatEndsText
                end,
                set = function(value)
                    CombatAlert.db.combatEndsText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Combat ends color",
                hasAlpha = true,
                get = function()
                    local c = CombatAlert.db.combatEndsColor
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    CombatAlert.db.combatEndsColor = {
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
                rows = ItruliaQoL:EUIFontRows(CombatAlert.db.font, apply),
            },
        },
    }
end
