local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "PreventRelease"
local PreventRelease = ItruliaQoL:GetModule(moduleName)

function PreventRelease:GetDefaults()
    return {
        enabled = false,
        raidOnly = false,
    }
end