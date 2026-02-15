local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "AutoAcceptRole"
local AutoAcceptRole = ItruliaQoL:GetModule(moduleName)

function AutoAcceptRole:GetDefaults()
    return {
        enabled = true,
    }
end