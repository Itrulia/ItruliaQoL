local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "FocusTargetMarker"
local FocusTargetMarker = ItruliaQoL:GetModule(moduleName)

function FocusTargetMarker:GetDefaults()
    return {
        enabled = true,
        announce = not ItruliaQoL.isForever,
        marker = 5,
    }
end