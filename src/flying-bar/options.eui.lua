local addonName, ItruliaQoL = ...

local moduleName = "FlyingBar"
local FlyingBar = ItruliaQoL:GetModule(moduleName)

function FlyingBar:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

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
            ItruliaQoL:EUIStatusbarRow({
                get = function()
                    return FlyingBar.db[key].statusbarTexture
                end,
                set = function(value)
                    FlyingBar.db[key].statusbarTexture = value
                    apply()
                end,
            }),
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
