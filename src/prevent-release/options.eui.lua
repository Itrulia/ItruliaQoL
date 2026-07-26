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
        },
    }
end
