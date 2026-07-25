local addonName, ItruliaQoL = ...

-- Top-level "General" page for EllesmereUI: Test mode + the shared "All" font.
-- Hand-authored (rendered by ellesmere.lua's PAGE_GENERAL), the manual
-- counterpart to general/options.ace.lua.
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

    -- The "All" font is a template pushed to every module via "Apply to all";
    -- editing it does nothing until that button (matches the ace onChange no-op).
    -- Frame strata/level are omitted here (per-frame, not part of the template).
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
