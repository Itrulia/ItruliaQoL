local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "FriendlyNameplates"
local FriendlyNameplates = ItruliaQoL:GetModule(moduleName)

function FriendlyNameplates:GetOptions(onChange)
    return {
        order = 2,
        type = "group",
        name = "Friendly Nameplates",
        args = {
            description = {
                type = "description",
                name =  "Improves the display of the friendly nameplates in instances\n\n",
                width = "full",
                order = 1,
            },
            enable = {
                order = 2,
                type = "toggle",
                width = "full",
                name = "Enable",
                get = function() 
                    return FriendlyNameplates.db.enabled
                end,
                set = function(_, value)
                    FriendlyNameplates.db.enabled = value
                    FriendlyNameplates:RefreshConfig()
                end,
            },
            fontSettings = {
                type = "group",
                name = "",
                order = 3,
                inline = true,
                args = ItruliaQoL:createFontOptions(function() return FriendlyNameplates.db.font end, function() 
                    onChange()
                end, {
                    justifyH = ItruliaQoL.MergeDeep_Delete_Key,
                    spacer = ItruliaQoL.MergeDeep_Delete_Key,
                    fontShadowXOffset = ItruliaQoL.MergeDeep_Delete_Key,
                    fontShadowYOffset = ItruliaQoL.MergeDeep_Delete_Key,
                    fontShadowColor = ItruliaQoL.MergeDeep_Delete_Key,
                    spacer2 = ItruliaQoL.MergeDeep_Delete_Key,
                    frameStrata = ItruliaQoL.MergeDeep_Delete_Key,
                    frameLevel = ItruliaQoL.MergeDeep_Delete_Key,
                })
            },
        }
    }
end