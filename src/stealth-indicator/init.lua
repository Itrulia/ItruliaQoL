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

        self:SetFrameStrata(StealthIndicator.db.font.frameStrata or "BACKGROUND")
        self:SetFrameLevel(StealthIndicator.db.font.frameLevel or 1)
        self.text:SetJustifyH(StealthIndicator.db.font.justifyH or "CENTER")
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

function StealthIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.StealthIndicator = profile.StealthIndicator or self:GetDefaults()
    self.db = profile.StealthIndicator
end

function StealthIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.StealthIndicator = profile.StealthIndicator or self:GetDefaults()
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
    self.db.font.justifyH = font.justifyH
    frame:UpdateStyles()
end

function StealthIndicator:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil,
            nil,
            nil,
            "ALL,ITRULIA",
            function()
                return self.db.enable
            end,
            addonName .. "," .. moduleName
        )
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end
end

function StealthIndicator:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function StealthIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end)
end