local addonName, ItruliaQoL = ...

local moduleName = "SelfDispelAlert"
local SelfDispelAlert = ItruliaQoL:GetModule(moduleName)

function SelfDispelAlert:PreparePreview(frame)
    frame.gate:SetAlpha(1)
    frame.display:Show()
end
