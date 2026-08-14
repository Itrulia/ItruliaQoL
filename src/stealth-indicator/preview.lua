local addonName, ItruliaQoL = ...

local moduleName = "StealthIndicator"
local StealthIndicator = ItruliaQoL:GetModule(moduleName)

function StealthIndicator:PreparePreview(frame)
    frame.text:Show()
end
