local addonName, ItruliaQoL = ...

local moduleName = "StealthIndicator"
local StealthIndicator = ItruliaQoL:GetModule(moduleName)

function StealthIndicator:PreparePreview(f)
    f.text:Show()
end
