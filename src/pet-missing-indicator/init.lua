local addonName, ItruliaQoL = ...
local moduleName = "PetMissingIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local PetMissingIndicator = ItruliaQoL:NewModule(moduleName)

local PET_CLASSES = {
    DEATHKNIGHT = {[250] = false, [251] = false, [252] = true},
    DEMONHUNTER = {[577] = false, [581] = false, [1480] = false},
    DRUID = {[102] = false, [103] = false, [104] = false, [105] = false},
    EVOKER = {[1467] = false, [1468] = false, [1473] = false},
    HUNTER = {[253] = true, [254] = 1223323, [255] = true},
    MAGE = {[62] = false, [63] = false, [64] = 31687},
    MONK = {[268] = false, [269] = false, [270] = false},
    PALADIN = {[65] = false, [66] = false, [70] = false},
    PRIEST = {[256] = false, [257] = false, [258] = false},
    ROGUE = {[259] = false, [260] = false, [261] = false},
    SHAMAN = {[262] = false, [263] = false, [264] = false},
    WARLOCK = {[265] = true, [266] = true, [267] = true},
    WARRIOR = {[71] = false, [72] = false, [73] = false}
}

local function OnEvent(self, event, ...)
    local petSpec = self:IsPetSpec()
    local conditionsWherePetIsntShown = IsMounted() or UnitInVehicle("player") or UnitIsDeadOrGhost("player")

    if ItruliaQoL.testMode then
        self.text:Show()
        return
    end

    if not petSpec or conditionsWherePetIsntShown then
        self.text:Hide()
    else
        if UnitExists("pet") then
            self.text:Hide()
        else
            self.text:Show()
        end
    end
end

function PetMissingIndicator:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)
    f:SetPoint("CENTER", 0, 300)
    f:SetSize(28, 28)

    f.petClasses = PET_CLASSES

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("CENTER")
    f.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
    f.text:SetText("**Pet missing!**")
    f.text:SetTextColor(1, 1, 1)
    f.text:SetJustifyH("CENTER")
    f.text:Hide()

    function f:IsPetSpec()
        local class = select(2, UnitClass("player"))
        local specID = select(1, GetSpecializationInfo(GetSpecialization()))
        local spells = self.petClasses[class]

        if not spells or not specID then
            return nil
        end

        local spellId = spells[specID]

        if spellId == true or not spellId then
            return spellId
        end

        return ItruliaQoL:IsSpellKnown(spellId)
    end

    function f:IsPetPassive()
        if not UnitExists("pet") then
            return false
        end

        if not UnitAffectingCombat("player") then
            return false
        end

        local petTarget = UnitExists("pettarget")

        if not petTarget then
            return true
        end

        return false
    end

    function f:UpdateStyles()
        if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
            if not E then
                self:ClearAllPoints()
                self:SetPoint(PetMissingIndicator.db.point.point, PetMissingIndicator.db.point.x, PetMissingIndicator.db.point.y)
            end

            self:SetFrameStrata(PetMissingIndicator.db.font.frameStrata or "BACKGROUND")
            self:SetFrameLevel(PetMissingIndicator.db.font.frameLevel or 1)
            self.text:ClearAllPoints()
            self.text:SetPoint(PetMissingIndicator.db.font.justifyH or "CENTER")
            self.text:SetJustifyH(PetMissingIndicator.db.font.justifyH or "CENTER")
            self.text:SetText(PetMissingIndicator.db.displayText)
            self.text:SetTextColor(PetMissingIndicator.db.color.r, PetMissingIndicator.db.color.g, PetMissingIndicator.db.color.b, PetMissingIndicator.db.color.a)
            if PetMissingIndicator.db.font.fontOutline ~= "OUTLINESLUG" then
                self.text:SetShadowColor(PetMissingIndicator.db.font.fontShadowColor.r, PetMissingIndicator.db.font.fontShadowColor.g, PetMissingIndicator.db.font.fontShadowColor.b, PetMissingIndicator.db.font.fontShadowColor.a)
                self.text:SetShadowOffset(PetMissingIndicator.db.font.fontShadowXOffset, PetMissingIndicator.db.font.fontShadowYOffset)
            else
                self.text:SetShadowColor(0, 0, 0, 0)
                self.text:SetShadowOffset(0, 0)
            end
            self.text:SetFont(LSM:Fetch("font", PetMissingIndicator.db.font.fontFamily), PetMissingIndicator.db.font.fontSize, PetMissingIndicator.db.font.fontOutline)
            self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
        end
    end

    return f
end

function PetMissingIndicator:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    f:RegisterEvent("PLAYER_TALENT_UPDATE")
    f:RegisterEvent("TRAIT_CONFIG_UPDATED")
    f:RegisterEvent("UNIT_PET")
    f:RegisterEvent("PET_BAR_UPDATE")
    f:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
    f:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    f:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    f:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    f:RegisterEvent("PLAYER_DEAD")
    f:RegisterEvent("PLAYER_ALIVE")

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

function PetMissingIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.PetMissingIndicator = profile.PetMissingIndicator or self:GetDefaults()
    self.db = profile.PetMissingIndicator
end

function PetMissingIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.PetMissingIndicator = profile.PetMissingIndicator or self:GetDefaults()
    self.db = profile.PetMissingIndicator

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

function PetMissingIndicator:ApplyFontSettings(font)
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

function PetMissingIndicator:OnEnable()
    self:RefreshConfig()
end

function PetMissingIndicator:ToggleTestMode()
    if not self.db.enabled or not self.frame then
        return
    end

    OnEvent(self.frame)
end

function PetMissingIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
        end

        ItruliaQoL:RefreshPreview(self)
    end)
end
