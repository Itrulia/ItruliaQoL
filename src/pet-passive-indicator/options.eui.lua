local addonName, ItruliaQoL = ...

local moduleName = "PetPassiveIndicator"
local PetPassiveIndicator = ItruliaQoL:GetModule(moduleName)

function PetPassiveIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Pet Passive",
        rows = {
            {
                text = "Displays a text when you have a pet and it's set to passive",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return PetPassiveIndicator.db.enabled
                end,
                set = function(value)
                    PetPassiveIndicator.db.enabled = value
                    PetPassiveIndicator:RefreshConfig()
                end,
            },
            {
                type = "input",
                label = "Display text",
                get = function()
                    return PetPassiveIndicator.db.displayText
                end,
                set = function(value)
                    PetPassiveIndicator.db.displayText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = PetPassiveIndicator.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    PetPassiveIndicator.db.color = {
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
                rows = ItruliaQoL:EUIFontRows(PetPassiveIndicator.db.font, apply),
            },
        },
    }
end
