local addonName, ItruliaQoL = ...

local moduleName = "RepairIndicator"
local RepairIndicator = ItruliaQoL:GetModule(moduleName)

function RepairIndicator:PreparePreview(frame)
    frame.text:Show()
end
