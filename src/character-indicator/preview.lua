local addonName, ItruliaQoL = ...

local moduleName = "CharacterIndicator"
local CharacterIndicator = ItruliaQoL:GetModule(moduleName)

function CharacterIndicator:PreparePreview(f)
    f.text:Show()
end
