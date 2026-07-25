local addonName, ItruliaQoL = ...

local moduleName = "PreventRelease"
local PreventRelease = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function PreventRelease:GetEUIOptions()
    return {
        name = "Prevent Release",
        rows = {
            {
                text = "Disable release button unless you hold down ctrl",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return PreventRelease.db.enabled
                end,
                set = function(value)
                    PreventRelease.db.enabled = value
                    PreventRelease:RefreshConfig()
                end,
            },
        },
    }
end
