local addonName, ItruliaQoL = ...

local moduleName = "StealthIndicator"
local StealthIndicator = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function StealthIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Stealth Indicator",
        rows = {
            {
                text = "Shows an indicator text when stealthed (not invisible)",
            },
            {
                type = "input",
                label = "Display text",
                get = function()
                    return StealthIndicator.db.displayText
                end,
                set = function(value)
                    StealthIndicator.db.displayText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = StealthIndicator.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    StealthIndicator.db.color = {
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
                rows = ItruliaQoL:EUIFontRows(StealthIndicator.db.font, apply),
            },
        },
    }
end
