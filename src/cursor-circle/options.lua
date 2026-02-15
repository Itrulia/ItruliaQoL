local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "CursorCircle"
local CursorCircle = ItruliaQoL:GetModule(moduleName)

function CursorCircle:GetOptions(onChange)
    return {
        order = 2,
        type = "group",
        name = "Cursor Circle",
        args = {
            description = {
                type = "description",
                name = "Puts a circle arounds your cursor \n\n",
                width = "full",
                order = 1,
            },
            enable = {
                order = 2,
                type = "toggle",
                width = "full",
                name = "Enable",
                get = function()
                    return CursorCircle.db.enabled
                end,
                set = function(_, value)
                    CursorCircle.db.enabled = value
                    CursorCircle:RefreshConfig()
                end
            },
            displaySettings = {
                type = "group",
                name = "",
                order = 4,
                inline = true,
                args = {
                    displayTexture = {
                        order = 1,
                        type = "select",
                        values = CursorCircle.CursorTextures,
                        name = "Display texture",
                        get = function()
                            return CursorCircle.db.displayTexture
                        end,
                        set = function(_, value)
                            CursorCircle.db.displayTexture = value
                            onChange()
                        end
                    },
                    color = {
                        order = 2,
                        type = "color",
                        name = "Color",
                        width = 0.4,
                        hasAlpha = true,
                        get = function()
                            local c = CursorCircle.db.color
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            CursorCircle.db.color = {
                                r = r,
                                g = g,
                                b = b,
                                a = a
                            }
                            onChange()
                        end
                    },
                    size = {
                        order = 3,
                        type = "range",
                        name = "Size",
                        min = 10,
                        max = 100,
                        step = 1,
                        get = function()
                            return CursorCircle.db.size
                        end,
                        set = function(_, value)
                            CursorCircle.db.size = value
                            
                            if onChange then
                                onChange()
                            end
                        end
                    },
                }
            },
        }
    }
end