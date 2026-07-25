local addonName, ItruliaQoL = ...

local moduleName = "GroupJoinedReminder"
local GroupJoinedReminder = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function GroupJoinedReminder:GetEUIOptions()
    return {
        name = "Group Joined Reminder",
        rows = {
            {
                text = "Reminds you in the chat what mythic+ key you joined",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return GroupJoinedReminder.db.enabled
                end,
                set = function(value)
                    GroupJoinedReminder.db.enabled = value
                    GroupJoinedReminder:RefreshConfig()
                end,
            },
        },
    }
end
