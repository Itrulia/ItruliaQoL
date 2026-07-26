local addonName, ItruliaQoL = ...

local moduleName = "LFGImprovements"
local LFGImprovements = ItruliaQoL:GetModule(moduleName)

function LFGImprovements:GetOptions(onChange)
    return {
        order = 2,
        type = "group",
        name = "LFG Improvements",
        args = {
            description = {
                type = "description",
                name = "Group Finder helpers: automatic role confirmation and a reminder of the key you joined\n\n",
                width = "full",
                order = 1,
            },
            enable = {
                order = 2,
                type = "toggle",
                width = "full",
                name = "Enable",
                get = function()
                    return LFGImprovements.db.enabled
                end,
                set = function(_, value)
                    LFGImprovements.db.enabled = value
                    LFGImprovements:RefreshConfig()
                end,
            },
            autoAcceptRole = {
                order = 10,
                type = "toggle",
                width = "full",
                name = "Automatically accept the role call when signing up",
                disabled = function()
                    return not LFGImprovements.db.enabled
                end,
                get = function()
                    return LFGImprovements.db.autoAcceptRole.enabled
                end,
                set = function(_, value)
                    LFGImprovements.db.autoAcceptRole.enabled = value
                    LFGImprovements:RefreshConfig()
                end,
            },
            groupJoinedReminder = {
                order = 20,
                type = "toggle",
                width = "full",
                name = "Remind you in the chat what mythic+ key you joined",
                disabled = function()
                    return not LFGImprovements.db.enabled
                end,
                get = function()
                    return LFGImprovements.db.groupJoinedReminder.enabled
                end,
                set = function(_, value)
                    LFGImprovements.db.groupJoinedReminder.enabled = value
                    LFGImprovements:RefreshConfig()
                end,
            },
        }
    }
end
