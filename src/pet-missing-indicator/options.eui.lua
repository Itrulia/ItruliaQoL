local addonName, ItruliaQoL = ...

local moduleName = "PetMissingIndicator"
local PetMissingIndicator = ItruliaQoL:GetModule(moduleName)

function PetMissingIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    -- The row's own Enable, because the sidebar switch on a combined row sets both
    -- pet indicators at once. It leads the font settings alongside the colour, so
    -- the page opens on one row of the two things per indicator worth reaching for.
    local enableRow = {
        type = "toggle",
        label = "Enable",
        get = function()
            return PetMissingIndicator.db.enabled
        end,
        set = function(value)
            PetMissingIndicator.db.enabled = value
            PetMissingIndicator:RefreshConfig()
        end,
    }

    local displayRow = {
        type = "color",
        label = "Display",
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
        cog = {
            title = "Alert Text",
            rows = {
                {
                    type = "input",
                    label = "Text",
                    width = 120,
                    get = function()
                        return PetMissingIndicator.db.displayText or ""
                    end,
                    set = function(value)
                        PetMissingIndicator.db.displayText = value
                        apply()
                    end,
                },
            },
        },
    }

    return {
        name = "Pet Missing",
        rows = ItruliaQoL:EUIFontRows(PetMissingIndicator.db.font, apply, nil, { enableRow, displayRow }),
    }
end
