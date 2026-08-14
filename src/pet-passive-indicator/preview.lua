local addonName, ItruliaQoL = ...

local moduleName = "PetPassiveIndicator"
local PetPassiveIndicator = ItruliaQoL:GetModule(moduleName)

function PetPassiveIndicator:PreparePreview(frame)
    frame.text:Show()
end
