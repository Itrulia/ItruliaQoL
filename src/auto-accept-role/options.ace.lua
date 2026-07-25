local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "AutoAcceptRole"
local AutoAcceptRole = ItruliaQoL:GetModule(moduleName)

function AutoAcceptRole:GetOptions(onChange)
    return {
        order = 2,
        type = "group",
        name = "Auto Role Accept",
        args = {
            description = {
                type = "description",
                name =  "Automatically accept the role call when signing up\n\n",
                width = "full",
                order = 1,
            },
            enable = {
                order = 2,
                type = "toggle",
                width = "full",
                name = "Enable",
                get = function() 
                    return AutoAcceptRole.db.enabled
                end,
                set = function(_, value)
                    AutoAcceptRole.db.enabled = value
                    AutoAcceptRole:RefreshConfig()
                end,
            },
        }
    }
end