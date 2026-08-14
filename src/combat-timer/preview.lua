local addonName, ItruliaQoL = ...

local moduleName = "CombatTimer"
local CombatTimer = ItruliaQoL:GetModule(moduleName)

function CombatTimer:PreparePreview(frame)
    frame.text:SetText(frame:FormatTime(83))
    frame.text:Show()
    frame:UpdateStyles()
end
