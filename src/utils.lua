local addonName, ItruliaQoL = ...

ItruliaQoL.PlayerClass = select(2, UnitClass("player"));

ItruliaQoL.interruptSpells = {
    DEATHKNIGHT = {[250] = 47528, [251] = 47528, [252] = 47528},
    DEMONHUNTER = {[577] = 183752, [581] = 183752, [1480] = 183752},
    DRUID = {[102] = 78675, [103] = 106839, [104] = 106839, [105] = nil},
    EVOKER = {[1467] = 351338, [1468] = 351338, [1473] = 351338},
    HUNTER = {[253] = 147362, [254] = 147362, [255] = 187707},
    MAGE = {[62] = 2139, [63] = 2139, [64] = 2139},
    MONK = {[268] = 116705, [269] = 116705, [270] = nil},
    PALADIN = {[65] = nil, [66] = 96231, [70] = 96231},
    PRIEST = {[256] = nil, [257] = nil, [258] = 15487},
    ROGUE = {[259] = 1766, [260] = 1766, [261] = 1766},
    SHAMAN = {[262] = 57994, [263] = 57994, [264] = 57994},
    WARLOCK = {[265] = 19647, [266] = 119914, [267] = 19647},
    WARRIOR = {[71] = 6552, [72] = 6552, [73] = 6552}
}

function ItruliaQoL:GetInterruptSpell()
    local class = select(2, UnitClass("player"))
    local specId = select(1, GetSpecializationInfo(GetSpecialization()))

    return ItruliaQoL.interruptSpells[class][specId]
end

ItruliaQoL.battleRezSpells = {
    DEATHKNIGHT = 61999,  -- Raise Ally
    DRUID = 20484,        -- Rebirth
    PALADIN = 391054,     -- Intercession
    WARLOCK = 20707,      -- Soulstone
}

function ItruliaQoL:GetBattleRezSpell()
    local class = select(2, UnitClass("player"))

    return ItruliaQoL.battleRezSpells[class]
end

function ItruliaQoL:InDungeon()
    local inInstance, instanceType = IsInInstance()

    return inInstance and instanceType == "party"
end

function ItruliaQoL:InMythicDungeon()
    if not self:InDungeon() then
        return false
    end

    local name = GetDifficultyInfo(GetDungeonDifficultyID())

    return name == "Mythic";
end

function ItruliaQoL:InRaid()
    local inInstance, instanceType = IsInInstance()

    return inInstance and instanceType == "raid"
end

function ItruliaQoL:IsSpellKnown(spellId)
    if not spellId then
        return
    end

    -- C_SpellBook.IsSpellInSpellBook might return false for w/e reason (like Fel Rush)
    -- C_SpellBook.IsSpellKnown doesn't work with overriden spells
    
    return C_SpellBook.IsSpellInSpellBook(spellId, Enum.SpellBookSpellBank.Player, false) or C_SpellBook.IsSpellKnown(spellId, Enum.SpellBookSpellBank.Player)
end

function ItruliaQoL:SplitAndTrim(str)
    local t = {}

    for part in string.gmatch(str, "([^,]+)") do
        part = part:match("^%s*(.-)%s*$") -- trim whitespace
        table.insert(t, part)
    end

    return t
end

function ItruliaQoL:GetGroupUnits()
    local units = {}

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            table.insert(units, "raid" .. i)
        end
    elseif IsInGroup() then
        table.insert(units, "player")
        for i = 1, GetNumSubgroupMembers() do
            table.insert(units, "party" .. i)
        end
    else
        table.insert(units, "player")
    end

    return units
end

function ItruliaQoL:CanGlide()
    local canGlide = select(2, C_PlayerInfo.GetGlidingInfo())

    if not canGlide then
        return false
    end

    -- can glide is slow
    return IsMounted() or UnitInVehicle("player") or GetShapeshiftFormID() ~= nil
end

function ItruliaQoL:OnDragonRidingChange(onEvent)
    local mountFrame = CreateFrame("frame", nil, UIParent)
    mountFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    mountFrame:RegisterEvent("PLAYER_CAN_GLIDE_CHANGED")
    mountFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    mountFrame:SetScript("OnEvent", function() 
        onEvent(ItruliaQoL:CanGlide())
    end)

    return mountFrame
end

local chatLinkHandlers = {}
local chatLinkHooked = false

-- garrmission links are one of the few link types the chat frame renders for addons,
-- clicking one runs through SetItemRef and the default handler ignores unknown payloads
function ItruliaQoL:RegisterChatLink(handlerName, handler)
    chatLinkHandlers[handlerName] = handler

    if chatLinkHooked then
        return
    end

    chatLinkHooked = true

    hooksecurefunc("SetItemRef", function(link)
        local name, payload = link:match("^garrmission:" .. addonName .. ":([^:]+):?(.*)$")
        if not name then
            return
        end

        local registered = chatLinkHandlers[name]
        if registered then
            registered(payload)
        end
    end)
end

function ItruliaQoL:ChatLink(handlerName, payload, text)
    return ("|Hgarrmission:%s:%s:%s|h|cff00ccff[%s]|r|h"):format(addonName, handlerName, payload or "", text)
end

function ItruliaQoL:UnitTokenFromGUID(guid)
    if not guid or hasanysecretvalues(guid) then
        return nil
    end

    local token = UnitTokenFromGUID(guid)

    if token then
        return token
    end

    if guid == UnitGUID("player") then
        return "player"
    end

    if IsInRaid() then
        for i = 1, 40 do
            local unit = "raid" .. i

            if guid == UnitGUID(unit) then
                return unit
            end
        end
    end

    if IsInGroup() then
        for i = 1, 4 do
            local unit = "party" .. i

            if guid == UnitGUID(unit) then
                return unit
            end
        end
    end

    return nil
end

function ItruliaQoL:CreateBorder(frame, r, g, b, a)
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetPoint("TOPLEFT", frame, 0, 0)
    border:SetPoint("BOTTOMRIGHT", frame, 0, 0)
    border:SetBackdrop({
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(r or 0, g or 0, b or 0, a or 1)
    border:SetBackdropColor(0, 0, 0, 0)
    border:SetFrameStrata(frame:GetFrameStrata())
    border:SetFrameLevel(frame:GetFrameLevel() + 2)

    function border:SetBorderColor(r2, g2, b2, a2)
        self:SetBackdropBorderColor(r2, g2, b2, a2 or 1)
    end

    return border
end

function ItruliaQoL:CreateBackground(frame, r, g, b, a)
    local background = CreateFrame("Frame", "$parent_Background", frame, "BackdropTemplate")
    background:SetAllPoints()
    background:SetFrameStrata(frame:GetFrameStrata())
    background:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 0))
    background:SetBackdrop({
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        edgeSize = 1,
    })
    background:SetBackdropColor(r or 0, g or 0, b or 0, a or 0.35)

    function background:SetColor(r2, g2, b2, a2)
        self:SetBackdropColor(r2, g2, b2, a2 or 1)
    end

    return background
end
