local addonName, ItruliaQoL = ...

local moduleName = "CharacterIndicator"
local CharacterIndicator = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function CharacterIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Character Indicator",
        rows = {
            {
                text = "Creates an indicator that is always on during combat indicating where you are",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return CharacterIndicator.db.enabled
                end,
                set = function(value)
                    CharacterIndicator.db.enabled = value
                    CharacterIndicator:RefreshConfig()
                end,
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
