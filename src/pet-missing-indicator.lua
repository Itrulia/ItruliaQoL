local addonName, ItruliaQoL = ...
local moduleName = "PetMissingIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E
local C = ItruliaQoL.C
local CD = ItruliaQoL.CD

local PetMissingIndicator = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 300)
frame:SetSize(28, 28)

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetText("**Pet missing!**")
frame.text:SetTextColor(1, 1, 1)
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
    local petInCombat = UnitAffectingCombat("pet")

    if not petTarget then
        return true
    end

    return false
end

function frame:UpdateStyles(forceUpdate)
    if not InCombatLockdown() or forceUpdate then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(PetMissingIndicator.db.point.point, PetMissingIndicator.db.point.x, PetMissingIndicator.db.point.y)
        end

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

local defaults = {
    enabled = true,
    displayText = "**Pet missing!**",
    color = {r = 1, g = 1, b = 1, a = 1},
    updateInterval = 0.5,
    point = {point = "CENTER", x = 0, y = 300},

    font = {
        fontFamily = "Expressway",
        fontSize = 28,
        fontOutline = "OUTLINE",
        fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
        fontShadowXOffset = 1,
        fontShadowYOffset = -1,
    }
}

function PetMissingIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.PetMissingIndicator = profile.PetMissingIndicator or defaults
    self.db = profile.PetMissingIndicator
end

function PetMissingIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.PetMissingIndicator = profile.PetMissingIndicator or defaults
    self.db = profile.PetMissingIndicator

    if self.db.enabled then
        frame:SetScript("OnEvent", OnEvent)
        OnEvent(frame)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function PetMissingIndicator:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil, nil, nil, nil, nil)
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, {point = "CENTER", x = 0, y = 300})
    end
end

function PetMissingIndicator:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

local options = {
    type = "group",
    name = "Missing Pet",
    order = 4,
    args = {
        description = {
            type = "description",
            name =  "Displays a text when you are a pet spec and your pet is missing\n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function(info)
                return PetMissingIndicator.db.enabled
            end,
            set = function(info, value)
                PetMissingIndicator.db.enabled = value
                PetMissingIndicator:RefreshConfig()
            end
        },
        displaySettings = {
            type = "group",
            name = "",
            order = 4,
            guiInline = true,
            args = {
                displayText = {
                    order = 2,
                    type = "input",
                    name = "Display text",
                    get = function()
                        return PetMissingIndicator.db.displayText
                    end,
                    set = function(_, value)
                        PetMissingIndicator.db.displayText = value
                        frame:UpdateStyles()
                    end
                },
                color = {
                    order = 2,
                    type = "color",
                    name = "Color",
                    hasAlpha = true,
                    get = function()
                        local c = PetMissingIndicator.db.color
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        PetMissingIndicator.db.color = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        frame:UpdateStyles()
                    end
                }
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
                    values = LSM:HashTable("font"),
                    get = function()
                        return PetMissingIndicator.db.font.fontFamily
                    end,
                    set = function(_, value)
                        PetMissingIndicator.db.font.fontFamily = value
                        frame:UpdateStyles()
                    end
                },
                fontSize = {
                    order = 2,
                    type = "range",
                    name = "Size",
                    min = 1,
                    max = 68,
                    step = 1,
                    get = function()
                        return PetMissingIndicator.db.font.fontSize
                    end,
                    set = function(_, value)
                        PetMissingIndicator.db.font.fontSize = value
                        frame:UpdateStyles()
                    end
                },
                fontOutline = {
                    order = 3,
                    type = "select",
                    name = "Outline",
                    values = {
                        NONE = "None",
                        OUTLINE = "Outline",
                        THICKOUTLINE = "Thick Outline",
                        MONOCHROME = "Monochrome"
                    },
                    get = function()
                        return PetMissingIndicator.db.font.fontOutline
                    end,
                    set = function(_, value)
                        PetMissingIndicator.db.font.fontOutline = value ~= "NONE" and value or nil
                        frame:UpdateStyles()
                    end
                },
                fontShadowColor = {
                    order = 4,
                    type = "color",
                    name = "Shadow Color",
                    hasAlpha = true,
                    get = function()
                        local c = PetMissingIndicator.db.font.fontShadowColor
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        PetMissingIndicator.db.font.fontShadowColor = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        frame:UpdateStyles()
                    end
                },
                fontShadowXOffset = {
                    order = 5,
                    type = "range",
                    name = "Shadow X Offset",
                    min = -5,
                    max = 5,
                    step = 1,
                    get = function()
                        return PetMissingIndicator.db.font.fontShadowXOffset
                    end,
                    set = function(_, value)
                        PetMissingIndicator.db.font.fontShadowXOffset = value
                        frame:UpdateStyles()
                    end
                },
                fontShadowYOffset = {
                    order = 5,
                    type = "range",
                    name = "Shadow Y Offset",
                    min = -5,
                    max = 5,
                    step = 1,
                    get = function()
                        return PetMissingIndicator.db.font.fontShadowYOffset
                    end,
                    set = function(_, value)
                        PetMissingIndicator.db.font.fontShadowYOffset = value
                        frame:UpdateStyles()
                    end
                },
            }
        }
    }
}

function PetMissingIndicator:RegisterOptions(parentCategory, parentOptions)
    if E then
        E.Options.args[addonName].args[moduleName] = options
        C:RegisterOptionsTable(moduleName, options)
    else
        parentOptions.args[moduleName] = options;
        CD:AddToBlizOptions(moduleName, "Missing Pet", parentCategory)
    end
end