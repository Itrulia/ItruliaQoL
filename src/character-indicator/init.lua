local addonName, ItruliaQoL = ...
local moduleName = "CharacterIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local CharacterIndicator = ItruliaQoL:NewModule(moduleName)


local function OnEvent(self, ...)
    if ItruliaQoL.testMode or PlayerIsInCombat() then
        self.text:Show()
    else
        self.text:Hide()
    end
end


function CharacterIndicator:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)
    f:SetPoint("CENTER", 0, 0)
    f:SetSize(28, 28)

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("CENTER")
    f.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
    f.text:SetText("+")
    f.text:SetTextColor(1, 0, 0)
    f.text:SetJustifyH("CENTER")
    f.text:Hide()

    function f:UpdateStyles()
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
            if CharacterIndicator.db.font.fontOutline ~= "OUTLINESLUG" then
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

    return f
end

function CharacterIndicator:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")

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

function CharacterIndicator:ApplyFontSettings(font)
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

function CharacterIndicator:OnEnable()
    self:RefreshConfig()
end

function CharacterIndicator:ToggleTestMode()
    if not self.db.enabled or not self.frame then
        return
    end

    OnEvent(self.frame)
end

function CharacterIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
        end

        ItruliaQoL:RefreshPreview(self)
    end)
end
