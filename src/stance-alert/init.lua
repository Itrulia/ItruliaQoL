local addonName, ItruliaQoL = ...
local moduleName = "StanceAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local StanceAlert = ItruliaQoL:NewModule(moduleName)

local defensiveStances = {[71] = true, [386208] = true}

local catFormId = 1
local bearFormId = 5
local moonkinFormId = 31

StanceAlert.DruidForms = {
    [102] = {form = moonkinFormId, spell = 24858},
    [103] = {form = catFormId, spell = 768},
    [104] = {form = bearFormId, spell = 5487},
}


StanceAlert.StanceCheckers = {
    WARRIOR = function()
        if 1 >= GetNumShapeshiftForms() then
            return false
        end

        local active = ItruliaQoL:GetActiveStanceSpell()

        return active ~= nil and defensiveStances[active] == true
    end,

    DRUID = function(specID)
        local expected = StanceAlert.DruidForms[specID]

        if not expected then
            return false
        end

        if not UnitAffectingCombat("player") then
            return false
        end

        if expected.spell and not ItruliaQoL:IsSpellKnown(expected.spell) then
            return false
        end

        return GetShapeshiftFormID() ~= expected.form
    end,
}

function StanceAlert:IsWrongStance()
    local checker = StanceAlert.StanceCheckers[ItruliaQoL.PlayerClass]

    if not checker then
        return false
    end

    if IsMounted() or UnitInVehicle("player") or UnitIsDeadOrGhost("player") then
        return false
    end

    local specId = select(1, GetSpecializationInfo(GetSpecialization()))

    return checker(specId)
end

local function OnEvent(self)
    if ItruliaQoL.testMode then
        self.text:Show()

        return
    end

    if StanceAlert:IsWrongStance() then
        self.text:Show()
    else
        self.text:Hide()
    end
end

function StanceAlert:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)
    f:SetPoint("CENTER", 0, 50)
    f:SetSize(28, 28)

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("CENTER")
    f.text:SetFont(LSM:Fetch("font", "Expressway"), 14, "OUTLINE")
    f.text:SetTextColor(1, 1, 1)
    f.text:SetJustifyH("CENTER")
    f.text:Hide()

    function f:UpdateStyles()
        if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
            if not E then
                self:ClearAllPoints()
                self:SetPoint(StanceAlert.db.point.point, StanceAlert.db.point.x, StanceAlert.db.point.y)
            end

            self:SetFrameStrata(StanceAlert.db.font.frameStrata or "BACKGROUND")
            self:SetFrameLevel(StanceAlert.db.font.frameLevel or 1)
            self.text:ClearAllPoints()
            self.text:SetPoint(StanceAlert.db.font.justifyH or "CENTER")
            self.text:SetJustifyH(StanceAlert.db.font.justifyH or "CENTER")
            self.text:SetText(StanceAlert.db.displayText)
            self.text:SetTextColor(StanceAlert.db.color.r, StanceAlert.db.color.g, StanceAlert.db.color.b, StanceAlert.db.color.a)

            if StanceAlert.db.font.fontOutline ~= "OUTLINESLUG" then
                self.text:SetShadowColor(StanceAlert.db.font.fontShadowColor.r, StanceAlert.db.font.fontShadowColor.g, StanceAlert.db.font.fontShadowColor.b, StanceAlert.db.font.fontShadowColor.a)
                self.text:SetShadowOffset(StanceAlert.db.font.fontShadowXOffset, StanceAlert.db.font.fontShadowYOffset)
            else
                self.text:SetShadowColor(0, 0, 0, 0)
                self.text:SetShadowOffset(0, 0)
            end
            self.text:SetFont(LSM:Fetch("font", StanceAlert.db.font.fontFamily), StanceAlert.db.font.fontSize, StanceAlert.db.font.fontOutline)

            self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
        end
    end

    return f
end

function StanceAlert:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    if StanceAlert.StanceCheckers[ItruliaQoL.PlayerClass] then
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        f:RegisterEvent("PLAYER_TALENT_UPDATE")
        f:RegisterEvent("TRAIT_CONFIG_UPDATED")
        f:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
        f:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
        f:RegisterEvent("PLAYER_REGEN_DISABLED")
        f:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
        f:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
        f:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    end

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

function StanceAlert:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.StanceAlert = profile.StanceAlert or self:GetDefaults()
    self.db = profile.StanceAlert
end

function StanceAlert:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.StanceAlert = profile.StanceAlert or self:GetDefaults()
    self.db = profile.StanceAlert

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

function StanceAlert:ApplyFontSettings(font)
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

function StanceAlert:OnEnable()
    self:RefreshConfig()
end

function StanceAlert:ToggleTestMode()
    if not self.db.enabled or not self.frame then
        return
    end

    OnEvent(self.frame)
end

function StanceAlert:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
        end

        ItruliaQoL:RefreshPreview(self)
    end)
end
