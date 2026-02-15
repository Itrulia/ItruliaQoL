local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

ItruliaQoL.MergeDeep_Delete_Key = {}

function ItruliaQoL:MergeDeep(a, b)
    local result = {}

    for k, v in pairs(a) do
        if type(v) == "table" then
            result[k] = self:MergeDeep(v, {})
        else
            result[k] = v
        end
    end

    for k, v in pairs(b) do
        if v == ItruliaQoL.MergeDeep_Delete_Key then
          result[k] = nil
        elseif type(v) == "table" and type(result[k]) == "table" then
            result[k] = self:MergeDeep(result[k], v)
        else
            result[k] = v
        end
    end

    return result
end

ItruliaQoL.FrameStrataSettings = {
    BACKGROUND = "BACKGROUND",
    LOW = "LOW",
    MEDIUM = "MEDIUM",
    HIGH = "HIGH",
    DIALOG = "DIALOG",
    FULLSCREEN = "FULLSCREEN",
    FULLSCREEN_DIALOG = "FULLSCREEN_DIALOG",
    TOOLTIP = "TOOLTIP",
}

ItruliaQoL.OutlineSettings = {
    NONE = "None",
    OUTLINE = "Outline",
    THICKOUTLINE = "Thick Outline",
    MONOCHROME = "Monochrome"
}

function ItruliaQoL:createFontOptions(fontObject, onChange, additionalOptions)
    return ItruliaQoL:MergeDeep({
        font = {
            order = 10,
            type = "select",
            dialogControl = "LSM30_Font",
            name = "Font",
            values = LSM:HashTable("font"),
            get = function()
                return fontObject.fontFamily
            end,
            set = function(_, value)
                fontObject.fontFamily = value
                
                if onChange then
                    onChange()
                end
            end
        },
        fontSize = {
            order = 20,
            type = "range",
            name = "Size",
            min = 1,
            max = 68,
            step = 1,
            get = function()
                return fontObject.fontSize
            end,
            set = function(_, value)
                fontObject.fontSize = value
                
                if onChange then
                    onChange()
                end
            end
        },
        fontOutline = {
            order = 30,
            type = "select",
            name = "Outline",
            values = ItruliaQoL.OutlineSettings,
            get = function()
                return fontObject.fontOutline
            end,
            set = function(_, value)
                fontObject.fontOutline = value ~= "NONE" and value or nil
                
                if onChange then
                    onChange()
                end
            end
        },
        spacer = {
            type = "description",
            name =  "",
            width = "full",
            order = 39,
        },
        fontShadowColor = {
            order = 40,
            type = "color",
            name = "Shadow Color",
            hasAlpha = true,
            get = function()
                local c = fontObject.fontShadowColor
                return c.r, c.g, c.b, c.a
            end,
            set = function(_, r, g, b, a)
                fontObject.fontShadowColor = {
                    r = r,
                    g = g,
                    b = b,
                    a = a
                }
                
                if onChange then
                    onChange()
                end
            end
        },
        fontShadowXOffset = {
            order = 50,
            type = "range",
            name = "Shadow X Offset",
            min = -5,
            max = 5,
            step = 1,
            get = function()
                return fontObject.fontShadowXOffset
            end,
            set = function(_, value)
                fontObject.fontShadowXOffset = value
                
                if onChange then
                    onChange()
                end
            end
        },
        fontShadowYOffset = {
            order = 60,
            type = "range",
            name = "Shadow Y Offset",
            min = -5,
            max = 5,
            step = 1,
            get = function()
                return fontObject.fontShadowYOffset
            end,
            set = function(_, value)
                fontObject.fontShadowYOffset = value
                
                if onChange then
                    onChange()
                end
            end
        },
        spacer2 = {
            type = "description",
            name =  "",
            width = "full",
            order = 69,
        },
        frameStrata = {
            order = 70,
            type = "select",
            name = "Frame strata",
            values = ItruliaQoL.FrameStrataSettings,
            get = function()
                return fontObject.frameStrata or ItruliaQoL.FrameStrataSettings.BACKGROUND
            end,
            set = function(_, value)
                fontObject.frameStrata = value
                
                if onChange then
                    onChange()
                end
            end,
        },
        frameLevel = {
            order = 80,
            type = "range",
            name = "Frame level",
            min = 1,
            max = 10,
            step = 1,
            get = function()
                return fontObject.frameLevel or 1
            end,
            set = function(_, value)
                fontObject.frameLevel = value
                
                if onChange then
                    onChange()
                end
            end
        }
    }, additionalOptions or {})
end