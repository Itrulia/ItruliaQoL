local addonName, ItruliaQoL = ...
local moduleName = "HealerManaIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local HealerManaIndicator = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 50)
frame:SetSize(150, 28)

frame.texts = {}

function frame:IsHealer(unit)
    return UnitExists(unit) and UnitIsConnected(unit) and (UnitGroupRolesAssigned(unit) == "HEALER" or UnitName(unit) == "Shambun")
end

function frame:UpdateTextStyle(text)
    if not text then
        return
    end

    if not text:HasAnySecretAspect() then
        text:SetFont(LSM:Fetch("font", HealerManaIndicator.db.font.fontFamily), HealerManaIndicator.db.font.fontSize, HealerManaIndicator.db.font.fontOutline)
        text:SetTextColor(HealerManaIndicator.db.color.r, HealerManaIndicator.db.color.g, HealerManaIndicator.db.color.b, HealerManaIndicator.db.color.a)
        text:SetShadowColor(HealerManaIndicator.db.font.fontShadowColor.r, HealerManaIndicator.db.font.fontShadowColor.g, HealerManaIndicator.db.font.fontShadowColor.b, HealerManaIndicator.db.font.fontShadowColor.a)
        text:SetShadowOffset(HealerManaIndicator.db.font.fontShadowXOffset, HealerManaIndicator.db.font.fontShadowYOffset)
    end
end

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() then        
        if not E then
            self:ClearAllPoints()
            self:SetPoint(HealerManaIndicator.db.point.point, HealerManaIndicator.db.point.x, HealerManaIndicator.db.point.y)
        end

        for index, text in ipairs(self.texts) do
            self:UpdateTextStyle(text)

            text:ClearAllPoints()
            if index == 1 then
                text:SetPoint("TOPLEFT", self, 0, 0)
            else
                if HealerManaIndicator.db.growUpwards then
                    text:SetPoint("BOTTOMLEFT", self.texts[index - 1], "TOPLEFT", 0, 4)
                else
                    text:SetPoint("TOPLEFT", self.texts[index - 1], "BOTTOMLEFT", 0, -4)
                end
            end
        end

        self:SetHeight(HealerManaIndicator.db.font.fontSize)
    end
end

function frame:GetOrCreateText(index)
    if not self.texts[index] then
        local text = self:CreateFontString(nil, "OVERLAY")
        self:UpdateTextStyle(text)
        text:SetText(" ")
        text:SetJustifyH("LEFT")
        text:Hide()

        if index == 1 then
            text:SetPoint("TOPLEFT", self, 0, 0)
        else
            if HealerManaIndicator.db.growUpwards then
                text:SetPoint("BOTTOMLEFT", self.texts[index - 1], "TOPLEFT", 0, 4)
            else
                text:SetPoint("TOPLEFT", self.texts[index - 1], "BOTTOMLEFT", 0, -4)
            end
        end

        self.texts[index] = text
    end

    return self.texts[index]
end

function frame:ClearTexts()
    for _, text in ipairs(self.texts) do
        text:SetText(" ")
        text:Hide()
    end
end

function frame:UpdateManaText(index, unit, overrideMana)
    local percent = overrideMana or UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
    local name = UnitName(unit)
    local _, class = UnitClass(unit)
    local classColor = C_ClassColor.GetClassColor(class)
    local nameText = classColor:WrapTextInColorCode(name)

    local text = self:GetOrCreateText(index)
    text:SetText(string.format("%d%% - %s", percent, nameText))
    text:Show()
end

function frame:UpdateManaTexts()
    self:ClearTexts()
    local index = 1

    if not ItruliaQoL:InRaid() and not ItruliaQoL:InDungeon() then
        return
    end

    if ItruliaQoL:InRaid() and not HealerManaIndicator.db.enableInRaids then
        return
    elseif ItruliaQoL:InDungeon() and not HealerManaIndicator.db.enableInDungeons then
        return
    end

    for _, unit in ipairs(ItruliaQoL:GetGroupUnits()) do
        if self:IsHealer(unit) then
            self:UpdateManaText(index, unit)

            index = index + 1
        end
    end
end

local function OnEvent(self, event, ...)
    if ItruliaQoL.testMode then
        self:ClearTexts()
        self:UpdateManaText(1, "player", 69)
        self:UpdateManaText(2, "player", 50)
    else
        self:UpdateManaTexts()
    end

    self:UpdateStyles()
end

frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:RegisterEvent("UNIT_DISPLAYPOWER")
frame:RegisterEvent("UNIT_MAXPOWER")

