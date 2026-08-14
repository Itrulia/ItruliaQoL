local addonName, ItruliaQoL = ...

local moduleName = "StanceAlert"
local StanceAlert = ItruliaQoL:GetModule(moduleName)

function StanceAlert:PreparePreview(frame)
    frame.text:Show()
end
