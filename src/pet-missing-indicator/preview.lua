local addonName, ItruliaQoL = ...

local moduleName = "PetMissingIndicator"
local PetMissingIndicator = ItruliaQoL:GetModule(moduleName)

function PetMissingIndicator:PreparePreview(f)
    f.text:Show()
end
