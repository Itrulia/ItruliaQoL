local addonName, ItruliaQoL = ...

local moduleName = "MeleeIndicator"
local MeleeIndicator = ItruliaQoL:GetModule(moduleName)

function MeleeIndicator:PreparePreview(f)
    f.text:Show()
end
