local addonName, ItruliaQoL = ...
local moduleName = "CombatTimer"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local CombatTimer = ItruliaQoL:NewModule(moduleName)

CombatTimer.timeFormats = {
    SECONDS = {
        display = '180',
        fn = function(seconds)
            return string.format("%d", seconds)
        end
    },
    SECONDS_BRACKET = {
        display = '[180]',
        fn = function(seconds)
            return string.format("[%d]", seconds)
        end
    },
    CLOCK = {
        display = '01:23',
        fn = function(seconds)
            return date("%M:%S", seconds)
        end
    },
    CLOCK_BRACKET = {
        display = '[01:23]',
        fn = function(seconds)
            return date("[%M:%S]", seconds)
        end
    },
}


local function OnUpdate(self)
    if self.combatStart then
        local elapsed = math.max(GetTime() - self.combatStart, 0)
        local text = self:FormatTime(elapsed)
        self.text:SetText(text)
        self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())

        self.text:Show()
    else
        self.text:Hide()
    end
end

local function OnEvent(self, event, ...)
    self:UpdateStyles()

    if ItruliaQoL.testMode or event == "PLAYER_REGEN_DISABLED" then
        self.combatStart = GetTime()
    else
        self.combatStart = nil
    end
end

function CombatTimer:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)
    f:SetPoint("CENTER", 0, 0)
    f:SetSize(28, 28)
    f.combatStart = nil

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("CENTER")
    f.text:SetFont(LSM:Fetch("font", "Expressway"), 14, "OUTLINE")
    f.text:SetTextColor(1, 1, 1)
    f.text:SetJustifyH("CENTER")
    -- needs a non empty text to restore frame position
    f.text:SetText(" ")

    function f:FormatTime(seconds)
        local formatter = CombatTimer.timeFormats[CombatTimer.db.timeFormat or "SECONDS"] or CombatTimer.timeFormats.CLOCK

        return formatter.fn(seconds)
    end

    function f:UpdateStyles()
        if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
            if not E then
                self:ClearAllPoints()
                self:SetPoint(CombatTimer.db.point.point, CombatTimer.db.point.x, CombatTimer.db.point.y)
            end

            self:SetFrameStrata(CombatTimer.db.font.frameStrata or "BACKGROUND")
            self:SetFrameLevel(CombatTimer.db.font.frameLevel or 1)
            self.text:ClearAllPoints()
            self.text:SetPoint(CombatTimer.db.font.justifyH or "CENTER")
            self.text:SetJustifyH(CombatTimer.db.font.justifyH or "CENTER")
            self.text:SetTextColor(CombatTimer.db.color.r, CombatTimer.db.color.g, CombatTimer.db.color.b, CombatTimer.db.color.a)
            if CombatTimer.db.font.fontOutline ~= "OUTLINESLUG" then
                self.text:SetShadowColor(CombatTimer.db.font.fontShadowColor.r, CombatTimer.db.font.fontShadowColor.g, CombatTimer.db.font.fontShadowColor.b, CombatTimer.db.font.fontShadowColor.a)
                self.text:SetShadowOffset(CombatTimer.db.font.fontShadowXOffset, CombatTimer.db.font.fontShadowYOffset)
            else
                self.text:SetShadowColor(0, 0, 0, 0)
                self.text:SetShadowOffset(0, 0)
            end
            self.text:SetFont(LSM:Fetch("font", CombatTimer.db.font.fontFamily), CombatTimer.db.font.fontSize, CombatTimer.db.font.fontOutline)
            self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
        end
    end

    return f
end

function CombatTimer:EnsureFrame()
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

function CombatTimer:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.CombatTimer = profile.CombatTimer or self:GetDefaults()
    self.db = profile.CombatTimer
end

function CombatTimer:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.CombatTimer = profile.CombatTimer or self:GetDefaults()
    self.db = profile.CombatTimer

    if self.db.enabled then
        local f = self:EnsureFrame()

        f:UpdateStyles()
        f:SetScript("OnEvent", OnEvent)
        f:SetScript("OnUpdate", OnUpdate)
        OnEvent(f)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
        self.frame:SetScript("OnUpdate", nil)
        self.frame.text:Hide()
    end
end

function CombatTimer:ApplyFontSettings(font)
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

function CombatTimer:OnEnable()
    self:RefreshConfig()
end

function CombatTimer:ToggleTestMode()
    if not self.db.enabled or not self.frame then
        return
    end

    OnEvent(self.frame)
end

function CombatTimer:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
        end

        ItruliaQoL:RefreshPreview(self)
    end)
end
