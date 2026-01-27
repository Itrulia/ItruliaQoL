local addonName, ItruliaQoL = ...
local moduleName = "MovementAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E
local C = ItruliaQoL.C
local CD = ItruliaQoL.CD

local MovementAlert = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 300)
frame:SetSize(28, 28)
frame.movementId = nil;
frame.movementName = nil;

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 14, "OUTLINE")
frame.text:SetTextColor(1, 1, 1, 1)
frame.text:Hide();

frame.movementAbilities = {
    DEATHKNIGHT = {[250] = {48265}, [251] = {48265}, [252] = {48265}},
    DEMONHUNTER = {[577] = {195072}, [581] = {189110}, [1480] = {1234796}},
    DRUID = {[102] = {102401, 252216, 1850}, [103] = {102401, 252216, 1850}, [104] = {102401, 106898}, [105] = {102401, 252216, 1850}},
    Evoker = {[1467] = {358267 }, [1468] = {358267 }, [1473] = {358267 }},
    HUNTER = {[253] = {781}, [254] = {781}, [255] = {781}},
    MAGE = {[62] = {212653, 1953}, [63] = {212653, 1953}, [64] = {212653, 1953}},
    MONK = {[268] = {115008, 109132}, [269] = {109132}, [270] = {109132}},
    PALADIN = {[65] = {190784} , [66] = {190784} , [70] = {190784} },
    Priest = {[256] = {121536,73325}, [257] = {121536,73325}, [258] = {121536,73325}},
    ROGUE = {[259] = {36554}, [260] = {195457}, [261] = {36554}},
    SHAMAN = {[262] = {79206, 90328, 192063}, [263] = {90328, 192063}, [264] = {79206, 90328, 192063}},
    WARLOCK = {[265] = {48020}, [266] = {48020}, [267] = {48020}},
    WARRIOR = {[71] = {6544}, [72] = {6544}, [73] = {6544}}
}

function frame:GetSpellToCheck()
    local class = select(2, UnitClass("player"))
    local specId = select(1, GetSpecializationInfo(GetSpecialization()))
    local spells = frame.movementAbilities[class]

    if not spells or not specId then 
        return nil
    end


    local spellIds = spells[specId]
    if not spellIds then
        return nil
    end

    local spellId
    for _, s in ipairs(spellIds) do
        if ItruliaQoL:IsSpellKnown(s) then
            spellId = s
            break
        end
    end

    if not spellId then
        return nil
    end

    local spellInfo = C_Spell.GetSpellInfo(spellId)
    if not spellInfo then
        return nil
    end

    return spellId
end

function frame:UpdateStyles()
    if not E then
        frame:ClearAllPoints()
        frame:SetPoint(MovementAlert.db.point.point, MovementAlert.db.point.x, MovementAlert.db.point.y)
    end

    frame.text:SetFont(LSM:Fetch("font", MovementAlert.db.font), MovementAlert.db.fontSize, MovementAlert.db.fontOutline)
    frame.text:SetTextColor(MovementAlert.db.color.r, MovementAlert.db.color.g, MovementAlert.db.color.b, MovementAlert.db.color.a)
    frame:SetSize(math.max(frame.text:GetStringWidth(), 28), math.max(frame.text:GetStringHeight(), 28))
end

local function OnUpdate(self, elapsed, ...)
    if not self.timeSinceLastUpdate then 
        self.timeSinceLastUpdate = 0 
    end

    self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
    
    if self.timeSinceLastUpdate > MovementAlert.db.updateInterval then
        if not ItruliaQoL.testMode then
            if self.movementId then
                local cdInfo = C_Spell.GetSpellCooldown(self.movementId)

                if cdInfo and cdInfo.timeUntilEndOfStartRecovery then
                    self.text:SetText("No " .. self.movementName .. "\n" .. string.format("%." .. MovementAlert.db.precision .. "f", cdInfo.timeUntilEndOfStartRecovery))
                    self.text:Show()
                else
                    self.text:Hide()
                end
            else
                self.text:Hide()
            end
        end

        self.timeSinceLastUpdate = 0
    end
