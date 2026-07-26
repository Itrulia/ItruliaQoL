local addonName, ItruliaQoL = ...

local moduleName = "RepairIndicator"
local RepairIndicator = ItruliaQoL:GetModule(moduleName)

function RepairIndicator:PreparePreview(f)
    f.text:Show()
end
