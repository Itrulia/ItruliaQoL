local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "GroupJoinedReminder"
local GroupJoinedReminder = ItruliaQoL:GetModule(moduleName)

function GroupJoinedReminder:GetDefaults()
    return {
        enabled = true,
    }
end