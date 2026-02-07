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

ItruliaQoL.dump = DevTools_Dump