local addonName, ItruliaQoL = ...
local moduleName = "HealerManaIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local HealerManaIndicator = ItruliaQoL:NewModule(moduleName)

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

function HealerManaIndicator:GenerateFrame(frameName, parent)
    local f = CreateFrame("frame", frameName, parent or UIParent)
    f:SetPoint("CENTER", 0, 50)
    f:SetSize(150, 28)

    f.texts = {}

    function f:IsHealer(unit)
        return UnitExists(unit)
            and UnitIsConnected(unit)
            and (
                UnitGroupRolesAssigned(unit) == "HEALER"
                or UnitName(unit) == "Shambun"
            )
    end

    function f:UpdateTextStyle(text)
        if not text then
            return
        end

        if not text:HasAnySecretAspect() then
            text:SetJustifyH(HealerManaIndicator.db.font.justifyH or "LEFT")
            if HealerManaIndicator.db.font.fontOutline ~= "OUTLINESLUG" then
                text:SetShadowColor(HealerManaIndicator.db.font.fontShadowColor.r, HealerManaIndicator.db.font.fontShadowColor.g, HealerManaIndicator.db.font.fontShadowColor.b, HealerManaIndicator.db.font.fontShadowColor.a)
                text:SetShadowOffset(HealerManaIndicator.db.font.fontShadowXOffset, HealerManaIndicator.db.font.fontShadowYOffset)
            else
                text:SetShadowColor(0, 0, 0, 0)
                text:SetShadowOffset(0, 0)
            end
            text:SetFont(LSM:Fetch("font", HealerManaIndicator.db.font.fontFamily), HealerManaIndicator.db.font.fontSize, HealerManaIndicator.db.font.fontOutline)
            text:SetTextColor(HealerManaIndicator.db.color.r, HealerManaIndicator.db.color.g, HealerManaIndicator.db.color.b, HealerManaIndicator.db.color.a)
        end
    end

    function f:UpdateStyles()
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
                local point = "LEFT"
                if HealerManaIndicator.db.font.justifyH == "CENTER" then
                    point = ""
                elseif HealerManaIndicator.db.font.justifyH == "RIGHT" then
                    point = "RIGHT"
                end

                if index == 1 then
                    text:SetPoint("TOP" .. point, self, 0, 0)
                else
                    if HealerManaIndicator.db.growUpwards then
                        text:SetPoint("BOTTOM" .. point, self.texts[index - 1], "TOP" .. point, 0, 4)
                    else
                        text:SetPoint("TOP" .. point, self.texts[index - 1], "BOTTOM" .. point, 0, -4)
                    end
                end
            end

            self:SetHeight(HealerManaIndicator.db.font.fontSize)
        end
    end

    function f:GetOrCreateText(index)
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

    function f:ClearTexts()
        for _, text in ipairs(self.texts) do
            text:SetText(" ")
            text:Hide()
        end
    end

    function f:UpdateManaText(index, unit, overrideMana)
        local percent = overrideMana or UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
        local name = UnitName(unit)
        local _, class = UnitClass(unit)
        local classColor = C_ClassColor.GetClassColor(class)
        local nameText = classColor:WrapTextInColorCode(name)

        local text = self:GetOrCreateText(index)
        text:SetText(string.format("%d%% - %s", percent, nameText))
        text:Show()
    end

    function f:UpdateManaTexts()
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

    return f
end

function HealerManaIndicator:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UNIT_POWER_UPDATE")
    f:RegisterEvent("UNIT_DISPLAYPOWER")
    f:RegisterEvent("UNIT_MAXPOWER")

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

function HealerManaIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.HealerManaIndicator = profile.HealerManaIndicator or self:GetDefaults()
    self.db = profile.HealerManaIndicator
end

function HealerManaIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.HealerManaIndicator = profile.HealerManaIndicator or self:GetDefaults()
    self.db = profile.HealerManaIndicator

    if self.db.enabled then
        local f = self:EnsureFrame()

        f:ClearTexts()
        f:UpdateStyles()
        f:SetScript("OnEvent", OnEvent)
        OnEvent(f)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
        self.frame:SetScript("OnUpdate", nil)
        self.frame:ClearTexts()
    end
end

function HealerManaIndicator:ApplyFontSettings(font)
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

function HealerManaIndicator:OnEnable()
    self:RefreshConfig()
end

function HealerManaIndicator:ToggleTestMode()
    if not self.db.enabled or not self.frame then
        return
    end

    OnEvent(self.frame)
end


function HealerManaIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            OnEvent(self.frame)
        end

        ItruliaQoL:RefreshPreview(self)
    end)
end