end

function frame:CacheMovementId()
    self.movementId = self:GetSpellToCheck()
    local spellInfo = self.movementId and C_Spell.GetSpellInfo(self.movementId)
    self.movementName = spellInfo and spellInfo.name
end

local function OnEvent(self, ...)
    self:UpdateStyles()
    self:CacheMovementId()

    if ItruliaQoL.testMode then
        self.text:SetText("No " .. self.movementName .. "\n" .. string.format("%." .. MovementAlert.db.precision .. "f", 15.3))
        self.text:Show()
        return
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")

local defaults = {
    enabled = true,
    precision = 0,
    color = {r = 1, g = 1, b = 1, a = 1},
    font = "Expressway",
    fontSize = 14,
    fontOutline = "OUTLINE",
    updateInterval = 0.1,
    point = {point = "CENTER", x = 0, y = 50},
}

function MovementAlert:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.MovementAlert = profile.MovementAlert or defaults
    self.db = profile.MovementAlert
end

function MovementAlert:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.MovementAlert = profile.MovementAlert or defaults
    self.db = profile.MovementAlert

    if self.db.enabled then
        frame:UpdateStyles()
        frame:CacheMovementId()
        frame:SetScript("OnEvent", OnEvent)
        frame:SetScript("OnUpdate", OnUpdate) 
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function MovementAlert:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
        frame:SetScript("OnUpdate", OnUpdate) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil, nil, nil, nil, nil)
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, {point = "CENTER", x = 0, y = 50})
    end
end

function MovementAlert:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

local options = {
    type = "group",
    name = "Movement Alert",
    order = 2,
    args = {
        enable = {
            order = 1,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function(info)
                return MovementAlert.db.enabled
            end,
            set = function(info, value)
                MovementAlert.db.enabled = value
                MovementAlert:RefreshConfig()
            end
        },
        displaySettings = {
            type = "group",
            name = "",
            order = 4,
            guiInline = true,
            args = {
                color = {
                    order = 2,
                    type = "color",
                    name = "Indicator Color",
                    desc = "Set the color of the indicator",
                    hasAlpha = true,
                    get = function()
                        local c = MovementAlert.db.color
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        MovementAlert.db.color = {
                            r = r,
                            g = g,
                            b = b,
                            a = a
                        }
                        frame:UpdateStyles()
                    end
                },
                decimals = {
                    order = 3,
                    type = "range",
                    min = 0,
                    max = 1,
                    step = 1,
                    name = "Precision",
                    desc = "How many decimals should be shown?",
                    get = function()
                        return MovementAlert.db.precision
                    end,
                    set = function(_, value)
                        MovementAlert.db.precision = value
                        frame:UpdateStyles()
                    end
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
                        return MovementAlert.db.font
                    end,
                    set = function(_, value)
                        MovementAlert.db.font = value
                        frame:UpdateStyles()
                    end
                },
                fontSize = {
                    order = 2,
                    type = "range",
                    name = "Font Size",
                    min = 1,
                    max = 68,
                    step = 1,
                    get = function()
                        return MovementAlert.db.fontSize
                    end,
                    set = function(_, value)
                        MovementAlert.db.fontSize = value
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
                        return MovementAlert.db.fontOutline
                    end,
                    set = function(_, value)
                        MovementAlert.db.fontOutline = value ~= "NONE" and value or "OUTLINE"
                        frame:UpdateStyles()
                    end
                }
            }
        },
    }
}

function MovementAlert:RegisterOptions(parentCategory)
    if E then
        E.Options.args[addonName].args[moduleName] = options
    end

    C:RegisterOptionsTable(moduleName, options)
    -- CD:AddToBlizOptions(moduleName, "Movement Alert", parentCategory)
end