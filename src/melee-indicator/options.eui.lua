local addonName, ItruliaQoL = ...

local moduleName = "MeleeIndicator"
local MeleeIndicator = ItruliaQoL:GetModule(moduleName)

function MeleeIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    local displayRow = {
        type = "color",
        label = "Display",
        hasAlpha = true,
        get = function()
            local color = MeleeIndicator.db.color
            return color.r, color.g, color.b, color.a
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
        cog = {
            title = "Alert Text",
            rows = {
                {
                    type = "input",
                    label = "Text",
                    width = 120,
                    get = function()
                        return MeleeIndicator.db.displayText or ""
                    end,
                    set = function(value)
                        MeleeIndicator.db.displayText = value
                        apply()
                    end,
                },
            },
        },
    }

    return {
        name = "Melee Indicator",
        rows = ItruliaQoL:EUIFontRows(function() return MeleeIndicator.db.font end, apply, nil, { displayRow }),
    }
end
