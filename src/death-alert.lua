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

function frame:UpdateStyles(forceUpdate)
    if not InCombatLockdown() or forceUpdate then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(DeathAlert.db.point.point, DeathAlert.db.point.x, DeathAlert.db.point.y)
        end

        self.text:SetTextColor(DeathAlert.db.color.r, DeathAlert.db.color.g, DeathAlert.db.color.b, DeathAlert.db.color.a)
        self.text:SetFont(LSM:Fetch("font", DeathAlert.db.font.fontFamily), DeathAlert.db.font.fontSize, DeathAlert.db.font.fontOutline)
        self.text:SetShadowColor(DeathAlert.db.font.fontShadowColor.r, DeathAlert.db.font.fontShadowColor.g, DeathAlert.db.font.fontShadowColor.b, DeathAlert.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(DeathAlert.db.font.fontShadowXOffset, DeathAlert.db.font.fontShadowYOffset)
        self.alpha:SetStartDelay(DeathAlert.db.messageDuration)
        self:SetSize(frame.text:GetStringWidth(), frame.text:GetStringHeight())
    end
end

local function OnEvent(self, event, deadGUID, ...)
    if ItruliaQoL.testMode then
        local name = UnitName("player")
        local _, class = UnitClass("player")
        
        local color = C_ClassColor.GetClassColor(class);
        local displayText = CreateColor(
            DeathAlert.db.color.r,
            DeathAlert.db.color.g, 
            DeathAlert.db.color.b, 
            DeathAlert.db.color.a
        ):WrapTextInColorCode(DeathAlert.db.displayText)
        local nameText = color:WrapTextInColorCode(name)

        self.text:SetText(nameText .. " " .. displayText)
        self.text:SetAlpha(1)

        return self:UpdateStyles()
    end

    if event == "UNIT_DIED" then
        if not canaccessvalue(deadGUID) or not canaccessvalue(UnitTokenFromGUID(deadGUID)) then
            return;
        end

        local unitId = UnitTokenFromGUID(deadGUID)

        if unitId and (UnitInParty(unitId) or UnitInRaid(unitId) or unitId == "player") then
            local name = UnitName(unitId)
            local _, class = UnitClass(unitId)
            local classColor = C_ClassColor.GetClassColor(class);

            local displayText = CreateColor(
                DeathAlert.db.color.r,
                DeathAlert.db.color.g, 
                DeathAlert.db.color.b, 
                DeathAlert.db.color.a
            ):WrapTextInColorCode(DeathAlert.db.displayText)
            local nameText = classColor:WrapTextInColorCode(name)

            self.text:SetText(nameText .. " " .. displayText)
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
    displayText = "died",
    color = {r = 1, g = 1, b = 1, a = 1},
    updateInterval = 0.5,
    messageDuration = 2,
    point = {point = "CENTER", x = 0, y = 200},
    playSound = false,
    sound = "Exit",

    font = {
        fontFamily = "Expressway",
        fontSize = 28,
        fontOutline = "OUTLINE",
        fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
        fontShadowXOffset = 1,
        fontShadowYOffset = -1,
    }
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
        description = {
            type = "description",
            name = "Shows an alert when someone in your party or raid dies \n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
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
                displayText = {
                    order = 2,
                    type = "input",
                    name = "Display text",
                    get = function()
                        return DeathAlert.db.displayText
                    end,
                    set = function(_, value)
                        DeathAlert.db.displayText = value
                        frame:UpdateStyles()
                    end
                },
                color = {
                    order = 2,
                    type = "color",
                    name = "Color",
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
                    values = LSM:HashTable("font"),
                    get = function()
                        return DeathAlert.db.font.fontFamily
                    end,
                    set = function(_, value)
                        DeathAlert.db.font.fontFamily = value
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
                        return DeathAlert.db.font.fontSize
                    end,
                    set = function(_, value)
                        DeathAlert.db.font.fontSize = value
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
                        return DeathAlert.db.font.fontOutline
                    end,
                    set = function(_, value)
                        DeathAlert.db.font.fontOutline = value ~= "NONE" and value or nil
                        frame:UpdateStyles()
                    end
                },
                fontShadowColor = {
                    order = 4,
                    type = "color",
                    name = "Shadow Color",
                    hasAlpha = true,
                    get = function()
                        local c = DeathAlert.db.font.fontShadowColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        DeathAlert.db.font.fontShadowColor = {
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
                        return DeathAlert.db.font.fontShadowXOffset
                    end,
                    set = function(_, value)
                        DeathAlert.db.font.fontShadowXOffset = value
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
                        return DeathAlert.db.font.fontShadowYOffset
                    end,
                    set = function(_, value)
                        DeathAlert.db.font.fontShadowYOffset = value
                        frame:UpdateStyles()
                    end
                },
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

function DeathAlert:RegisterOptions(parentCategory, parentOptions)
    if E then
        E.Options.args[addonName].args[moduleName] = options
        C:RegisterOptionsTable(moduleName, options)
    else
        parentOptions.args[moduleName] = options;
        CD:AddToBlizOptions(moduleName, "Death Alert", parentCategory)
    end
end