local defaults = {
    enabled = false,
    growUpwards = false,
    color = {r = 1, g = 1, b = 1, a = 1},
    point = {point = "CENTER", x = -100, y = 50},

    enableInRaids = false,
    enableInDungeons = true,

    font = {
        fontFamily = "Expressway",
        fontSize = 14,
        fontOutline = "OUTLINE",
        fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
        fontShadowXOffset = 1,
        fontShadowYOffset = -1,
    }
};

function HealerManaIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.HealerManaIndicator = profile.HealerManaIndicator or defaults
    self.db = profile.HealerManaIndicator
end

function HealerManaIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.HealerManaIndicator = profile.HealerManaIndicator or defaults
    self.db = profile.HealerManaIndicator

    frame:ClearTexts()

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function HealerManaIndicator:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    frame:UpdateStyles()
end

function HealerManaIndicator:OnEnable()
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

function HealerManaIndicator:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end


local options = {
    order = 2,
    type = "group",
    name = "Healer Mana Indicator",
    args = {
        description = {
            type = "description",
            name = "Shows the mana of your healers \n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
            width = 0.4,
            type = "toggle",
            name = "Enable",
            get = function()
                return HealerManaIndicator.db.enabled
            end,
            set = function(_, value)
                HealerManaIndicator.db.enabled = value
                HealerManaIndicator:RefreshConfig()
                if value then
                    OnEvent(frame)
                end
            end
        },
        enableInDungeons = {
            order = 3,
            width = 0.8,
            type = "toggle",
            name = "Enable in dungeons",
            get = function()
                return HealerManaIndicator.db.enableInDungeons
            end,
            set = function(_, value)
                HealerManaIndicator.db.enableInDungeons = value
                OnEvent(frame)
            end,
            disabled = function()
                return not HealerManaIndicator.db.enabled
            end
        },
        enableInRaids = {
            order = 4,
            width = 0.75,
            type = "toggle",
            name = "Enable in raids",
            get = function()
                return HealerManaIndicator.db.enableInRaids
            end,
            set = function(_, value)
                HealerManaIndicator.db.enableInRaids = value
                OnEvent(frame)
            end,
            disabled = function()
                return not HealerManaIndicator.db.enabled
            end
        },
        displaySettings = {
            type = "group",
            name = "",
            order = 5,
            inline = true,
            args = {
                color = {
                    order = 1,
                    type = "color",
                    name = "Color",
                    hasAlpha = true,
                    get = function()
                        local c = HealerManaIndicator.db.color
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        HealerManaIndicator.db.color = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        frame:UpdateStyles()
                    end
                },
                growUpwards = {
                    order = 2,
                    type = "toggle",
                    width = "full",
                    name = "Grow upwards",
                    get = function()
                        return HealerManaIndicator.db.growUpwards
                    end,
                    set = function(_, value)
                        HealerManaIndicator.db.growUpwards = value
                        frame:UpdateStyles()
                    end
                },
            }
        },
        fontSettings = {
            type = "group",
            name = "",
            order = 6,
            inline = true,
            args = {
                font = {
                    order = 1,
                    type = "select",
                    dialogControl = "LSM30_Font",
                    name = "Font",
                    values = LSM:HashTable("font"),
                    get = function()
                        return HealerManaIndicator.db.font.fontFamily
                    end,
                    set = function(_, value)
                        HealerManaIndicator.db.font.fontFamily = value
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
                        return HealerManaIndicator.db.font.fontSize
                    end,
                    set = function(_, value)
                        HealerManaIndicator.db.font.fontSize = value
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
                        return HealerManaIndicator.db.font.fontOutline
                    end,
                    set = function(_, value)
                        HealerManaIndicator.db.font.fontOutline = value ~= "NONE" and value or nil
                        frame:UpdateStyles()
                    end
                },
                fontShadowColor = {
                    order = 4,
                    type = "color",
                    name = "Shadow Color",
                    hasAlpha = true,
                    get = function()
                        local c = HealerManaIndicator.db.font.fontShadowColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        HealerManaIndicator.db.font.fontShadowColor = {
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
                        return HealerManaIndicator.db.font.fontShadowXOffset
                    end,
                    set = function(_, value)
                        HealerManaIndicator.db.font.fontShadowXOffset = value
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
                        return HealerManaIndicator.db.font.fontShadowYOffset
                    end,
                    set = function(_, value)
                        HealerManaIndicator.db.font.fontShadowYOffset = value
                        frame:UpdateStyles()
                    end
                },
            }
        },
    }
}

function HealerManaIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = options;
end