local addonName, ItruliaQoL = ...

local moduleName = "AutoAcceptRole"
local AutoAcceptRole = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function AutoAcceptRole:GetEUIOptions()
    return {
        name = "Auto Role Accept",
        rows = {
            {
                text = "Automatically accept the role call when signing up",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return AutoAcceptRole.db.enabled
                end,
                set = function(value)
                    AutoAcceptRole.db.enabled = value
                    AutoAcceptRole:RefreshConfig()
                end,
            },
        },
    }
end
