local addonName, ItruliaQoL = ...

local moduleName = "HealerManaIndicator"
local HealerManaIndicator = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function HealerManaIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Healer Mana Indicator",
        rows = {
            {
                text = "Shows the mana of your healers",
            },
            {
                type = "toggle",
                label = "Enable",
                refresh = true,
                get = function()
                    return HealerManaIndicator.db.enabled
                end,
                set = function(value)
                    HealerManaIndicator.db.enabled = value
                    HealerManaIndicator:RefreshConfig()
                end,
            },
            {
                type = "toggle",
                label = "Enable in dungeons",
                disabled = function()
                    return not HealerManaIndicator.db.enabled
                end,
                get = function()
                    return HealerManaIndicator.db.enableInDungeons
                end,
                set = function(value)
                    HealerManaIndicator.db.enableInDungeons = value
                    apply()
                end,
            },
            {
                type = "toggle",
                label = "Enable in raids",
                disabled = function()
                    return not HealerManaIndicator.db.enabled
                end,
                get = function()
                    return HealerManaIndicator.db.enableInRaids
                end,
                set = function(value)
                    HealerManaIndicator.db.enableInRaids = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = HealerManaIndicator.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    HealerManaIndicator.db.color = {
                        r = r,
                        g = g,
                        b = b,
                        a = a,
                    }
                    apply()
                end,
            },
            {
                type = "toggle",
                label = "Grow upwards",
                get = function()
                    return HealerManaIndicator.db.growUpwards
                end,
                set = function(value)
                    HealerManaIndicator.db.growUpwards = value
                    apply()
                end,
            },
            {
                header = "Font",
                rows = ItruliaQoL:EUIFontRows(HealerManaIndicator.db.font, apply),
            },
        },
    }
end
