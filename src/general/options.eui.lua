local addonName, ItruliaQoL = ...

function ItruliaQoL:GetGeneralEUIOptions()
    local rows = {}

    local all = ItruliaQoL.db.profile.all
    if all and all.font then
        rows[#rows + 1] = {
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
