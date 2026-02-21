local addonName, ItruliaQoL = ...
local moduleName = "NoTargetIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local NoTargetIndicator = ItruliaQoL:NewModule(moduleName)

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
            self:SetPoint(NoTargetIndicator.db.point.point, NoTargetIndicator.db.point.x, NoTargetIndicator.db.point.y)
        end

        self:SetFrameStrata(NoTargetIndicator.db.font.frameStrata or "BACKGROUND")
        self:SetFrameLevel(NoTargetIndicator.db.font.frameLevel or 1)
        self.text:SetJustifyH(NoTargetIndicator.db.font.justifyH or "CENTER")
        self.text:SetText(NoTargetIndicator.db.displayText)
        self.text:SetTextColor(NoTargetIndicator.db.color.r, NoTargetIndicator.db.color.g, NoTargetIndicator.db.color.b, NoTargetIndicator.db.color.a)
        self.text:SetFont(LSM:Fetch("font", NoTargetIndicator.db.font.fontFamily), NoTargetIndicator.db.font.fontSize, NoTargetIndicator.db.font.fontOutline)
        self.text:SetShadowColor(NoTargetIndicator.db.font.fontShadowColor.r, NoTargetIndicator.db.font.fontShadowColor.g, NoTargetIndicator.db.font.fontShadowColor.b, NoTargetIndicator.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(NoTargetIndicator.db.font.fontShadowXOffset, NoTargetIndicator.db.font.fontShadowYOffset)

        self:SetSize(frame.text:GetStringWidth(), frame.text:GetStringHeight())
    end
end

local function OnEvent(self, ...)
    self:UpdateStyles()

    if ItruliaQoL.testMode then
        self.text:Show()
        return
    end

    if UnitAffectingCombat("player") and not UnitExists("target") and not UnitIsDead("target") then
        self.text:Show()
    else
        self.text:Hide()
    end
end

frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_DIED")

function NoTargetIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.NoTargetIndicator = profile.NoTargetIndicator or self:GetDefaults()
    self.db = profile.NoTargetIndicator
end

function NoTargetIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.NoTargetIndicator = profile.NoTargetIndicator or self:GetDefaults()
    self.db = profile.NoTargetIndicator

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function NoTargetIndicator:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    self.db.font.justifyH = font.justifyH
    frame:UpdateStyles()
end

function NoTargetIndicator:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil,
            nil,
            nil,
            "ALL,ITRULIA",
            function()
                return self.db.enabled
            end,
            addonName .. "," .. moduleName
        )
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end
end

function NoTargetIndicator:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function NoTargetIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end)
end