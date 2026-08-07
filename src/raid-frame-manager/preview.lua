local addonName, ItruliaQoL = ...

local moduleName = "RaidFrameManager"
local RaidFrameManager = ItruliaQoL:GetModule(moduleName)

RaidFrameManager.pageDisplay = "Display"
RaidFrameManager.pageActions = "Actions"
RaidFrameManager.pagePullTimers = "Pull Timers"

function RaidFrameManager:PreparePreview(f)
    f:UpdateStyles()
    f:Show()
end
