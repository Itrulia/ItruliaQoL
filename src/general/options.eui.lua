local addonName, ItruliaQoL = ...

function ItruliaQoL:GetGeneralEUIOptions()
    local rows = {
        {
            type = "toggle",
            label = "Test mode",
            get = function()
                return ItruliaQoL.testMode
            end,
            set = function(value)
                ItruliaQoL:ToggleTestMode(value)
            end,
        },
    }

    local all = ItruliaQoL.db.profile.all
    if all and all.font then
        rows[#rows + 1] = {
            header = "All Fonts",
            rows = ItruliaQoL:EUIFontRows(all.font, function() end, { strata = true, level = true }),
        }
        rows[#rows + 1] = {
            type = "execute",
            label = "Apply to all",
            func = function()
                ItruliaQoL:ApplyFontSettings()
            end,
        }
    end

    return { rows = rows }
end
