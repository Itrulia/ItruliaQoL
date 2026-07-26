local addonName, ItruliaQoL = ...

local moduleName = "MeleeIndicator"
local MeleeIndicator = ItruliaQoL:GetModule(moduleName)

function MeleeIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Melee Indicator",
        rows = {
            {
                text = "Creates an indicator that shows up when you not in melee range as a melee spec",
            },
            {
                type = "input",
                label = "Display text",
                get = function()
                    return MeleeIndicator.db.displayText
                end,
                set = function(value)
                    MeleeIndicator.db.displayText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = MeleeIndicator.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    MeleeIndicator.db.color = {
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
                rows = ItruliaQoL:EUIFontRows(MeleeIndicator.db.font, apply),
            },
        },
    }
end
