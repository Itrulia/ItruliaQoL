local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "FocusTargetMarker"
local FocusTargetMarker = ItruliaQoL:GetModule(moduleName)

function FocusTargetMarker:GetDefaults()
    return {
        enabled = true,
        announce = true,
        marker = 5,
    }
end