local addonName, ItruliaQoL = ...

local moduleName = "NoTargetIndicator"
local NoTargetIndicator = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function NoTargetIndicator:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "No Target Indicator",
        rows = {
            {
                text = "Shows an indicator text when player doesn't have a target when in combat",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return NoTargetIndicator.db.enabled
                end,
                set = function(value)
                    NoTargetIndicator.db.enabled = value
                    NoTargetIndicator:RefreshConfig()
                end,
            },
            {
                type = "toggle",
                label = "Include friendly target as valid target",
                get = function()
                    return NoTargetIndicator.db.friendlyisValidTarget
                end,
                set = function(value)
                    NoTargetIndicator.db.friendlyisValidTarget = value
                end,
            },
            {
                type = "input",
                label = "Display text",
                get = function()
                    return NoTargetIndicator.db.displayText
                end,
                set = function(value)
                    NoTargetIndicator.db.displayText = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = NoTargetIndicator.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    NoTargetIndicator.db.color = {
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
                rows = ItruliaQoL:EUIFontRows(NoTargetIndicator.db.font, apply),
            },
        },
    }
end
