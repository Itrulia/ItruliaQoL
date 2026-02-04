local addonName, ItruliaQoL = ...

function ItruliaQoL:IsSpellKnown(spellId)
    if not spellId then
        return
    end

    if C_SpellBook.IsSpellInSpellBook(spellId) then
        return true
    end
    
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

function ItruliaQoL:SplitAndTrim(str)
    local t = {}

    for part in string.gmatch(str, "([^,]+)") do
        part = part:match("^%s*(.-)%s*$") -- trim whitespace
        table.insert(t, part)
    end

    return t
end

ItruliaQoL.dump = DevTools_Dump