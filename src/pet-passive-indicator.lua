local addonName, ItruliaQoL = ...
local moduleName = "PetPassiveIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E
local C = ItruliaQoL.C
local CD = ItruliaQoL.CD

local PetPassiveIndicator = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 300)
frame:SetSize(28, 28)

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetText("**Pet passive!**")
frame.text:SetTextColor(1, 1, 1)
frame.text:Hide()

function frame:IsPetPassive()
    -- Pet bar might be active while mounted
    if not UnitExists("pet") or not PetHasActionBar() or IsMounted() then 
        return false 
    end

    for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
        local name, _, token, active = GetPetActionInfo(slot)

        if name == "PET_MODE_PASSIVE" and token and active then 
            return true 
        end
    end

    return false
end

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(PetPassiveIndicator.db.point.point, PetPassiveIndicator.db.point.x, PetPassiveIndicator.db.point.y)
        end

        self.text:SetText(PetPassiveIndicator.db.displayText)
        self.text:SetTextColor(PetPassiveIndicator.db.color.r, PetPassiveIndicator.db.color.g, PetPassiveIndicator.db.color.b, PetPassiveIndicator.db.color.a)
        self.text:SetFont(LSM:Fetch("font", PetPassiveIndicator.db.font.fontFamily), PetPassiveIndicator.db.font.fontSize, PetPassiveIndicator.db.font.fontOutline)
        self.text:SetShadowColor(PetPassiveIndicator.db.font.fontShadowColor.r, PetPassiveIndicator.db.font.fontShadowColor.g, PetPassiveIndicator.db.font.fontShadowColor.b, PetPassiveIndicator.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(PetPassiveIndicator.db.font.fontShadowXOffset, PetPassiveIndicator.db.font.fontShadowYOffset)
        
        self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
    end
end

local function OnEvent(self, event, ...)
    self:UpdateStyles()

    if ItruliaQoL.testMode then 
        self.text:Show()
        return
    end

    if self:IsPetPassive() then
        self.text:Show()
    else
        self.text:Hide()
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_PET")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ALIVE")
frame:RegisterEvent("PET_BAR_UPDATE")
frame:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")

local defaults = {
    enabled = true,
    displayText = "**Pet passive!**",
    color = {r = 1, g = 1, b = 1, a = 1},
    updateInterval = 0.5,
    point = {point = "CENTER", x = 0, y = 300},

    font = {
        fontFamily = "Expressway",
        fontSize = 28,
        fontOutline = "OUTLINE",
        fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
        fontShadowXOffset = 1,
        fontShadowYOffset = -1,
    }
}

function PetPassiveIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.PetPassiveIndicator = profile.PetPassiveIndicator or defaults
    self.db = profile.PetPassiveIndicator
end

function PetPassiveIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.PetPassiveIndicator = profile.PetPassiveIndicator or defaults
    self.db = profile.PetPassiveIndicator

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function PetPassiveIndicator:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    frame:UpdateStyles()
end

function PetPassiveIndicator:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil, nil, nil, nil, nil)
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, {point = "CENTER", x = 0, y = 300})
    end
end

function PetPassiveIndicator:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

local options = {
    type = "group",
    name = "Passive Pet",
    order = 5,
    args = {
        description = {
            type = "description",
            name =  "Displays a text when you have a pet and it's set to passive\n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function(info)
                return PetPassiveIndicator.db.enabled
            end,
            set = function(info, value)
                PetPassiveIndicator.db.enabled = value
                PetPassiveIndicator:RefreshConfig()
            end
        },
        displaySettings = {
            type = "group",
            name = "",
            order = 4,
            guiInline = true,
            args = {
                displayText = {
                    order = 2,
                    type = "input",
                    name = "Display text",
                    get = function()
                        return PetPassiveIndicator.db.displayText
                    end,
                    set = function(_, value)
                        PetPassiveIndicator.db.displayText = value
                        frame:UpdateStyles()
                    end
                },
                color = {
                    order = 2,
                    type = "color",
                    name = "Color",
                    hasAlpha = true,
                    get = function()
                        local c = PetPassiveIndicator.db.color
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        PetPassiveIndicator.db.color = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        frame:UpdateStyles()
                    end
                }
            }
        },
        fontSettings = {
            type = "group",
            name = "",
            order = 5,
            guiInline = true,
            args = {
                font = {
                    order = 1,
                    type = "select",
                    dialogControl = "LSM30_Font",
                    name = "Font",
                    values = LSM:HashTable("font"),
                    get = function()
                        return PetPassiveIndicator.db.font.fontFamily
                    end,
                    set = function(_, value)
                        PetPassiveIndicator.db.font.fontFamily = value
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
                        return PetPassiveIndicator.db.font.fontSize
                    end,
                    set = function(_, value)
                        PetPassiveIndicator.db.font.fontSize = value
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
                        return PetPassiveIndicator.db.font.fontOutline
                    end,
                    set = function(_, value)
                        PetPassiveIndicator.db.font.fontOutline = value ~= "NONE" and value or nil
                        frame:UpdateStyles()
                    end
                },
                fontShadowColor = {
                    order = 4,
                    type = "color",
                    name = "Shadow Color",
                    hasAlpha = true,
                    get = function()
                        local c = PetPassiveIndicator.db.font.fontShadowColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        PetPassiveIndicator.db.font.fontShadowColor = {
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
                        return PetPassiveIndicator.db.font.fontShadowXOffset
                    end,
                    set = function(_, value)
                        PetPassiveIndicator.db.font.fontShadowXOffset = value
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
                        return PetPassiveIndicator.db.font.fontShadowYOffset
                    end,
                    set = function(_, value)
                        PetPassiveIndicator.db.font.fontShadowYOffset = value
                        frame:UpdateStyles()
                    end
                },
            }
        }
    }
}

function PetPassiveIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = options;
end