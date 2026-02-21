local addonName, ItruliaQoL = ...
local moduleName = "CombatTimer"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local CombatTimer = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 0)
frame:SetSize(28, 28)
frame.combatStart = nil

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 14, "OUTLINE")
frame.text:SetTextColor(1, 1, 1)
frame.text:SetJustifyH("CENTER")
-- needs a non empty text to restore frame position
frame.text:SetText(" ")

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(CombatTimer.db.point.point, CombatTimer.db.point.x, CombatTimer.db.point.y)
        end

        self:SetFrameStrata(CombatTimer.db.font.frameStrata or "BACKGROUND")
        self:SetFrameLevel(CombatTimer.db.font.frameLevel or 1)
        self.text:SetJustifyH(CombatTimer.db.font.justifyH or "CENTER")
        self.text:SetTextColor(CombatTimer.db.color.r, CombatTimer.db.color.g, CombatTimer.db.color.b, CombatTimer.db.color.a)
        self.text:SetFont(LSM:Fetch("font", CombatTimer.db.font.fontFamily), CombatTimer.db.font.fontSize, CombatTimer.db.font.fontOutline)
        self.text:SetShadowColor(CombatTimer.db.font.fontShadowColor.r, CombatTimer.db.font.fontShadowColor.g, CombatTimer.db.font.fontShadowColor.b, CombatTimer.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(CombatTimer.db.font.fontShadowXOffset, CombatTimer.db.font.fontShadowYOffset)
        self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
    end
end

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

function frame:FormatTime(seconds)
    local formatter = CombatTimer.timeFormats[CombatTimer.db.timeFormat or "SECONDS"] or CombatTimer.timeFormats.CLOCK

    return formatter.fn(seconds)
end

local function OnUpdate(self)
    if self.combatStart then
        local elapsed = math.max(GetTime() - self.combatStart, 0)
        self.text:SetText(self:FormatTime(elapsed))
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

frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

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
        frame:SetScript("OnEvent", OnEvent)
        frame:SetScript("OnUpdate", OnUpdate)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function CombatTimer:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    self.db.font.justifyH = font.justifyH
    frame:UpdateStyles()
end

function CombatTimer:OnEnable()
    if self.db.enabled then 
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent) 
        frame:SetScript("OnUpdate", OnUpdate)
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

function CombatTimer:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function CombatTimer:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end)
end