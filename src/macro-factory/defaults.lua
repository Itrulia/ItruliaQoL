local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "MacroFactory"
local MacroFactory = ItruliaQoL:GetModule(moduleName)

function MacroFactory:GetDefaults()
    return {
        enabled = true,
    }
end