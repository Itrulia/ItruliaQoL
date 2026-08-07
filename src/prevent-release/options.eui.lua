local addonName, ItruliaQoL = ...

local moduleName = "PreventRelease"
local PreventRelease = ItruliaQoL:GetModule(moduleName)

function PreventRelease:GetEUIOptions()
    return {
        name = "Prevent Release",
        rows = {
            {
                text = "Disable release button unless you hold down ctrl",
            },
            {
                type = "toggle",
                label = "Only in a raid",
                get = function()
                    return PreventRelease.db.raidOnly
                end,
                set = function(value)
                    PreventRelease.db.raidOnly = value
                    PreventRelease:RefreshConfig()
                end,
            },
        },
    }
end
