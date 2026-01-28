local addonName, ItruliaQoL = ...
local moduleName = "DeathAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E
local C = ItruliaQoL.C
local CD = ItruliaQoL.CD

local DeathAlert = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 300)
frame:SetSize(28, 28)

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetTextColor(1, 1, 1)

frame.text.anim = frame.text:CreateAnimationGroup()
frame.text.anim:SetScript("OnFinished", function() 
    frame.text:SetText("") 
end)
frame.alpha = frame.text.anim:CreateAnimation("Alpha")
frame.alpha:SetFromAlpha(1)
frame.alpha:SetToAlpha(0)
frame.alpha:SetDuration(1)
frame.alpha:SetStartDelay(4)

function frame:UpdateStyles()
    if not E then
        self:ClearAllPoints()
        self:SetPoint(DeathAlert.db.point.point, DeathAlert.db.point.x, DeathAlert.db.point.y)
    end

    self.text:SetFont(LSM:Fetch("font", DeathAlert.db.font), DeathAlert.db.fontSize, DeathAlert.db.fontOutline)
    self.text:SetTextColor(DeathAlert.db.color.r, DeathAlert.db.color.g, DeathAlert.db.color.b, DeathAlert.db.color.a)
    self.alpha:SetStartDelay(DeathAlert.db.messageDuration)
    self:SetSize(frame.text:GetStringWidth(), frame.text:GetStringHeight())
end

local function OnEvent(self, event, deadGUID, ...)
    if ItruliaQoL.testMode then
        local name = UnitName("player")
        local _, class = UnitClass("player")
        
        local color = C_ClassColor.GetClassColor(class);
        local customText = CreateColor(
            DeathAlert.db.color.r,
            DeathAlert.db.color.g, 
            DeathAlert.db.color.b, 
            DeathAlert.db.color.a
        ):WrapTextInColorCode(DeathAlert.db.customText)
        local nameText = color:WrapTextInColorCode(name)

        self.text:SetText(nameText .. " " .. customText)
        self.text:SetAlpha(1)

        return self:UpdateStyles()
    end

    if event == "UNIT_DIED" then
        local unitId = UnitTokenFromGUID(deadGUID)

        if unitId and (UnitInParty(unitId) or UnitInRaid(unitId) or UnitIsUnit(unitId, "player")) then
            local name = UnitName(unitId)
            local _, class = UnitClass(unitId)
            
            local color = C_ClassColor.GetClassColor(class);
            local customText = CreateColor(
                DeathAlert.db.color.r,
                DeathAlert.db.color.g, 
                DeathAlert.db.color.b, 
                DeathAlert.db.color.a
            ):WrapTextInColorCode(DeathAlert.db.customText)
            local nameText = color:WrapTextInColorCode(name)

            self.text:SetText(nameText .. " " .. customText)
            self.text:SetAlpha(1)
            self.text.anim:Stop()
            self.text.anim:Play()

            if DeathAlert.db.playSound and DeathAlert.db.sound then
                PlaySoundFile(LSM:Fetch("sound", DeathAlert.db.sound), "Master")
            end
        else
            self.text:SetText("")
        end
    else
        self.text:SetText("")
    end

    self:UpdateStyles()
end

frame:RegisterEvent("UNIT_DIED")

local defaults = {
    enabled = true,
    customText = "DIED!",
    color = {r = 1, g = 1, b = 1, a = 1},
    font = "Expressway",
    fontSize = 28,
    fontOutline = "OUTLINE",
    updateInterval = 0.5,
    messageDuration = 2,
    point = {point = "CENTER", x = 0, y = 200},
    playSound = false,
    sound = "Exit"
};

function DeathAlert:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.DeathAlert = profile.DeathAlert or defaults
    self.db = profile.DeathAlert
end

function DeathAlert:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.DeathAlert = profile.DeathAlert or defaults
    self.db = profile.DeathAlert

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function DeathAlert:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil, nil, nil, nil, nil)
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, {point = "CENTER", x = 0, y = 200})
    end
end

function DeathAlert:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end


local options = {
    type = "group",
    name = "Death Alert",
    order = 2,
    args = {
        enable = {
            order = 1,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function(info)
                return DeathAlert.db.enabled
            end,
            set = function(info, value)
                DeathAlert.db.enabled = value

                if value then
                    frame:SetScript("OnEvent", OnEvent)
                    onEvent(frame)
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
            guiInline = true,
            args = {
                customText = {
                    order = 2,
                    type = "input",
                    name = "Display text",
                    desc = "Text to display on the indicator",
                    get = function()
                        return DeathAlert.db.customText
                    end,
                    set = function(_, value)
                        DeathAlert.db.customText = value
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
                        local c = DeathAlert.db.color
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        DeathAlert.db.color = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        frame:UpdateStyles()
                    end
                },
                messageDuration = {
                    order = 3,
                    type = "range",
                    min = 1,
                    max = 10,
                    step = 1,
                    name = "Display duration",
                    desc = "How long should the message be displayed?",
                    get = function()
                        return DeathAlert.db.messageDuration
                    end,
                    set = function(_, value)
                        DeathAlert.db.messageDuration = value
                        frame:UpdateStyles()
                    end
                },
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
                        return DeathAlert.db.font
                    end,
                    set = function(_, value)
                        DeathAlert.db.font = value
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
                        return DeathAlert.db.fontSize
                    end,
                    set = function(_, value)
                        DeathAlert.db.fontSize = value
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
                        return DeathAlert.db.fontOutline
                    end,
                    set = function(_, value)
                        DeathAlert.db.fontOutline = value ~= "NONE" and value or nil
                        frame:UpdateStyles()
                    end
                }
            }
        },
        soundGroup = {
            type = "group",
            name = "",
            order = 6,
            guiInline = true,
            args = {
                playSound = {
                    order = 1,
                    type = "toggle",
                    name = "Play sound",
                    get = function() 
                        return DeathAlert.db.playSound
                    end,
                    set = function(_, value)
                        DeathAlert.db.playSound = value
                    end,
                },
                sound = {
                    order = 2,
                    type = "select",
                    dialogControl = "LSM30_Sound", 
                    name = "Sound",
                    desc = "Select the sound used by this module",
                    values = LSM:HashTable("sound"),
                    get = function()
                        return DeathAlert.db.sound
                    end,
                    set = function(_, value)
                        DeathAlert.db.sound = value
                    end,
                    disabled = function()
                        return not DeathAlert.db.playSound
                    end,
                },
            }
        },
    }
}

function DeathAlert:RegisterOptions(parentCategory)
    if E then
        E.Options.args[addonName].args[moduleName] = options
    end

    C:RegisterOptionsTable(moduleName, options)

    if not E then
        CD:AddToBlizOptions(moduleName, "Death Alert", parentCategory)
    end
end