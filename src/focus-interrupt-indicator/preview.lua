local addonName, ItruliaQoL = ...

local moduleName = "FocusInterruptIndicator"
local FocusInterruptIndicator = ItruliaQoL:GetModule(moduleName)

function FocusInterruptIndicator:PreparePreview(frame)
    frame.text:Show()
    frame.text:SetAlpha(1)
end
