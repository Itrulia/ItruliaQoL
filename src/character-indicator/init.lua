local addonName, ItruliaQoL = ...
local moduleName = "CharacterIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local CharacterIndicator = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 0)
frame:SetSize(28, 28)
frame.meleeSpellId = nil
frame.meleeSpellName = nil

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetText("+")
frame.text:SetTextColor(1, 0, 0)
frame.text:SetJustifyH("CENTER")
frame.text:Hide()

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(CharacterIndicator.db.point.point, CharacterIndicator.db.point.x, CharacterIndicator.db.point.y)
        end

        self:SetFrameStrata(CharacterIndicator.db.font.frameStrata or "BACKGROUND")
        self:SetFrameLevel(CharacterIndicator.db.font.frameLevel or 1)
        self.text:ClearAllPoints()
        self.text:SetPoint(CharacterIndicator.db.font.justifyH or "CENTER")
        self.text:SetJustifyH(CharacterIndicator.db.font.justifyH or "CENTER")
        self.text:SetTextColor(CharacterIndicator.db.color.r, CharacterIndicator.db.color.g, CharacterIndicator.db.color.b, CharacterIndicator.db.color.a)
        self.text:SetText(CharacterIndicator.db.displayText)
        if CharacterIndicator.db.font.fontOutline ~= ItruliaQoL.OutlineSettings.OUTLINESLUG then
            self.text:SetShadowColor(CharacterIndicator.db.font.fontShadowColor.r, CharacterIndicator.db.font.fontShadowColor.g, CharacterIndicator.db.font.fontShadowColor.b, CharacterIndicator.db.font.fontShadowColor.a)
            self.text:SetShadowOffset(CharacterIndicator.db.font.fontShadowXOffset, CharacterIndicator.db.font.fontShadowYOffset)
        else
            self.text:SetShadowColor(0, 0, 0, 0)
            self.text:SetShadowOffset(0, 0)
        end
        self.text:SetFont(LSM:Fetch("font", CharacterIndicator.db.font.fontFamily), CharacterIndicator.db.font.fontSize, CharacterIndicator.db.font.fontOutline)
        self:SetSize(math.max(self.text:GetStringWidth(), 28), math.max(self.text:GetStringHeight(), 28))
    end
end

local function OnEvent(self, ...)
    if ItruliaQoL.testMode or PlayerIsInCombat() then
        self.text:Show()
    else
        self.text:Hide()
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")

function CharacterIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.CharacterIndicator = profile.CharacterIndicator or self:GetDefaults()
    self.db = profile.CharacterIndicator
end

function CharacterIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.CharacterIndicator = profile.CharacterIndicator or self:GetDefaults()
    self.db = profile.CharacterIndicator

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
        OnEvent(frame)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function CharacterIndicator:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    self.db.font.justifyH = font.justifyH
    frame:UpdateStyles()
end

function CharacterIndicator:OnEnable()
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

function CharacterIndicator:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function CharacterIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end)
end
