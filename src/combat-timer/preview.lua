local addonName, ItruliaQoL = ...

local moduleName = "CombatTimer"
local CombatTimer = ItruliaQoL:GetModule(moduleName)

function CombatTimer:PreparePreview(f)
    f.text:SetText(f:FormatTime(83))
    f.text:Show()
    f:UpdateStyles()
end
