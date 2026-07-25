local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "FriendlyNameplates"
local FriendlyNameplates = ItruliaQoL:GetModule(moduleName)

function FriendlyNameplates:GetDefaults()
    return {
        enabled = true,
        font = {
            fontFamily = "Expressway",
            fontSize = 14,
            fontOutline = "OUTLINESLUG",
        },
    }
end