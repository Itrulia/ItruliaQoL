local addonName, ItruliaQoL = ...

local moduleName = "CursorCircle"
local CursorCircle = ItruliaQoL:GetModule(moduleName)

function CursorCircle:PreparePreview(frame)
    frame:Show()
end
