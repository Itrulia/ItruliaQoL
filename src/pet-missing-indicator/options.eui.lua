local addonName, ItruliaQoL = ...

local moduleName = "PetMissingIndicator"
local PetMissingIndicator = ItruliaQoL:GetModule(moduleName)

function PetMissingIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Pet Missing",
        rows = {
            {
                text = "Displays a text when you are a pet spec and your pet is missing",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return PetMissingIndicator.db.enabled
                end,
                set = function(value)
                    PetMissingIndicator.db.enabled = value
                    PetMissingIndicator:RefreshConfig()
                end,
            },
            {
                type = "input",
                label = "Display text",
                get = function()
                    return PetMissingIndicator.db.displayText
                end,
                set = function(value)
                    PetMissingIndicator.db.displayText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = PetMissingIndicator.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    PetMissingIndicator.db.color = {
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
                rows = ItruliaQoL:EUIFontRows(PetMissingIndicator.db.font, apply),
            },
        },
    }
end
