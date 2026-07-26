local addonName, ItruliaQoL = ...
local moduleName = "NoTargetIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local NoTargetIndicator = ItruliaQoL:NewModule(moduleName)

local function OnEvent(self, ...)
    self.text:Hide()

    if ItruliaQoL.testMode then
        self.text:Show()
        return
    end

    if not PlayerIsInCombat() then
        return
    end

    if UnitIsDeadOrGhost("target") then
        self.text:Show()
        return
    end

    if not UnitExists("target") then
        self.text:Show()
        return
    end

    if not UnitCanAttack("player", "target") and not NoTargetIndicator.db.friendlyisValidTarget then
        self.text:Show()
        return
    end
end

function NoTargetIndicator:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)
    f:SetPoint("CENTER", 0, 50)
    f:SetSize(28, 28)

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("CENTER")
    f.text:SetFont(LSM:Fetch("font", "Expressway"), 14, "OUTLINE")
    f.text:SetTextColor(1, 1, 1)
    f.text:SetJustifyH("CENTER")

    function f:UpdateStyles()
        if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
            if not E then
                self:ClearAllPoints()
                self:SetPoint(NoTargetIndicator.db.point.point, NoTargetIndicator.db.point.x, NoTargetIndicator.db.point.y)
            end

            self:SetFrameStrata(NoTargetIndicator.db.font.frameStrata or "BACKGROUND")
            self:SetFrameLevel(NoTargetIndicator.db.font.frameLevel or 1)
            self.text:ClearAllPoints()
            self.text:SetPoint(NoTargetIndicator.db.font.justifyH or "CENTER")
            self.text:SetJustifyH(NoTargetIndicator.db.font.justifyH or "CENTER")
            self.text:SetText(NoTargetIndicator.db.displayText)
            self.text:SetTextColor(NoTargetIndicator.db.color.r, NoTargetIndicator.db.color.g, NoTargetIndicator.db.color.b, NoTargetIndicator.db.color.a)
            if NoTargetIndicator.db.font.fontOutline ~= "OUTLINESLUG" then
                self.text:SetShadowColor(NoTargetIndicator.db.font.fontShadowColor.r, NoTargetIndicator.db.font.fontShadowColor.g, NoTargetIndicator.db.font.fontShadowColor.b, NoTargetIndicator.db.font.fontShadowColor.a)
                self.text:SetShadowOffset(NoTargetIndicator.db.font.fontShadowXOffset, NoTargetIndicator.db.font.fontShadowYOffset)
            else
                self.text:SetShadowColor(0, 0, 0, 0)
                self.text:SetShadowOffset(0, 0)
            end
            self.text:SetFont(LSM:Fetch("font", NoTargetIndicator.db.font.fontFamily), NoTargetIndicator.db.font.fontSize, NoTargetIndicator.db.font.fontOutline)

            -- `self`, not the module's live frame: a preview instance must size itself.
            self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
        end
    end

    return f
end

function NoTargetIndicator:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UNIT_DIED")

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
        local f = self:EnsureFrame()

        f:UpdateStyles()
        f:SetScript("OnEvent", OnEvent)
        OnEvent(f)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
        self.frame:SetScript("OnUpdate", nil)
        self.frame.text:Hide()
    end
end

function NoTargetIndicator:ApplyFontSettings(font)
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

function NoTargetIndicator:OnEnable()
    self:RefreshConfig()
end

function NoTargetIndicator:ToggleTestMode()
    if not self.db.enabled or not self.frame then
        return
    end

    OnEvent(self.frame)
end

function NoTargetIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
        end
    end)
end
