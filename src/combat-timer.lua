local addonName, ItruliaQoL = ...
local moduleName = "CombatTimer"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local CombatTimer = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 0)
frame:SetSize(28, 28)
frame.combatStart = nil

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 14, "OUTLINE")
frame.text:SetTextColor(1, 1, 1)
frame.text:SetJustifyH("CENTER")
-- needs a non empty text to restore frame position
frame.text:SetText(" ")

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(CombatTimer.db.point.point, CombatTimer.db.point.x, CombatTimer.db.point.y)
        end

        self.text:SetTextColor(CombatTimer.db.color.r, CombatTimer.db.color.g, CombatTimer.db.color.b, CombatTimer.db.color.a)
        self.text:SetFont(LSM:Fetch("font", CombatTimer.db.font.fontFamily), CombatTimer.db.font.fontSize, CombatTimer.db.font.fontOutline)
        self.text:SetShadowColor(CombatTimer.db.font.fontShadowColor.r, CombatTimer.db.font.fontShadowColor.g, CombatTimer.db.font.fontShadowColor.b, CombatTimer.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(CombatTimer.db.font.fontShadowXOffset, CombatTimer.db.font.fontShadowYOffset)
        self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
    end
end

frame.timeFormats = {
    SECONDS = {
        display = '180',
        fn = function(seconds)
            return string.format("%d", seconds)
        end
    },
    SECONDS_BRACKET = {
        display = '[180]',
        fn = function(seconds)
            return string.format("[%d]", seconds)
        end
    },
    CLOCK = {
        display = '01:23',
        fn = function(seconds)
            return date("%M:%S", seconds)
        end
    },
    CLOCK_BRACKET = {
        display = '[01:23]',
        fn = function(seconds)
            return date("[%M:%S]", seconds)
        end
    },
}

function frame:FormatTime(seconds)
    local formatter = self.timeFormats[CombatTimer.db.timeFormat or "SECONDS"] or self.timeFormats.CLOCK

    return formatter.fn(seconds)
end

local function OnUpdate(self)
    if self.combatStart then
        local elapsed = math.max(GetTime() - self.combatStart, 0)
        frame.text:SetText(self:FormatTime(elapsed))
        frame.text:Show()
    else
        frame.text:Hide()
    end
end

local function OnEvent(self, event, ...)
    self:UpdateStyles()

    if ItruliaQoL.testMode or event == "PLAYER_REGEN_DISABLED" then
        self.combatStart = GetTime()
    else
        self.combatStart = nil
    end
end

frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local defaults = {
    enabled = false,
    color = {r = 1, g = 1, b = 1, a = 1},
    point = {point = "CENTER", x = 0, y = 0},
    timeFormat = "CLOCK",

    font = {
        fontFamily = "Expressway",
        fontSize = 14,
        fontOutline = "OUTLINE",
        fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
        fontShadowXOffset = 1,
        fontShadowYOffset = -1,
    }
};

function CombatTimer:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.CombatTimer = profile.CombatTimer or defaults
    self.db = profile.CombatTimer
end

function CombatTimer:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.CombatTimer = profile.CombatTimer or defaults
    self.db = profile.CombatTimer

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
        frame:SetScript("OnUpdate", OnUpdate)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function CombatTimer:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    frame:UpdateStyles()
end

function CombatTimer:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
        frame:SetScript("OnUpdate", OnUpdate)
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil, nil, nil, nil, nil)
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, {point = "CENTER", x = 0, y = 0})
    end
end

function CombatTimer:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end


local options = {
    order = 2,
    type = "group",
    name = "Combat Timer",
    args = {
        description = {
            type = "description",
            name = "Shows a combat timer \n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function()
                return CombatTimer.db.enabled
            end,
            set = function(_, value)
                CombatTimer.db.enabled = value

                if value then
                    CombatTimer:RefreshConfig()
                    OnEvent(frame)
                else
                    frame:SetScript("OnEvent", nil)
                    frame:SetScript("OnUpdate", nil)
                end
            end
        },
        displaySettings = {
            type = "group",
            name = "",
            order = 4,
            inline = true,
            args = {
                myDropdown = {
                    order = 1,
                    type = "select",
                    name = "Time format",
                    values = {
                        SECONDS = frame.timeFormats.SECONDS.display,
                        SECONDS_BRACKET = frame.timeFormats.SECONDS_BRACKET.display,
                        CLOCK = frame.timeFormats.CLOCK.display,
                        CLOCK_BRACKET = frame.timeFormats.CLOCK_BRACKET.display,
                    },
                    get = function()
                        return CombatTimer.db.timeFormat
                    end,
                    set = function(_, value)
                        CombatTimer.db.timeFormat = value
                        frame:UpdateStyles()
                    end,
                },
                color = {
                    order = 2,
                    type = "color",
                    name = "Combat starts color",
                    hasAlpha = true,
                    get = function()
                        local c = CombatTimer.db.color
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        CombatTimer.db.color = {
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
                        return CombatTimer.db.font.fontFamily
                    end,
                    set = function(_, value)
                        CombatTimer.db.font.fontFamily = value
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
                        return CombatTimer.db.font.fontSize
                    end,
                    set = function(_, value)
                        CombatTimer.db.font.fontSize = value
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
                        return CombatTimer.db.font.fontOutline
                    end,
                    set = function(_, value)
                        CombatTimer.db.font.fontOutline = value ~= "NONE" and value or nil
                        frame:UpdateStyles()
                    end
                },
                fontShadowColor = {
                    order = 4,
                    type = "color",
                    name = "Shadow Color",
                    hasAlpha = true,
                    get = function()
                        local c = CombatTimer.db.font.fontShadowColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        CombatTimer.db.font.fontShadowColor = {
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
                        return CombatTimer.db.font.fontShadowXOffset
                    end,
                    set = function(_, value)
                        CombatTimer.db.font.fontShadowXOffset = value
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
                        return CombatTimer.db.font.fontShadowYOffset
                    end,
                    set = function(_, value)
                        CombatTimer.db.font.fontShadowYOffset = value
                        frame:UpdateStyles()
                    end
                },
            }
        },
    }
}

function CombatTimer:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = options;
end