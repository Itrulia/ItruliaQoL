local addonName, ItruliaQoL = ...
local moduleName = "HealerManaIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local HealerManaIndicator = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 50)
frame:SetSize(150, 28)

frame.texts = {}

function frame:IsHealer(unit)
    return UnitExists(unit) and UnitIsConnected(unit) and (UnitGroupRolesAssigned(unit) == "HEALER" or UnitName(unit) == "Shambun")
end

function frame:UpdateTextStyle(text)
    if not text then
        return
    end

    if not text:HasAnySecretAspect() then
        text:SetJustifyH(HealerManaIndicator.db.font.justifyH or "LEFT")
        text:SetFont(LSM:Fetch("font", HealerManaIndicator.db.font.fontFamily), HealerManaIndicator.db.font.fontSize, HealerManaIndicator.db.font.fontOutline)
        text:SetTextColor(HealerManaIndicator.db.color.r, HealerManaIndicator.db.color.g, HealerManaIndicator.db.color.b, HealerManaIndicator.db.color.a)
        text:SetShadowColor(HealerManaIndicator.db.font.fontShadowColor.r, HealerManaIndicator.db.font.fontShadowColor.g, HealerManaIndicator.db.font.fontShadowColor.b, HealerManaIndicator.db.font.fontShadowColor.a)
        text:SetShadowOffset(HealerManaIndicator.db.font.fontShadowXOffset, HealerManaIndicator.db.font.fontShadowYOffset)
    end
end

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() then        
        if not E then
            self:ClearAllPoints()
            self:SetPoint(HealerManaIndicator.db.point.point, HealerManaIndicator.db.point.x, HealerManaIndicator.db.point.y)
        end

        self:SetFrameStrata(HealerManaIndicator.db.font.frameStrata or "BACKGROUND")
        self:SetFrameLevel(HealerManaIndicator.db.font.frameLevel or 1)

        for index, text in ipairs(self.texts) do
            self:UpdateTextStyle(text)

            text:ClearAllPoints()
            if index == 1 then
                text:SetPoint("TOPLEFT", self, 0, 0)
            else
                if HealerManaIndicator.db.growUpwards then
                    text:SetPoint("BOTTOMLEFT", self.texts[index - 1], "TOPLEFT", 0, 4)
                else
                    text:SetPoint("TOPLEFT", self.texts[index - 1], "BOTTOMLEFT", 0, -4)
                end
            end
        end

        self:SetHeight(HealerManaIndicator.db.font.fontSize)
    end
end

function frame:GetOrCreateText(index)
    if not self.texts[index] then
        local text = self:CreateFontString(nil, "OVERLAY")
        self:UpdateTextStyle(text)
        text:SetText(" ")
        text:SetJustifyH("LEFT")
        text:Hide()

        if index == 1 then
            text:SetPoint("TOPLEFT", self, 0, 0)
        else
            if HealerManaIndicator.db.growUpwards then
                text:SetPoint("BOTTOMLEFT", self.texts[index - 1], "TOPLEFT", 0, 4)
            else
                text:SetPoint("TOPLEFT", self.texts[index - 1], "BOTTOMLEFT", 0, -4)
            end
        end

        self.texts[index] = text
    end

    return self.texts[index]
end

function frame:ClearTexts()
    for _, text in ipairs(self.texts) do
        text:SetText(" ")
        text:Hide()
    end
end

function frame:UpdateManaText(index, unit, overrideMana)
    local percent = overrideMana or UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
    local name = UnitName(unit)
    local _, class = UnitClass(unit)
    local classColor = C_ClassColor.GetClassColor(class)
    local nameText = classColor:WrapTextInColorCode(name)

    local text = self:GetOrCreateText(index)
    text:SetText(string.format("%d%% - %s", percent, nameText))
    text:Show()
end

function frame:UpdateManaTexts()
    self:ClearTexts()
    local index = 1

    if not ItruliaQoL:InRaid() and not ItruliaQoL:InDungeon() then
        return
    end

    if ItruliaQoL:InRaid() and not HealerManaIndicator.db.enableInRaids then
        return
    elseif ItruliaQoL:InDungeon() and not HealerManaIndicator.db.enableInDungeons then
        return
    end

    for _, unit in ipairs(ItruliaQoL:GetGroupUnits()) do
        if self:IsHealer(unit) then
            self:UpdateManaText(index, unit)

            index = index + 1
        end
    end
end

local function OnEvent(self, event, ...)
    if ItruliaQoL.testMode then
        self:ClearTexts()
        self:UpdateManaText(1, "player", 69)
        self:UpdateManaText(2, "player", 50)
    else
        self:UpdateManaTexts()
    end

    self:UpdateStyles()
end

frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:RegisterEvent("UNIT_DISPLAYPOWER")
frame:RegisterEvent("UNIT_MAXPOWER")

function HealerManaIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.HealerManaIndicator = profile.HealerManaIndicator or self:GetDefaults()
    self.db = profile.HealerManaIndicator
end

function HealerManaIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.HealerManaIndicator = profile.HealerManaIndicator or self:GetDefaults()
    self.db = profile.HealerManaIndicator

    frame:ClearTexts()

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function HealerManaIndicator:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    self.db.font.justifyH = font.justifyH
    frame:UpdateStyles()
end

function HealerManaIndicator:OnEnable()
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

function HealerManaIndicator:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end


function HealerManaIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        OnEvent(frame)
    end)
end