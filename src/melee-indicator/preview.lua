local addonName, ItruliaQoL = ...

local moduleName = "MeleeIndicator"
local MeleeIndicator = ItruliaQoL:GetModule(moduleName)

function MeleeIndicator:PreparePreview(frame)
    frame.text:Show()
end
