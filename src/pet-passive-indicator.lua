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
    if not E then
        self:ClearAllPoints()
        self:SetPoint(PetPassiveIndicator.db.point.point, PetPassiveIndicator.db.point.x, PetPassiveIndicator.db.point.y)
    end

    self.text:SetText(PetPassiveIndicator.db.customText)
    self.text:SetFont(LSM:Fetch("font", PetPassiveIndicator.db.font), PetPassiveIndicator.db.fontSize, PetPassiveIndicator.db.fontOutline)
    self.text:SetTextColor(PetPassiveIndicator.db.color.r, PetPassiveIndicator.db.color.g, PetPassiveIndicator.db.color.b, PetPassiveIndicator.db.color.a)
    self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
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
frame:RegisterEvent("UNIT_ENTERED_VEHICLE")
frame:RegisterEvent("UNIT_EXITED_VEHICLE")

local defaults = {
    enabled = true,
    customText = "**Pet passive!**",
    color = {r = 1, g = 1, b = 1, a = 1},
    font = "Expressway",
    fontSize = 28,
    fontOutline = "OUTLINE",
    updateInterval = 0.5,
    point = {point = "CENTER", x = 0, y = 300}
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
        enable = {
            order = 1,
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
                customText = {
                    order = 2,
                    type = "input",
                    name = "Display text",
                    desc = "Text to display on the indicator",
                    get = function()
                        return PetPassiveIndicator.db.customText
                    end,
                    set = function(_, value)
                        PetPassiveIndicator.db.customText = value
                        frame:UpdateStyles()
                    end
                },
                color = {
                    order = 2,
                    type = "color",
                    name = "Indicator Color",
                    desc = "Set the color of the indicator",
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
                    desc = "Select the font used by this module",
                    values = LSM:HashTable("font"),
                    get = function()
                        return PetPassiveIndicator.db.font
                    end,
                    set = function(_, value)
                        PetPassiveIndicator.db.font = value
                        frame:UpdateStyles()
                    end
                },
                fontSize = {
                    order = 2,
                    type = "range",
                    name = "Font Size",
                    min = 1,
                    max = 68,
                    step = 1,
                    get = function()
                        return PetPassiveIndicator.db.fontSize
                    end,
                    set = function(_, value)
                        PetPassiveIndicator.db.fontSize = value
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
                        return PetPassiveIndicator.db.fontOutline
                    end,
                    set = function(_, value)
                        PetPassiveIndicator.db.fontOutline = value ~= "NONE" and value or nil
                        frame:UpdateStyles()
                    end
                }
            }
        }
    }
}

function PetPassiveIndicator:RegisterOptions(parentCategory)
    if E then
        E.Options.args[addonName].args[moduleName] = options
    end

    C:RegisterOptionsTable(moduleName, options)

    if not E then
        CD:AddToBlizOptions(moduleName, "Passive Pet", parentCategory)
    end
end