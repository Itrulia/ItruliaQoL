local addonName, ItruliaQoL = ...

local moduleName = "StealthIndicator"
local StealthIndicator = ItruliaQoL:GetModule(moduleName)

function StealthIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    local displayRow = {
        type = "color",
        label = "Display",
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
        cog = {
            title = "Alert Text",
            rows = {
                {
                    type = "input",
                    label = "Text",
                    width = 120,
                    get = function()
                        return StealthIndicator.db.displayText or ""
                    end,
                    set = function(value)
                        StealthIndicator.db.displayText = value
                        apply()
                    end,
                },
            },
        },
    }

    return {
        name = "Stealth Indicator",
        rows = ItruliaQoL:EUIFontRows(StealthIndicator.db.font, apply, nil, { displayRow }),
    }
end
