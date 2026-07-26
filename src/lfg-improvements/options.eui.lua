local addonName, ItruliaQoL = ...

local moduleName = "LFGImprovements"
local LFGImprovements = ItruliaQoL:GetModule(moduleName)

function LFGImprovements:GetEUIOptions()
    return {
        name = "LFG Improvements",
        rows = {
            {
                type = "toggle",
                label = "Automatically accept the role call when signing up",
                get = function()
                    return LFGImprovements.db.autoAcceptRole.enabled
                end,
                set = function(value)
                    LFGImprovements.db.autoAcceptRole.enabled = value
                    LFGImprovements:RefreshConfig()
                end,
            },
            {
                type = "toggle",
                label = "Remind you in the chat what mythic+ key you joined",
                get = function()
                    return LFGImprovements.db.groupJoinedReminder.enabled
                end,
                set = function(value)
                    LFGImprovements.db.groupJoinedReminder.enabled = value
                    LFGImprovements:RefreshConfig()
                end,
            },
        },
    }
end
