local addonName, ItruliaQoL = ...
local moduleName = "FocusInterruptIndicator"
local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E
local C = ItruliaQoL.C
local CD = ItruliaQoL.CD

local FocusInterruptIndicator = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", UIParent, 0, 150)
frame:SetSize(28, 28)
frame.active = false
frame.interruptId = nil

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetTextColor(1, 1, 1)
frame.text:SetText("INTERRUPT")
frame.text:Hide()

frame.interruptSpells = {
    DEATHKNIGHT = {[250] = 47528, [251] = 47528, [252] = 47528},
    DEMONHUNTER = {[577] = 183752, [581] = 183752, [1480] = 183752},
    DRUID = {[102] = 78675, [103] = 106839, [104] = 106839, [105] = nil},
    Evoker = {[1467] = 351338, [1468] = 351338, [1473] = 351338},
    HUNTER = {[253] = 147362, [254] = 147362, [255] = 187707},
    MAGE = {[268] = 2139, [269] = 2139, [270] = 2139},
    MONK = {[268] = 116705, [269] = 116705, [270] = nil},
    PALADIN = {[65] = nil, [66] = 96231, [70] = 96231},
    Priest = {[256] = nil, [257] = nil, [258] = 15487},
    ROGUE = {[259] = 1766, [260] = 1766, [261] = 1766},
    SHAMAN = {[262] = 57994, [263] = 57994, [264] = 57994},
    WARLOCK = {[265] = 19647, [266] = 119914, [267] = 19647},
    WARRIOR = {[71] = 6552, [72] = 6552, [73] = 6552}
}

function frame:UpdateFocusInterruptIndicator(active)
    self.active = active

    if not self.active then
        return
    end

    local name, _, texture, _, _, _, _, _ = UnitChannelInfo("focus")
    local isChannel = false
    if name then 
        isChannel = true
    else 
        name, _, texture, _, _, _, _, _ = UnitCastingInfo("focus")
    end

    if not name then 
        self.active = false
        return
    end

    local duration
    if isChannel then
        duration = UnitChannelDuration("focus")
    else
        duration = UnitCastingDuration("focus")
    end

    if self:IsInteruptible() then
        self.text:Show()
        
        if FocusInterruptIndicator.db.playSound then
            PlaySoundFile(LSM:Fetch("sound", FocusInterruptIndicator.db.sound), "Master")
        end
    end
end

function frame:GetSpellToCheck()
    local class = select(2, UnitClass("player"))
    local specID = select(1, GetSpecializationInfo(GetSpecialization()))

    return frame.interruptSpells[class][specID]
end

function frame:IsInteruptible()
    local focusBar = _G.FocusFrameSpellBar
    
    if focusBar and focusBar.BorderShield then
        return not focusBar.BorderShield:IsShown()
    end

    return false
end

function frame:CacheSpellId()
    self.interruptId = frame:GetSpellToCheck()
end

function frame:UpdateStyles()
    if not E then
        frame:ClearAllPoints()
        frame:SetPoint(FocusInterruptIndicator.db.point.point, FocusInterruptIndicator.db.point.x, FocusInterruptIndicator.db.point.y)
    end

    frame:SetSize(FocusInterruptIndicator.db.fontSize, FocusInterruptIndicator.db.fontSize)

    frame.text:SetText(FocusInterruptIndicator.db.customText)
    frame.text:SetFont(LSM:Fetch("font", FocusInterruptIndicator.db.font), FocusInterruptIndicator.db.fontSize, FocusInterruptIndicator.db.fontOutline)
    frame.text:SetTextColor(FocusInterruptIndicator.db.color.r, FocusInterruptIndicator.db.color.g, FocusInterruptIndicator.db.color.b, FocusInterruptIndicator.db.color.a)
end

local function OnEvent(self, event, unit, ...)
    self.active = false
    frame:UpdateStyles()

    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        frame:CacheSpellId()
        return
    end

    if unit and UnitCanAttack("player", unit) then
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "PLAYER_FOCUS_CHANGED" then
            frame:UpdateFocusInterruptIndicator(true)
        end
    end
