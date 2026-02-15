local addonName, ItruliaQoL = ...
local moduleName = "CombatAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local CombatAlert = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 0)
frame:SetSize(28, 28)

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetTextColor(1, 1, 1)
frame.text:SetJustifyH("CENTER")

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
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(CombatAlert.db.point.point, CombatAlert.db.point.x, CombatAlert.db.point.y)
        end

        self:SetFrameStrata(CombatAlert.db.frameStrata or "BACKGROUND")
        self:SetFrameLevel(CombatAlert.db.frameLevel or 1)
        self.text:SetFont(LSM:Fetch("font", CombatAlert.db.font.fontFamily), CombatAlert.db.font.fontSize, CombatAlert.db.font.fontOutline)
        self.text:SetShadowColor(CombatAlert.db.font.fontShadowColor.r, CombatAlert.db.font.fontShadowColor.g, CombatAlert.db.font.fontShadowColor.b, CombatAlert.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(CombatAlert.db.font.fontShadowXOffset, CombatAlert.db.font.fontShadowYOffset)

        self:SetSize(frame.text:GetStringWidth(), frame.text:GetStringHeight())
    end
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
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local defaults = {
    enabled = true,
    combatStartsText = "+Combat",
    combatStartsColor = {r = 0.9803922176361084, g = 1, b = 0, a = 1},
    combatEndsText = "-Combat",
    combatEndsColor = {r = 0.5333333611488342, g = 1, b = 0, a = 1},
    point = {point = "CENTER", x = 0, y = 0},

    font = {
        fontFamily = "Expressway",
        fontSize = 14,
        fontOutline = "OUTLINE",
        fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
        fontShadowXOffset = 1,
        fontShadowYOffset = -1,
        frameStrata = ItruliaQoL.FrameStrataSettings.BACKGROUND,
        frameLevel = 1,
    }
};

function CombatAlert:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.CombatAlert = profile.CombatAlert or self:GetDefaults()
    self.db = profile.CombatAlert
end

function CombatAlert:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.CombatAlert = profile.CombatAlert or self:GetDefaults()
    self.db = profile.CombatAlert

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function CombatAlert:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    frame:UpdateStyles()
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
        end, self:GetDefaults().point)
    end
end

function CombatAlert:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function CombatAlert:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end);
end