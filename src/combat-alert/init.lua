local addonName, ItruliaQoL = ...
local moduleName = "CombatAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local CombatAlert = ItruliaQoL:NewModule(moduleName)

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

function CombatAlert:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)
    f:SetPoint("CENTER", 0, 0)
    f:SetSize(28, 28)

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("CENTER")
    f.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
    f.text:SetTextColor(1, 1, 1)
    f.text:SetJustifyH("CENTER")

    f.text.anim = f.text:CreateAnimationGroup()
    f.text.anim:SetScript("OnFinished", function()
        f.text:SetText("")
    end)
    f.alpha = f.text.anim:CreateAnimation("Alpha")
    f.alpha:SetFromAlpha(1)
    f.alpha:SetToAlpha(0)
    f.alpha:SetDuration(1)
    f.alpha:SetStartDelay(1.5)

    function f:UpdateStyles()
        if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
            if not E then
                self:ClearAllPoints()
                self:SetPoint(CombatAlert.db.point.point, CombatAlert.db.point.x, CombatAlert.db.point.y)
            end

            self:SetFrameStrata(CombatAlert.db.font.frameStrata or "BACKGROUND")
            self:SetFrameLevel(CombatAlert.db.font.frameLevel or 1)
            self.text:ClearAllPoints()
            self.text:SetPoint(CombatAlert.db.font.justifyH or "CENTER")
            self.text:SetJustifyH(CombatAlert.db.font.justifyH or "CENTER")
            if CombatAlert.db.font.fontOutline ~= "OUTLINESLUG" then
                self.text:SetShadowColor(CombatAlert.db.font.fontShadowColor.r, CombatAlert.db.font.fontShadowColor.g, CombatAlert.db.font.fontShadowColor.b, CombatAlert.db.font.fontShadowColor.a)
                self.text:SetShadowOffset(CombatAlert.db.font.fontShadowXOffset, CombatAlert.db.font.fontShadowYOffset)
            else
                self.text:SetShadowColor(0, 0, 0, 0)
                self.text:SetShadowOffset(0, 0)
            end
            self.text:SetFont(LSM:Fetch("font", CombatAlert.db.font.fontFamily), CombatAlert.db.font.fontSize, CombatAlert.db.font.fontOutline)

            self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
        end
    end

    return f
end

function CombatAlert:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")

    if E then
        E:CreateMover(f, f:GetName() .. "Mover", moduleName, nil,
            nil,
            nil,
            "ALL,ITRULIA",
            function()
                return self.db.enabled
            end,
            addonName .. "," .. moduleName
        )
    elseif ItruliaQoL.EUI then
        ItruliaQoL:CreateEUIMover(self, f, moduleName)
    else
        LEM:AddFrame(f, function(_, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end

    return f
end

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
        local f = self:EnsureFrame()

        f:UpdateStyles()
        f:SetScript("OnEvent", OnEvent)
        OnEvent(f)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
        self.frame:SetScript("OnUpdate", nil)
        self.frame.text.anim:Stop()
        self.frame.text:SetText("")
    end
end

function CombatAlert:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    self.db.font.justifyH = font.justifyH

    if self.frame then
        self.frame:UpdateStyles()
    end
end

function CombatAlert:OnEnable()
    self:RefreshConfig()
end

function CombatAlert:ToggleTestMode()
    if not self.db.enabled or not self.frame then
        return
    end

    OnEvent(self.frame)
end

function CombatAlert:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
        end
    end);
end
