local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "GroupJoinedReminder"
local GroupJoinedReminder = ItruliaQoL:GetModule(moduleName)

function GroupJoinedReminder:GetOptions(onChange)
    return {
        order = 2,
        type = "group",
        name = "Group Joined Reminder",
        args = {
            description = {
                type = "description",
                name =  "Reminds you in the chat what mythic+ key you joined\n\n",
                width = "full",
                order = 1,
            },
            enable = {
                order = 2,
                type = "toggle",
                width = "full",
                name = "Enable",
                get = function() 
                    return GroupJoinedReminder.db.enabled
                end,
                set = function(_, value)
                    GroupJoinedReminder.db.enabled = value
                    GroupJoinedReminder:RefreshConfig()
                end,
            },
        }
    }
end