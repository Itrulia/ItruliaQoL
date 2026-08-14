local addonName, ItruliaQoL = ...

local moduleName = "PotionAlert"
local PotionAlert = ItruliaQoL:GetModule(moduleName)

function PotionAlert:PreparePreview(frame)
    frame.text:Show()
end
