local addonName, ItruliaQoL = ...

local moduleName = "RepairIndicator"
local RepairIndicator = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function RepairIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Repair Indicator",
        rows = {
            {
                text = "Displays a text when one of your items is broken or about to be",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return RepairIndicator.db.enabled
                end,
                set = function(value)
                    RepairIndicator.db.enabled = value
                    RepairIndicator:RefreshConfig()
                end,
            },
            {
                type = "input",
                label = "Display text",
                get = function()
                    return RepairIndicator.db.displayText
                end,
                set = function(value)
                    RepairIndicator.db.displayText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = RepairIndicator.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    RepairIndicator.db.color = {
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
                rows = ItruliaQoL:EUIFontRows(RepairIndicator.db.font, apply),
            },
        },
    }
end
