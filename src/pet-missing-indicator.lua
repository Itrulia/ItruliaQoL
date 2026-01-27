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
    Evoker = {[1467] = false, [1468] = false, [1473] = false},
    HUNTER = {[253] = true, [254] = 1223323, [255] = true},
    MAGE = {[268] = false, [269] = false, [270] = 31687},
    MONK = {[268] = false, [269] = false, [270] = false},
    PALADIN = {[65] = false, [66] = false, [70] = false},
    Priest = {[256] = false, [257] = false, [258] = false},
    ROGUE = {[259] = false, [260] = false, [261] = false},
    SHAMAN = {[262] = false, [263] = false, [264] = false},
    WARLOCK = {[265] = true, [266] = true, [267] = true},
    WARRIOR = {[71] = false, [72] = false, [73] = false}
}

function frame:IsSpellKnown(spellId)
    local configId = C_ClassTalents.GetActiveConfigID()
    if not configId then 
        return false 
    end

    local configInfo = C_Traits.GetConfigInfo(configId)

    if not configInfo or not configInfo.treeIDs then 
        return false 
    end

    for _, treeID in ipairs(configInfo.treeIDs) do
        local nodeIDs = C_Traits.GetTreeNodes(treeID)

        for _, nodeID in ipairs(nodeIDs) do
            local nodeInfo = C_Traits.GetNodeInfo(configId, nodeID)

            if nodeInfo and nodeInfo.activeEntry then
                local entryInfo = C_Traits.GetEntryInfo(configId, nodeInfo.activeEntry.entryID)

                if entryInfo and entryInfo.definitionID then
                    local defInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)

                    if defInfo and defInfo.spellID == spellId then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function frame:IsPetSpec()
    local class = select(2, UnitClass("player"))
    local specID = select(1, GetSpecializationInfo(GetSpecialization()))
    local spells = frame.petClasses[class]

    if not spells or not specID then 
        return nil 
    end

    local spellId = spells[specID]

    if spellId == true or spellId == false then 
        return spellId 
    end

    return frame:IsSpellKnown(spellId)
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

function frame:UpdateStyles()
    if not E then
        frame:ClearAllPoints()
        frame:SetPoint(PetMissingIndicator.db.point.point, PetMissingIndicator.db.point.x, PetMissingIndicator.db.point.y)
    end

    frame:SetSize(PetMissingIndicator.db.fontSize, PetMissingIndicator.db.fontSize)
    frame.text:SetText(PetMissingIndicator.db.customText)
    frame.text:SetFont(LSM:Fetch("font", PetMissingIndicator.db.font), PetMissingIndicator.db.fontSize, PetMissingIndicator.db.fontOutline)
    frame.text:SetTextColor(PetMissingIndicator.db.color.r, PetMissingIndicator.db.color.g, PetMissingIndicator.db.color.b, PetMissingIndicator.db.color.a)
end

local function OnEvent(self, event, ...)
    frame:UpdateStyles()
    local petSpec = frame:IsPetSpec()
    local conditionsWherePetIsntShown = IsMounted() or UnitInVehicle("player") or UnitIsDeadOrGhost("player")

    if not ItruliaQoL.testMode then
        if not petSpec or conditionsWherePetIsntShown then
            frame.text:Hide()
        else
            if UnitExists("pet") then
                frame.text:Hide()
            else
                frame.text:Show()
            end
        end
    end

    if ItruliaQoL.testMode then 
        frame.text:Show()
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
frame:RegisterEvent("UNIT_ENTERED_VEHICLE")
frame:RegisterEvent("UNIT_EXITED_VEHICLE")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ALIVE")

function PetMissingIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.PetMissingIndicator = profile.PetMissingIndicator or {
        enabled = true,
        customText = "**Pet missing!**",
        color = {r = 1, g = 1, b = 1, a = 1},
        font = "Expressway",
        fontSize = 28,
        fontOutline = "OUTLINE",
        updateInterval = 0.5,
        point = {point = "CENTER", x = 0, y = 300}
    }
    self.db = profile.PetMissingIndicator
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

local options = {
    type = "group",
    name = "Missing Pet",
    order = 4,
    args = {
        enable = {
            order = 1,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function(info)
                return PetMissingIndicator.db.enabled
            end,
            set = function(info, value)
                PetMissingIndicator.db.enabled = value

                if value then
                    frame:SetScript("OnEvent", OnEvent)
                    onEvent(frame)
                else
                    frame:SetScript("OnEvent", nil)
                    frame:SetScript("OnUpdate", nil)
                end
            end
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
                        return PetMissingIndicator.db.customText
                    end,
                    set = function(_, value)
                        PetMissingIndicator.db.customText = value
                        frame:UpdateStyles()
                    end
                },
                color = {
                    order = 2,
                    type = "color",
                    name = "Indicator Color",
                    desc = "Set the color of the indicator",
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
                    desc = "Select the font used by this module",
                    values = LSM:HashTable("font"),
                    get = function()
                        return PetMissingIndicator.db.font
                    end,
                    set = function(_, value)
                        PetMissingIndicator.db.font = value
                        frame:UpdateStyles()
                    end
                },
                fontSize = {
                    order = 2,
                    type = "range",
                    name = "Font Size",
                    min = 12,
                    max = 68,
                    step = 1,
                    get = function()
                        return PetMissingIndicator.db.fontSize
                    end,
                    set = function(_, value)
                        PetMissingIndicator.db.fontSize = value
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
                        return PetMissingIndicator.db.fontOutline
                    end,
                    set = function(_, value)
                        PetMissingIndicator.db.fontOutline = value ~= "NONE" and value or "OUTLINE"
                        frame:UpdateStyles()
                    end
                }
            }
        }
    }
}

function PetMissingIndicator:RegisterOptions(parentCategory)
    if E then
        E.Options.args[addonName].args[moduleName] = options
    end

    C:RegisterOptionsTable(moduleName, options)
    CD:AddToBlizOptions(moduleName, "Missing Pet", parentCategory)
end