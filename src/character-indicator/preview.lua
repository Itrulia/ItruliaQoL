local addonName, ItruliaQoL = ...

local moduleName = "CharacterIndicator"
local CharacterIndicator = ItruliaQoL:GetModule(moduleName)

function CharacterIndicator:PreparePreview(frame)
    frame.text:Show()
end
