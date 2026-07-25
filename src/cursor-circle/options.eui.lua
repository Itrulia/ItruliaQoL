local addonName, ItruliaQoL = ...

local moduleName = "CursorCircle"
local CursorCircle = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function CursorCircle:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Cursor Circle",
        rows = {
            {
                text = "Puts a circle arounds your cursor",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return CursorCircle.db.enabled
                end,
                set = function(value)
                    CursorCircle.db.enabled = value
                    CursorCircle:RefreshConfig()
                end,
            },
            {
                type = "toggle",
                label = "Only during combat",
                get = function()
                    return CursorCircle.db.onlyDuringCombat
                end,
                set = function(value)
                    CursorCircle.db.onlyDuringCombat = value
                    apply()
                end,
            },
            {
                type = "select",
                label = "Display texture",
                values = CursorCircle.CursorTextures,
                get = function()
                    return CursorCircle.db.displayTexture
                end,
                set = function(value)
                    CursorCircle.db.displayTexture = value
                    apply()
                end,
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = CursorCircle.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    CursorCircle.db.color = {
                        r = r,
                        g = g,
                        b = b,
                        a = a,
                    }
                    apply()
                end,
            },
            {
                type = "slider",
                label = "Size",
                min = 10,
                max = 100,
                step = 1,
                get = function()
                    return CursorCircle.db.size
                end,
                set = function(value)
                    CursorCircle.db.size = value
                    apply()
                end,
            },
        },
    }
end
