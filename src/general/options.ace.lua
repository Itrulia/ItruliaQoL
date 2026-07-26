local addonName, ItruliaQoL = ...

function ItruliaQoL:GetGeneralOptions()
    return {
        description = {
            type = "description",
            name =  "You can move things around using the native Edit Mode. Test mode will automatically be turned on\n\n Note that it ignores the Edit Mode layouts \n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
            type = "toggle",
            width = "full",
            name = "Test mode",
            get = function()
                return ItruliaQoL.testMode
            end,
            set = function(_, value)
                ItruliaQoL:ToggleTestMode(value)
            end
        },
        all = {
            type = "group",
            name = "All",
            order = 1,
            args = {
                fontSettings = {
                    type = "group",
                    name = "Font",
                    inline = true,
                    args = ItruliaQoL:createFontOptions(ItruliaQoL.db.profile.all.font, function() end, {
                        frameStrata = ItruliaQoL.MergeDeep_Delete_Key,
                        frameLevel = ItruliaQoL.MergeDeep_Delete_Key,
                        applyAll = {
                            type = "execute",
                            name = "Apply to all",
                            func = function()
                                ItruliaQoL:ApplyFontSettings()
                            end,
                        },
                    })
                },
            }
        },
    }
end
