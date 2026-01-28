local addonName, ItruliaQoL = ...
local moduleName = "CombatAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E
local C = ItruliaQoL.C
local CD = ItruliaQoL.CD

local CombatAlert = ItruliaQoL:NewModule(moduleName)

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
frame.alpha:SetStartDelay(1.5)

function frame:UpdateStyles()
    if not E then
        self:ClearAllPoints()
        self:SetPoint(CombatAlert.db.point.point, CombatAlert.db.point.x, CombatAlert.db.point.y)
    end

    self.text:SetFont(LSM:Fetch("font", CombatAlert.db.font), CombatAlert.db.fontSize, CombatAlert.db.fontOutline)
    self:SetSize(frame.text:GetStringWidth(), frame.text:GetStringHeight())
end

local function OnEvent(self, event, ...)
    if ItruliaQoL.testMode then
        self.text:SetText(CombatAlert.db.combatStartsText)
        self.text:SetTextColor(CombatAlert.db.combatEndsColor.r, CombatAlert.db.combatEndsColor.g, CombatAlert.db.combatEndsColor.b, CombatAlert.db.combatEndsColor.a)
        self.text:SetAlpha(1)

        return self:UpdateStyles()
    else 
        self.text:SetText("")
    end

    if event == "PLAYER_REGEN_ENABLED" then
        self.text:SetText(CombatAlert.db.combatEndsText)
        self.text:SetTextColor(CombatAlert.db.combatEndsColor.r, CombatAlert.db.combatEndsColor.g, CombatAlert.db.combatEndsColor.b, CombatAlert.db.combatEndsColor.a)
        self.text:SetAlpha(1)
        self.text.anim:Stop()
        self.text.anim:Play()
    elseif event == "PLAYER_REGEN_DISABLED" then
        self.text:SetText(CombatAlert.db.combatStartsText)
        self.text:SetTextColor(CombatAlert.db.combatStartsColor.r, CombatAlert.db.combatStartsColor.g, CombatAlert.db.combatStartsColor.b, CombatAlert.db.combatStartsColor.a)
        self.text:SetAlpha(1)
        self.text.anim:Stop()
        self.text.anim:Play()
    end

    self:UpdateStyles()
end

frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

local defaults = {
    enabled = true,
    combatStartsText = "+Combat",
    combatStartsColor = {r = 0.9803922176361084, g = 1, b = 0, a = 1},
    combatEndsText = "-Combat",
    combatEndsColor = {r = 0.5333333611488342, g = 1, b = 0, a = 1},
    font = "Expressway",
    fontSize = 14,
    fontOutline = "OUTLINE",
    point = {point = "CENTER", x = 0, y = 0},
};

function CombatAlert:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.CombatAlert = profile.CombatAlert or defaults
    self.db = profile.CombatAlert
end

function CombatAlert:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.CombatAlert = profile.CombatAlert or defaults
    self.db = profile.CombatAlert

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function CombatAlert:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil, nil, nil, nil, nil)
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, {point = "CENTER", x = 0, y = 0})
    end
end

function CombatAlert:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end


local options = {
    type = "group",
    name = "Combat Alert",
    order = 2,
    args = {
        enable = {
            order = 1,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function(info)
                return CombatAlert.db.enabled
            end,
            set = function(info, value)
                CombatAlert.db.enabled = value

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
                combatStartsText = {
                    order = 1,
                    type = "input",
                    name = "Combat starts text",
                    get = function()
                        return CombatAlert.db.combatStartsText
                    end,
                    set = function(_, value)
                        CombatAlert.db.combatStartsText = value
                        frame:UpdateStyles()
                    end
                },
                combatStartsColor = {
                    order = 2,
                    type = "color",
                    name = "Combat starts color",
                    hasAlpha = true,
                    get = function()
                        local c = CombatAlert.db.combatStartsColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        CombatAlert.db.combatStartsColor = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        frame:UpdateStyles()
                    end
                },
                spacer = {
                    type = "description",
                    name = "",
                    width = "full",
                    order = 3,
                },
                combatEndsText = {
                    order = 3,
                    type = "input",
                    name = "Combat ends text",
                    get = function()
                        return CombatAlert.db.combatEndsText
                    end,
                    set = function(_, value)
                        CombatAlert.db.combatEndsText = value
                        frame:UpdateStyles()
                    end
                },
                combatEndsColor = {
                    order = 4,
                    type = "color",
                    name = "Combat ends color",
                    hasAlpha = true,
                    get = function()
                        local c = CombatAlert.db.combatEndsColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        CombatAlert.db.combatEndsColor = {
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
                        return CombatAlert.db.font
                    end,
                    set = function(_, value)
                        CombatAlert.db.font = value
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
                        return CombatAlert.db.fontSize
                    end,
                    set = function(_, value)
                        CombatAlert.db.fontSize = value
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
                        return CombatAlert.db.fontOutline
                    end,
                    set = function(_, value)
                        CombatAlert.db.fontOutline = value ~= "NONE" and value or "OUTLINE"
                        frame:UpdateStyles()
                    end
                }
            }
        },
    }
}

function CombatAlert:RegisterOptions(parentCategory)
    if E then
        E.Options.args[addonName].args[moduleName] = options
    end

    C:RegisterOptionsTable(moduleName, options)

    if not E then
        CD:AddToBlizOptions(moduleName, "Combat Alert", parentCategory)
    end
end