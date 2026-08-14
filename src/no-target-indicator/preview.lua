local addonName, ItruliaQoL = ...

local moduleName = "NoTargetIndicator"
local NoTargetIndicator = ItruliaQoL:GetModule(moduleName)

function NoTargetIndicator:PreparePreview(frame)
    frame.text:Show()
end
