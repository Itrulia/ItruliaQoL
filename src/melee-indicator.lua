local addonName, ItruliaQoL = ...
local moduleName = "MeleeIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E
local C = ItruliaQoL.C
local CD = ItruliaQoL.CD

local MeleeIndicator = ItruliaQoL:NewModule(moduleName)

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
frame.text:Hide()

frame.meleeSpells = {
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
        [104] = 5221, 
        [105] = 5221,
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
        [65] = 96231, 
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
        [71] = 1464, 
        [72] = 1464, 
        [73] = 1464, 
    },
}

function frame:GetSpellToCheck()
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

function frame:UpdateMeleeIndicator()
    local targetExists = UnitExists("target")
    local targetAttackable = UnitCanAttack("player", "target")

    local class = select(2, UnitClass("player"))
    local specId = select(1, GetSpecializationInfo(GetSpecialization()))
    local inCombat = UnitAffectingCombat("player")

    local spellUsable = true

    if not inCombat then
        self.text:Hide()
        return
    end

    -- Only show when druid in cat or bear form
    if class == "DRUID" and self.meleeSpellId then
        spellUsable, _ = C_Spell.IsSpellUsable(self.meleeSpellId)
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

function frame:UpdateStyles()
    if not E then
        self:ClearAllPoints()
        self:SetPoint(MeleeIndicator.db.point.point, MeleeIndicator.db.point.x, MeleeIndicator.db.point.y)
    end

    self.text:SetFont(LSM:Fetch("font", MeleeIndicator.db.font), MeleeIndicator.db.fontSize, MeleeIndicator.db.fontOutline)
    self.text:SetTextColor(MeleeIndicator.db.color.r, MeleeIndicator.db.color.g, MeleeIndicator.db.color.b, MeleeIndicator.db.color.a)
    self.text:SetText(MeleeIndicator.db.customText)
    self:SetSize(math.max(self.text:GetStringWidth(), 28), math.max(self.text:GetStringHeight(), 28))
end

function frame:CacheMeleeSpellId()
    self.meleeSpellId = self:GetSpellToCheck()
    local spellInfo = self.meleeSpellId and C_Spell.GetSpellInfo(self.meleeSpellId)
    self.meleeSpellName = spellInfo and spellInfo.name
end

local function OnEvent(self, ...)
    self:UpdateStyles()
    self:CacheMeleeSpellId()

    if ItruliaQoL.testMode then
        self.text:Show()
        return
    end
end

local function OnUpdate(self, elapsed)
    if not self.meleeSpellId then
        self:SetScript("OnUpdate", nil)
        self.text:Hide()
        
        return
    end

    if not self.timeSinceLastUpdate then 
        self.timeSinceLastUpdate = 0 
    end

    self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
    
    if self.timeSinceLastUpdate > MeleeIndicator.db.updateInterval then
        if not ItruliaQoL.testMode then
            self:UpdateMeleeIndicator()
        end

        self.timeSinceLastUpdate = 0
    end
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

local defaults = {
    enabled = true,
    customText = "+",
    color = {r = 1, g = 0, b = 0, a = 1},
    font = "Expressway",
    fontSize = 28,
    fontOutline = "OUTLINE",
    updateInterval = 0.5,
    point = { point = "CENTER", x = 0, y = 0 }
}

function MeleeIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.MeleeIndicator = profile.MeleeIndicator or defaults
    self.db = profile.MeleeIndicator
end

function MeleeIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.MeleeIndicator = profile.MeleeIndicator or defaults
    self.db = profile.MeleeIndicator

    if self.db.enabled then
        frame:UpdateStyles()
        frame:CacheMeleeSpellId()
        frame:SetScript("OnEvent", OnEvent)
        frame:SetScript("OnUpdate", OnUpdate)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function MeleeIndicator:OnEnable()
    if self.db.enabled then
        frame:SetScript("OnEvent", OnEvent)
        frame:SetScript("OnUpdate", OnUpdate)
    end

    if E then
        E:CreateMover(
            frame,               
            frame:GetName() .. "Mover",   
            moduleName,
            nil, 
            nil, 
            nil, 
            nil, 
            nil
        )
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, { point = "CENTER", x = 0, y = 0 })
    end
end

function MeleeIndicator:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

local options = {
    type = "group",
    name = "Melee Indicator",
    order = 1,
    args = {
        enable = {
            order = 1,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function(info) 
                return MeleeIndicator.db.enabled
            end,
            set = function(info, value)
                MeleeIndicator.db.enabled = value
                MeleeIndicator:RefreshConfig()
            end,
        },
        displaySettings = {
            type = "group",
            name = "",
            order = 4,
            guiInline = true,
            args = {
                customText = {
                    order = 2,
                    type = "input",
                    name = "Display text",
                    desc = "Text to display on the indicator",
                    get = function()
                        return MeleeIndicator.db.customText
                    end,
                    set = function(_, value)
                        MeleeIndicator.db.customText = value
                        frame:UpdateStyles()
                    end,
                },
                color = {
                    order = 2,
                    type = "color",
                    name = "Indicator Color",
                    desc = "Set the color of the indicator",
                    hasAlpha = true, 
                    get = function()
                        local c = MeleeIndicator.db.color
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        MeleeIndicator.db.color = {
                            r = r,
                            g = g,
                            b = b,
                            a = a,
                        }
                        frame:UpdateStyles()
                    end,
                },
            }
        },
        fontSettings = {
            type = "group",
            name = "",
            order = 5,
            guiInline = true,
            args = {
                font = {
                    order = 1,
                    type = "select",
                    dialogControl = "LSM30_Font", 
                    name = "Font",
                    desc = "Select the font used by this module",
                    values = LSM:HashTable("font"),
                    get = function()
                        return MeleeIndicator.db.font
                    end,
                    set = function(_, value)
                        MeleeIndicator.db.font = value
                        frame:UpdateStyles()
                    end,
                },
                fontSize = {
                    order = 2,
                    type = "range",
                    name = "Font Size",
                    min = 1,
                    max = 68,
                    step = 1,
                    get = function() 
                        return MeleeIndicator.db.fontSize
                    end,
                    set = function(_, value)
                        MeleeIndicator.db.fontSize = value
                        frame:UpdateStyles()
                    end,
                },
                fontOutline = {
                    order = 3,
                    type = "select",
                    name = "Outline",
                    values = {
                        NONE = "None",
                        OUTLINE = "Outline",
                        THICKOUTLINE = "Thick Outline",
                        MONOCHROME = "Monochrome",
                    },
                    get = function()
                        return MeleeIndicator.db.fontOutline
                    end,
                    set = function(_, value)
                        MeleeIndicator.db.fontOutline = value ~= "NONE" and value or nil
                        frame:UpdateStyles()
                    end,
                },
            }
        },
    }
}

function MeleeIndicator:RegisterOptions(parentCategory)
    if E then
        E.Options.args[addonName].args[moduleName] = options
    end

    C:RegisterOptionsTable(moduleName, options)
    -- CD:AddToBlizOptions(moduleName, "Melee Indicator", parentCategory)
end
