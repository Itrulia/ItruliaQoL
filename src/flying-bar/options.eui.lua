local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "FlyingBar"
local FlyingBar = ItruliaQoL:GetModule(moduleName)

-- Hand-authored EllesmereUI settings, rendered by ellesmere.lua. Manual
-- counterpart to options.ace.lua's AceConfig table.
function FlyingBar:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    -- Per-statusbar appearance rows, mirroring options.ace.lua's
    -- createStatusbarOptions. `key` indexes FlyingBar.db live.
    local function statusbarRows(key)
        return {
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = FlyingBar.db[key].color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    FlyingBar.db[key].color = {
                        r = r,
                        g = g,
                        b = b,
                        a = a,
                    }
                    apply()
                end,
            },
            {
                type = "select",
                label = "Statusbar texture",
                values = LSM:HashTable("statusbar"),
                get = function()
                    return FlyingBar.db[key].statusbarTexture
                end,
                set = function(value)
                    FlyingBar.db[key].statusbarTexture = value
                    apply()
                end,
            },
            {
                type = "slider",
                label = "Height",
                min = 3,
                max = 20,
                step = 1,
                get = function()
                    return FlyingBar.db[key].height
                end,
                set = function(value)
                    FlyingBar.db[key].height = value
                    apply()
                end,
            },
        }
    end

    return {
        name = "Flying Bar",
        rows = {
            {
                text = "Dragonflying bar",
            },
            {
                type = "toggle",
                label = "Enable",
                get = function()
                    return FlyingBar.db.enabled
                end,
                set = function(value)
                    FlyingBar.db.enabled = value
                    FlyingBar:RefreshConfig()
                end,
            },
            {
                type = "slider",
                label = "Width",
                min = 10,
                max = 500,
                step = 1,
                get = function()
                    return FlyingBar.db.width
                end,
                set = function(value)
                    FlyingBar.db.width = value
                    apply()
                end,
            },
            {
                type = "select",
                label = "Frame strata",
                values = ItruliaQoL.FrameStrataSettings,
                get = function()
                    return FlyingBar.db.frameStrata or ItruliaQoL.FrameStrataSettings.BACKGROUND
                end,
                set = function(value)
                    FlyingBar.db.frameStrata = value
                    apply()
                end,
            },
            {
                type = "slider",
                label = "Frame level",
                min = 1,
                max = 10,
                step = 1,
                get = function()
                    return FlyingBar.db.frameLevel or 1
                end,
                set = function(value)
                    FlyingBar.db.frameLevel = value
                    apply()
                end,
            },
            {
                header = "Vigor",
                rows = statusbarRows("vigor"),
            },
            {
                header = "Second Wind",
                rows = statusbarRows("secondWind"),
            },
            {
                header = "Speed",
                rows = statusbarRows("speed"),
            },
        },
    }
end
