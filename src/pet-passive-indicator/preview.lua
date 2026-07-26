local addonName, ItruliaQoL = ...

local moduleName = "PetPassiveIndicator"
local PetPassiveIndicator = ItruliaQoL:GetModule(moduleName)

function PetPassiveIndicator:PreparePreview(f)
    f.text:Show()
end
