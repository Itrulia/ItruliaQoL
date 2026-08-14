local addonName, ItruliaQoL = ...

local moduleName = "PetMissingIndicator"
local PetMissingIndicator = ItruliaQoL:GetModule(moduleName)

function PetMissingIndicator:PreparePreview(frame)
    frame.text:Show()
end
