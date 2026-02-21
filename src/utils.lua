local addonName, ItruliaQoL = ...

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

-- Credits to KinderLine
-- Only using it for out of combat things that blizzard decided to make secret (cauldrons, etc)
local launderBar = CreateFrame("StatusBar")
launderBar:SetMinMaxValues(0, 9999999)
local onValueChangedResult = nil
launderBar:SetScript("OnValueChanged", function(self, value)
    onValueChangedResult = value
end)

function ItruliaQoL:LaunderSecretValue(value)
    onValueChangedResult = nil
    launderBar:SetValue(0)
    pcall(launderBar.SetValue, launderBar, value)

    return onValueChangedResult
end


function ItruliaQoL:OnDragonRidingChange(onEvent)
    local mountFrame = CreateFrame("frame", nil, UIParent)
    mountFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    mountFrame:RegisterEvent("PLAYER_CAN_GLIDE_CHANGED")
    mountFrame:SetScript("OnEvent", function() 
        onEvent(select(2, C_PlayerInfo.GetGlidingInfo()))
    end)

    return mountFrame
end