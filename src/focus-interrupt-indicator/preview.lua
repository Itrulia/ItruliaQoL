local addonName, ItruliaQoL = ...

local moduleName = "FocusInterruptIndicator"
local FocusInterruptIndicator = ItruliaQoL:GetModule(moduleName)

function FocusInterruptIndicator:PreparePreview(f)
    f.text:Show()
    f.text:SetAlpha(1)
end
