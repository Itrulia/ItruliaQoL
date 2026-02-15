local addonName, ItruliaQoL = ...
local moduleName = "PetMissingIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local PetMissingIndicator = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 300)
frame:SetSize(28, 28)

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetText("**Pet missing!**")
frame.text:SetTextColor(1, 1, 1)
frame.text:SetJustifyH("CENTER")
frame.text:Hide()

frame.petClasses = {
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

function frame:IsPetSpec()
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

function frame:IsPetPassive()
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

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(PetMissingIndicator.db.point.point, PetMissingIndicator.db.point.x, PetMissingIndicator.db.point.y)
        end

        self:SetFrameStrata(PetMissingIndicator.db.font.frameStrata or "BACKGROUND")
        self:SetFrameLevel(PetMissingIndicator.db.font.frameLevel or 1)
        self.text:SetText(PetMissingIndicator.db.displayText)
        self.text:SetTextColor(PetMissingIndicator.db.color.r, PetMissingIndicator.db.color.g, PetMissingIndicator.db.color.b, PetMissingIndicator.db.color.a)
        self.text:SetFont(LSM:Fetch("font", PetMissingIndicator.db.font.fontFamily), PetMissingIndicator.db.font.fontSize, PetMissingIndicator.db.font.fontOutline)
        self.text:SetShadowColor(PetMissingIndicator.db.font.fontShadowColor.r, PetMissingIndicator.db.font.fontShadowColor.g, PetMissingIndicator.db.font.fontShadowColor.b, PetMissingIndicator.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(PetMissingIndicator.db.font.fontShadowXOffset, PetMissingIndicator.db.font.fontShadowYOffset)
        self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
    end
end

local function OnEvent(self, event, ...)
    self:UpdateStyles()
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

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
frame:RegisterEvent("UNIT_PET")
frame:RegisterEvent("PET_BAR_UPDATE")
frame:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ALIVE")

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
        frame:SetScript("OnEvent", OnEvent)
        OnEvent(frame)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function PetMissingIndicator:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    frame:UpdateStyles()
end

function PetMissingIndicator:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil,
            nil,
            nil,
            "ALL,ITRULIA",
            function()
                return self.db.enable
            end,
            addonName .. "," .. moduleName
        )
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end
end

function PetMissingIndicator:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function PetMissingIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end)
end