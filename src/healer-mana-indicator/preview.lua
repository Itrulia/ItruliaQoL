local addonName, ItruliaQoL = ...

local moduleName = "HealerManaIndicator"
local HealerManaIndicator = ItruliaQoL:GetModule(moduleName)

function HealerManaIndicator:PreparePreview(f)
    f:ClearTexts()
    f:UpdateManaText(1, "player", 69)
    f:UpdateManaText(2, "player", 50)
    f:UpdateStyles()
end
