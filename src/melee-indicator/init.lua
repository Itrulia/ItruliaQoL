local addonName, ItruliaQoL = ...
local moduleName = "MeleeIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local MeleeIndicator = ItruliaQoL:NewModule(moduleName)

local MELEE_SPELLS = {
    DEATHKNIGHT = {
        [250] = 49998,
        [251] = 49998,
        [252] = 49998,
    },
    DEMONHUNTER = {
        [577] = 162794,
        [581] = 344859
    },
    DRUID = {
        [103] = 5221,
        [104] = 33917,
        [105] = 22568,
    },
    HUNTER = {
        [255] = 186270,
    },
    MONK = {
        [268] = 205523,
        [269] = 205523,
        [270] = 205523,
    },
    PALADIN = {
        [65] = 415091,
        [66] = 96231,
        [70] = 96231,
    },
    ROGUE = {
        [259] = 1752,
        [260] = 1752,
        [261] = 1752
    },
    SHAMAN = {
        [263] = 73899
    },
    WARRIOR = {
        [71] = 1715,
        [72] = 1715,
        [73] = 1715,
    },
}

local function OnEvent(self, ...)
    self:CacheMeleeSpellId()

    if ItruliaQoL.testMode then
        self.text:Show()
        return
    end
end

local function OnUpdate(self, elapsed)
    if not self.timeSinceLastUpdate then
        self.timeSinceLastUpdate = 0
    end

    self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed

    if self.timeSinceLastUpdate > MeleeIndicator.db.updateInterval then
        if not ItruliaQoL.testMode then
            self:UpdateMeleeIndicator()
        elseif not self.meleeSpellId then
            self.text:Hide()
        end

        self.timeSinceLastUpdate = 0
    end
end

function MeleeIndicator:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)
    f:SetPoint("CENTER", 0, 0)
    f:SetSize(28, 28)
    f.meleeSpellId = nil
    f.meleeSpellName = nil
    f.meleeSpells = MELEE_SPELLS

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("CENTER")
    f.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
    f.text:SetText("+")
    f.text:SetTextColor(1, 0, 0)
    f.text:SetJustifyH("CENTER")
    f.text:Hide()

    function f:GetSpellToCheck()
        local class = select(2, UnitClass("player"))
        local specId = select(1, GetSpecializationInfo(GetSpecialization()))
        local spells = self.meleeSpells[class]

        if not spells or not specId then
            return nil
        end

        local spellId = spells[specId]
        if not spellId then
            return nil
        end

        local spellInfo = C_Spell.GetSpellInfo(spellId)
        if not spellInfo then
            return nil
        end

        return spellId
    end

    function f:CacheMeleeSpellId()
        self.meleeSpellId = self:GetSpellToCheck()
        local spellInfo = self.meleeSpellId and C_Spell.GetSpellInfo(self.meleeSpellId)
        self.meleeSpellName = spellInfo and spellInfo.name
    end

    function f:UpdateMeleeIndicator()
        local targetExists = UnitExists("target")
        local targetAttackable = UnitCanAttack("player", "target")

        local class = select(2, UnitClass("player"))
        local inCombat = UnitAffectingCombat("player")

        local spellUsable = true

        if not inCombat then
            self.text:Hide()
            return
        end

        -- Only show when druid in cat or bear form
        if class == "DRUID" and self.meleeSpellId then
            local usable, missingResources = C_Spell.IsSpellUsable(self.meleeSpellId)
            spellUsable = usable or missingResources
        end

        if targetExists and targetAttackable and self.meleeSpellName then
            local inRange = C_Spell.IsSpellInRange(self.meleeSpellId, "target")

            if inRange then
                self.text:Hide()
            else
                if class == "DRUID" then
                    if spellUsable then
                        self.text:Show()
                    else
                        self.text:Hide()
                    end
                else
                    self.text:Show()
                end
            end
        else
            self.text:Hide()
        end
    end

    function f:UpdateStyles()
        if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
            if not E then
                self:ClearAllPoints()
                self:SetPoint(MeleeIndicator.db.point.point, MeleeIndicator.db.point.x, MeleeIndicator.db.point.y)
            end

            self:SetFrameStrata(MeleeIndicator.db.font.frameStrata or "BACKGROUND")
            self:SetFrameLevel(MeleeIndicator.db.font.frameLevel or 1)
            self.text:ClearAllPoints()
            self.text:SetPoint(MeleeIndicator.db.font.justifyH or "CENTER")
            self.text:SetJustifyH(MeleeIndicator.db.font.justifyH or "CENTER")
            self.text:SetTextColor(MeleeIndicator.db.color.r, MeleeIndicator.db.color.g, MeleeIndicator.db.color.b, MeleeIndicator.db.color.a)
            self.text:SetText(MeleeIndicator.db.displayText)
            if MeleeIndicator.db.font.fontOutline ~= "OUTLINESLUG" then
                self.text:SetShadowColor(MeleeIndicator.db.font.fontShadowColor.r, MeleeIndicator.db.font.fontShadowColor.g, MeleeIndicator.db.font.fontShadowColor.b, MeleeIndicator.db.font.fontShadowColor.a)
                self.text:SetShadowOffset(MeleeIndicator.db.font.fontShadowXOffset, MeleeIndicator.db.font.fontShadowYOffset)
            else
                self.text:SetShadowColor(0, 0, 0, 0)
                self.text:SetShadowOffset(0, 0)
            end
            self.text:SetFont(LSM:Fetch("font", MeleeIndicator.db.font.fontFamily), MeleeIndicator.db.font.fontSize, MeleeIndicator.db.font.fontOutline)
            self:SetSize(math.max(self.text:GetStringWidth(), 28), math.max(self.text:GetStringHeight(), 28))
        end
    end

    return f
end

function MeleeIndicator:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

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

function MeleeIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.MeleeIndicator = profile.MeleeIndicator or self:GetDefaults()
    self.db = profile.MeleeIndicator
end

function MeleeIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.MeleeIndicator = profile.MeleeIndicator or self:GetDefaults()
    self.db = profile.MeleeIndicator

    if self.db.enabled then
        local f = self:EnsureFrame()

        f:UpdateStyles()
        f:CacheMeleeSpellId()
        f:SetScript("OnEvent", OnEvent)
        f:SetScript("OnUpdate", OnUpdate)
        OnEvent(f)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
        self.frame:SetScript("OnUpdate", nil)
        self.frame.text:Hide()
    end
end

function MeleeIndicator:ApplyFontSettings(font)
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

function MeleeIndicator:OnEnable()
    self:RefreshConfig()
end

function MeleeIndicator:ToggleTestMode()
    if not self.db.enabled or not self.frame then
        return
    end

    OnEvent(self.frame)
end

function MeleeIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
        end

        ItruliaQoL:RefreshPreview(self)
    end)
end
