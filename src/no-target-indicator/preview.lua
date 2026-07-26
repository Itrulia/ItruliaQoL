local addonName, ItruliaQoL = ...

local moduleName = "NoTargetIndicator"
local NoTargetIndicator = ItruliaQoL:GetModule(moduleName)

function NoTargetIndicator:PreparePreview(f)
    f.text:Show()
end
