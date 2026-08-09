local addonName, ItruliaQoL = ...

local moduleName = "StanceAlert"
local StanceAlert = ItruliaQoL:GetModule(moduleName)

function StanceAlert:PreparePreview(f)
    f.text:Show()
end
