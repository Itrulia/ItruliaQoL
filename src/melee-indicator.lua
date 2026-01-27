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
        [250] = 316239, 
        [251] = 316239, 
        [252] = 316239, 
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
    local specID = select(1, GetSpecializationInfo(GetSpecialization()))
    local spells = frame.meleeSpells[class]

    if not spells or not specID then 
        return nil
    end

    local spellId = spells[specID]
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
    local specID = select(1, GetSpecializationInfo(GetSpecialization()))
    local inCombat = UnitAffectingCombat("player")

    local spellUsable = true
    local inRange = false

    if not inCombat then
        frame.text:Hide()
        return
    end

    -- Only show when druid in cat or bear form
    if class == "DRUID" and frame.meleeSpellId then
        spellUsable, _ = C_Spell.IsSpellUsable(frame.meleeSpellId)
    end

    if targetExists and targetAttackable and frame.meleeSpellName then
        inRange = C_Spell.IsSpellInRange(frame.meleeSpellId, "target")

        if inRange then
            frame.text:Hide()
        else
            if class == "DRUID" then
                if spellUsable then
                    frame.text:Show()
                else
                    frame.text:Hide()
                end
            else
                frame.text:Show()
            end
        end
    else
        frame.text:Hide()
    end
end

function frame:UpdateStyles()
    if not E then
        frame:ClearAllPoints()
        frame:SetPoint(MeleeIndicator.db.point.point, MeleeIndicator.db.point.x, MeleeIndicator.db.point.y)
    end

    frame:SetSize(MeleeIndicator.db.fontSize, MeleeIndicator.db.fontSize)
    frame.text:SetFont(LSM:Fetch("font", MeleeIndicator.db.font), MeleeIndicator.db.fontSize, MeleeIndicator.db.fontOutline)
    frame.text:SetTextColor(MeleeIndicator.db.color.r, MeleeIndicator.db.color.g, MeleeIndicator.db.color.b, MeleeIndicator.db.color.a)
    frame.text:SetText(MeleeIndicator.db.customText)
end

local function OnEvent(self, ...)
    frame:UpdateStyles()

    frame.meleeSpellId = frame:GetSpellToCheck()
    local spellInfo = frame.meleeSpellId and C_Spell.GetSpellInfo(frame.meleeSpellId)
    frame.meleeSpellName = spellInfo and spellInfo.name

    if frame.meleeSpellId and not frame:GetScript("OnUpdate") then
        frame:SetScript("OnUpdate", function(self, elapsed)
            if not self.timeSinceLastUpdate then 
                self.timeSinceLastUpdate = 0 
            end

            self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
            
            if self.timeSinceLastUpdate > MeleeIndicator.db.updateInterval then
                if not ItruliaQoL.testMode then
                    frame:UpdateMeleeIndicator()
                end

                if ItruliaQoL.testMode then
                    frame.text:Show()
                end

                self.timeSinceLastUpdate = 0
            end
        end)
    elseif not frame.meleeSpellId then
        frame:SetScript("OnUpdate", nil)
        frame.text:Hide()
    end
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

function MeleeIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.MeleeIndicator = profile.MeleeIndicator or {
        enabled = true,
        customText = "+",
        color = {r = 1, g = 0, b = 0, a = 1},
        font = "Expressway",
        fontSize = 28,
        fontOutline = "OUTLINE",
        updateInterval = 0.5,
        point = { point = "CENTER", x = 0, y = 0 }
    }
    self.db = profile.MeleeIndicator
end

function MeleeIndicator:OnEnable()
    if self.db.enabled then
        frame:SetScript("OnEvent", OnEvent)
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

                if value then
                    frame:SetScript("OnEvent", OnEvent)
                    onEvent(frame)
                else
                    frame:SetScript("OnEvent", nil)
                    frame:SetScript("OnUpdate", nil)
                end
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
                    min = 12,
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
    CD:AddToBlizOptions(moduleName, "Melee Indicator", parentCategory)
end