end

local function OnUpdate(self, elapsed)  
    if ItruliaQoL.testMode then
        self.text:Show()
        self.text:SetAlpha(1)
    elseif not self.active then
        self.timeSinceLastUpdate = 0
        self.text:Hide()
        self.text:SetAlpha(0);
        return
    end

    if not ItruliaQoL.testMode then
        self.text:SetAlphaFromBoolean(C_Spell.GetSpellCooldownDuration(self.interruptId):IsZero())
    end
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "focus")
frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "focus")
frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "focus")
frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "focus")
frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "focus")
frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "focus")

function FocusInterruptIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.FocusInterruptIndicator = profile.FocusInterruptIndicator or {
        enabled = true,
        point = { point = "CENTER", x = 0, y = 150 },
        color = {r = 1, g = 1, b = 1, a = 1},
        font = "Expressway",
        fontSize = 28,
        fontOutline = "OUTLINE",
        customText = "INTERRUPT",
        playSound = false,
        sound = "Kick"
    }
    self.db = profile.FocusInterruptIndicator
end

function FocusInterruptIndicator:OnEnable()
    if self.db.enabled then
        frame:SetScript("OnEvent", OnEvent)
        frame:SetScript("OnUpdate", OnUpdate)
    end

    if E then
        E:CreateMover(
            frame,               
            frame:GetName() .. "Mover",   
            frame:GetName(),
            nil, 
            nil, 
            nil, 
            nil, 
            nil
        )
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, { point = "CENTER", x = 0, y = 150 })
    end
end


local options = {
    type = "group",
    name = "Focus Interrupt",
    order = 3,
    args = {
        enable = {
            order = 1,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function() 
                return FocusInterruptIndicator.db.enabled
            end,
            set = function(_, value)
                FocusInterruptIndicator.db.enabled = value

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
                        return FocusInterruptIndicator.db.customText
                    end,
                    set = function(_, value)
                        FocusInterruptIndicator.db.customText = value
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
                        local c = FocusInterruptIndicator.db.color
                        return c.r, c.g, c.b, c.a
                    end,
                    set = function(_, r, g, b, a)
                        FocusInterruptIndicator.db.color = {
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
                        return FocusInterruptIndicator.db.font
                    end,
                    set = function(_, value)
                        FocusInterruptIndicator.db.font = value
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
                        return FocusInterruptIndicator.db.fontSize
                    end,
                    set = function(_, value)
                        FocusInterruptIndicator.db.fontSize = value
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
                        return FocusInterruptIndicator.db.fontOutline
                    end,
                    set = function(_, value)
                        FocusInterruptIndicator.db.fontOutline = value ~= "NONE" and value or nil
                        frame:UpdateStyles()
                    end,
                },
            }
        },
        soundGroup = {
            type = "group",
            name = "",
            order = 6,
            guiInline = true,
            args = {
                playSound = {
                    order = 1,
                    type = "toggle",
                    name = "Play sound",
                    get = function() 
                        return FocusInterruptIndicator.db.playSound
                    end,
                    set = function(_, value)
                        FocusInterruptIndicator.db.playSound = value
                    end,
                },
                sound = {
                    order = 2,
                    type = "select",
                    dialogControl = "LSM30_Sound", 
                    name = "Sound",
                    desc = "Select the sound used by this module",
                    values = LSM:HashTable("sound"),
                    get = function()
                        return FocusInterruptIndicator.db.sound
                    end,
                    set = function(_, value)
                        FocusInterruptIndicator.db.sound = value
                    end,
                    disabled = function()
                        return not FocusInterruptIndicator.db.playSound
                    end,
                },
            }
        },
    }
}

function FocusInterruptIndicator:RegisterOptions(parentCategory)
    if E then
        E.Options.args[addonName].args[moduleName] = options
    end

    C:RegisterOptionsTable(moduleName, options)
    CD:AddToBlizOptions(moduleName, "Focus Interrupt", parentCategory)
end