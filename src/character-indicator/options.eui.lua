local addonName, ItruliaQoL = ...

local moduleName = "CharacterIndicator"
local CharacterIndicator = ItruliaQoL:GetModule(moduleName)

function CharacterIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Character Indicator",
        rows = {
            {
                text = "Creates an indicator that is always on during combat indicating where you are",
            },
            {
                type = "input",
                label = "Display text",
                get = function()
                    return CharacterIndicator.db.displayText
                end,
                set = function(value)
                    CharacterIndicator.db.displayText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = CharacterIndicator.db.color
                    return c.r, c.g, c.b, c.a
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
            },
            {
                header = "Font",
                rows = ItruliaQoL:EUIFontRows(CharacterIndicator.db.font, apply),
            },
        },
    }
end
