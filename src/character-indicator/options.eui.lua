local addonName, ItruliaQoL = ...

local moduleName = "CharacterIndicator"
local CharacterIndicator = ItruliaQoL:GetModule(moduleName)

function CharacterIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    local displayRow = {
        type = "color",
        label = "Display",
        hasAlpha = true,
        get = function()
            local color = CharacterIndicator.db.color
            return color.r, color.g, color.b, color.a
        end,
        set = function(r, g, b, a)
            CharacterIndicator.db.color = {
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
                        return CharacterIndicator.db.displayText or ""
                    end,
                    set = function(value)
                        CharacterIndicator.db.displayText = value
                        apply()
                    end,
                },
            },
        },
    }

    return {
        name = "Character Indicator",
        rows = ItruliaQoL:EUIFontRows(CharacterIndicator.db.font, apply, nil, { displayRow }),
    }
end
