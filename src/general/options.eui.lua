local addonName, ItruliaQoL = ...

function ItruliaQoL:GetGeneralEUIOptions()
    local rows = {}

    local all = ItruliaQoL.db.profile.all
    if all and all.font then
        rows[#rows + 1] = {
            -- Read through the db rather than the local: `all` belongs to the profile
            -- that is current right now, and switching profiles replaces it.
            rows = ItruliaQoL:EUIFontRows(function() return ItruliaQoL.db.profile.all.font end, function() end, { strata = true, level = true }),
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
