local addonName, ItruliaQoL = ...

local moduleName = "CombatTimer"
local CombatTimer = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function CombatTimer:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Combat Timer",
        rows = {
            {
                text = "Shows a combat timer",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return CombatTimer.db.enabled
                end,
                set = function(value)
                    CombatTimer.db.enabled = value
                    CombatTimer:RefreshConfig()
                end,
            },
            {
                type = "select",
                label = "Time format",
                values = {
                    SECONDS = CombatTimer.timeFormats.SECONDS.display,
                    SECONDS_BRACKET = CombatTimer.timeFormats.SECONDS_BRACKET.display,
                    CLOCK = CombatTimer.timeFormats.CLOCK.display,
                    CLOCK_BRACKET = CombatTimer.timeFormats.CLOCK_BRACKET.display,
                },
                get = function()
                    return CombatTimer.db.timeFormat
                end,
                set = function(value)
                    CombatTimer.db.timeFormat = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Combat starts color",
                hasAlpha = true,
                get = function()
                    local c = CombatTimer.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    CombatTimer.db.color = {
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
                rows = ItruliaQoL:EUIFontRows(CombatTimer.db.font, apply),
            },
        },
    }
end
