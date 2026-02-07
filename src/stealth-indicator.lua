local addonName, ItruliaQoL = ...
local moduleName = "StealthIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local StealthIndicator = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 50)
frame:SetSize(28, 28)

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 14, "OUTLINE")
frame.text:SetTextColor(1, 1, 1)
frame.text:SetJustifyH("CENTER")

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(StealthIndicator.db.point.point, StealthIndicator.db.point.x, StealthIndicator.db.point.y)
        end

        self.text:SetText(StealthIndicator.db.displayText)
        self.text:SetTextColor(StealthIndicator.db.color.r, StealthIndicator.db.color.g, StealthIndicator.db.color.b, StealthIndicator.db.color.a)
        self.text:SetFont(LSM:Fetch("font", StealthIndicator.db.font.fontFamily), StealthIndicator.db.font.fontSize, StealthIndicator.db.font.fontOutline)
        self.text:SetShadowColor(StealthIndicator.db.font.fontShadowColor.r, StealthIndicator.db.font.fontShadowColor.g, StealthIndicator.db.font.fontShadowColor.b, StealthIndicator.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(StealthIndicator.db.font.fontShadowXOffset, StealthIndicator.db.font.fontShadowYOffset)

        self:SetSize(frame.text:GetStringWidth(), frame.text:GetStringHeight())
    end
end

local function OnEvent(self, ...)
    self:UpdateStyles()

    if ItruliaQoL.testMode then
        self.text:Show()
        return
    end

    if IsStealthed() then
        self.text:Show()
    else
        self.text:Hide()
    end
end

frame:RegisterEvent("UPDATE_STEALTH")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local defaults = {
    enabled = false,
    displayText = "+Stealth",
    color = {r = 1, g = 1, b = 1, a = 1},
    point = {point = "CENTER", x = 0, y = 50},

    font = {
        fontFamily = "Expressway",
        fontSize = 14,
        fontOutline = "OUTLINE",
        fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
        fontShadowXOffset = 1,
        fontShadowYOffset = -1,
    }
};

function StealthIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.StealthIndicator = profile.StealthIndicator or defaults
    self.db = profile.StealthIndicator
end

function StealthIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.StealthIndicator = profile.StealthIndicator or defaults
    self.db = profile.StealthIndicator

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function StealthIndicator:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    frame:UpdateStyles()
end

function StealthIndicator:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil, nil, nil, nil, nil)
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, defaults.point)
    end
end

function StealthIndicator:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end


local options = {
    order = 2,
    type = "group",
    name = "Stealth Indicator",
    args = {
        description = {
            type = "description",
            name = "Shows an indicator text when stealthed (not invisible) \n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function()
                return StealthIndicator.db.enabled
            end,
            set = function(_, value)
                StealthIndicator.db.enabled = value

                StealthIndicator:RefreshConfig()
                if value then
                    OnEvent(frame)
                end
            end
        },
        displaySettings = {
            type = "group",
            name = "",
            order = 4,
            inline = true,
            args = {
                displayText = {
                    order = 1,
                    type = "input",
                    name = "Display text",
                    get = function()
                        return StealthIndicator.db.displayText
                    end,
                    set = function(_, value)
                        StealthIndicator.db.displayText = value
                        frame:UpdateStyles()
                    end
                },
                color = {
                    order = 2,
                    type = "color",
                    name = "Color",
                    hasAlpha = true,
                    get = function()
                        local c = StealthIndicator.db.color
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        StealthIndicator.db.color = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        frame:UpdateStyles()
                    end
                },
            }
        },
        fontSettings = {
            type = "group",
            name = "",
            order = 5,
            inline = true,
            args = {
                font = {
                    order = 1,
                    type = "select",
                    dialogControl = "LSM30_Font",
                    name = "Font",
                    values = LSM:HashTable("font"),
                    get = function()
                        return StealthIndicator.db.font.fontFamily
                    end,
                    set = function(_, value)
                        StealthIndicator.db.font.fontFamily = value
                        frame:UpdateStyles()
                    end
                },
                fontSize = {
                    order = 2,
                    type = "range",
                    name = "Size",
                    min = 1,
                    max = 68,
                    step = 1,
                    get = function()
                        return StealthIndicator.db.font.fontSize
                    end,
                    set = function(_, value)
                        StealthIndicator.db.font.fontSize = value
                        frame:UpdateStyles()
                    end
                },
                fontOutline = {
                    order = 3,
                    type = "select",
                    name = "Outline",
                    values = {
                        NONE = "None",
                        OUTLINE = "Outline",
                        THICKOUTLINE = "Thick Outline",
                        MONOCHROME = "Monochrome"
                    },
                    get = function()
                        return StealthIndicator.db.font.fontOutline
                    end,
                    set = function(_, value)
                        StealthIndicator.db.font.fontOutline = value ~= "NONE" and value or nil
                        frame:UpdateStyles()
                    end
                },
                fontShadowColor = {
                    order = 4,
                    type = "color",
                    name = "Shadow Color",
                    hasAlpha = true,
                    get = function()
                        local c = StealthIndicator.db.font.fontShadowColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        StealthIndicator.db.font.fontShadowColor = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        frame:UpdateStyles()
                    end
                },
                fontShadowXOffset = {
                    order = 5,
                    type = "range",
                    name = "Shadow X Offset",
                    min = -5,
                    max = 5,
                    step = 1,
                    get = function()
                        return StealthIndicator.db.font.fontShadowXOffset
                    end,
                    set = function(_, value)
                        StealthIndicator.db.font.fontShadowXOffset = value
                        frame:UpdateStyles()
                    end
                },
                fontShadowYOffset = {
                    order = 5,
                    type = "range",
                    name = "Shadow Y Offset",
                    min = -5,
                    max = 5,
                    step = 1,
                    get = function()
                        return StealthIndicator.db.font.fontShadowYOffset
                    end,
                    set = function(_, value)
                        StealthIndicator.db.font.fontShadowYOffset = value
                        frame:UpdateStyles()
                    end
                },
            }
        },
    }
}

function StealthIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = options;
end