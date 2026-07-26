local addonName, ItruliaQoL = ...

local moduleName = "PotionAlert"
local PotionAlert = ItruliaQoL:GetModule(moduleName)

function PotionAlert:PreparePreview(f)
    f.text:Show()
end
