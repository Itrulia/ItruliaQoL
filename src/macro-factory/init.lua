local addonName, ItruliaQoL = ...
local moduleName = "MacroFactory"
local LSM = ItruliaQoL.LSM

local MacroFactory = ItruliaQoL:NewModule(moduleName)

-- Macros registered by the per-class files; used to build the options buttons.
MacroFactory.macros = {}

--[[ Example usage:
    MacroFactory:RegisterMacro({
        group = "Death Knight",       -- section heading in the options
        subgroup = "Frost",           -- optional sub-section within the group
        name = "Frostbane",           -- button label and in-game macro name
        desc = "What the macro does", -- optional hover tooltip
        icon = 194913,                -- spell id, texture, or function returning one
        create = MacroFactory.CreateFrostbaneMacro,
    })
]]
function MacroFactory:RegisterMacro(def)
    table.insert(self.macros, def)
end

-- Resolves a macro's `icon` (a spell id, a texture path/id, or a function
-- returning one of those) into a texture usable by an icon button.
function MacroFactory:ResolveIcon(icon)
    if type(icon) == "function" then
        icon = icon()
    end

    if type(icon) == "number" then
        -- Treat as a spell id first, fall back to using it as a raw texture id.
        return C_Spell.GetSpellTexture(icon) or icon
    end

    if type(icon) == "string" then
        return icon
    end

    return 134400 -- question mark
end

-- Groups the registered macros by section and optional sub-section, preserving
-- registration order. Both option hosts (AceConfig and EllesmereUI) build their
-- layout from this so they stay in sync. Returns an ordered list of:
--   { name = "Death Knight", macros = { <direct macros> },
--     subgroups = { { name = "Frost", macros = { ... } }, ... } }
function MacroFactory:GetGroupedMacros()
    local groups, byName = {}, {}

    for _, macro in ipairs(self.macros) do
        local groupName = macro.group or "Macros"
        local group = byName[groupName]

        if not group then
            group = { name = groupName, macros = {}, subgroups = {}, subByName = {} }
            byName[groupName] = group
            groups[#groups + 1] = group
        end

        if macro.subgroup then
            local sub = group.subByName[macro.subgroup]

            if not sub then
                sub = { name = macro.subgroup, macros = {} }
                group.subByName[macro.subgroup] = sub
                group.subgroups[#group.subgroups + 1] = sub
            end

            sub.macros[#sub.macros + 1] = macro
        else
            group.macros[#group.macros + 1] = macro
        end
    end

    return groups
end

function MacroFactory:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.MacroFactory = profile.MacroFactory or self:GetDefaults()
    self.db = profile.MacroFactory
end

function MacroFactory:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.MacroFactory = profile.MacroFactory or self:GetDefaults()
    self.db = profile.MacroFactory
end

function MacroFactory:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
    end)
end

-- Confirmation shown before an existing macro gets overwritten.
StaticPopupDialogs["ITRULIAQOL_MACRO_OVERRIDE"] = {
    text = "A macro named \"%s\" already exists.\n\nDo you want to overwrite it?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        local d = self.data

        if d and d.onAccept then
            d.onAccept()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Writes the macro into an existing slot, or creates a new one when slotIndex is nil.
function MacroFactory:WriteMacro(name, body, perCharacter, icon, slotIndex)
    if InCombatLockdown() then
        ItruliaQoL:Print("|cffff0000Can't create macros in combat.|r")
        return
    end

    local ok, err = pcall(function()
        if slotIndex then
            EditMacro(slotIndex, name, icon, body)
        else
            CreateMacro(name, icon, body, perCharacter)
        end
    end)

    if not ok then
        ItruliaQoL:Print("|cffff0000Failed to create macro|r " .. name .. ": " .. tostring(err))
    end
end

-- Creates a macro, asking the player to confirm before overwriting one that already exists.
function MacroFactory:CreateOrUpdateMacro(name, body, perCharacter, icon)
    if InCombatLockdown() then
        ItruliaQoL:Print("|cffff0000Can't create macros in combat.|r")
        return
    end

    icon = icon or 134400

    local slotIndex = GetMacroIndexByName(name)

    if slotIndex and slotIndex > 0 then
        StaticPopup_Show("ITRULIAQOL_MACRO_OVERRIDE", name, nil, {
            onAccept = function()
                self:WriteMacro(name, body, perCharacter, icon, slotIndex)
            end,
        })

        return
    end

    self:WriteMacro(name, body, perCharacter, icon)
end

function MacroFactory:GetClassInterruptSpellNames()
    local specs = ItruliaQoL.interruptSpells[ItruliaQoL.PlayerClass]

    if not specs then
        return {}
    end

    local specIds = {}
    for specId in pairs(specs) do
        table.insert(specIds, specId)
    end
    table.sort(specIds)

    local names, seen = {}, {}
    for _, specId in ipairs(specIds) do
        local spellId = specs[specId]
        local name = spellId and C_Spell.GetSpellName(spellId)

        if name and not seen[name] then
            seen[name] = true
            table.insert(names, name)
        end
    end

    return names
end

-- Builds a /cast line for the player's interrupt(s). Classes whose interrupt
-- differs by spec get a [known:spellName] clause per spell so a single macro
-- covers every spec; classes with one interrupt just cast it directly.
function MacroFactory:BuildInterruptCast(conditions)
    local names = self:GetClassInterruptSpellNames()

    if #names == 0 then
        return nil
    end

    if #names == 1 then
        if conditions then
            return ("/cast [%s] %s"):format(conditions, names[1])
        end

        return "/cast " .. names[1]
    end

    local clauses = {}
    for _, name in ipairs(names) do
        local cond = conditions and (conditions .. ",known:" .. name) or ("known:" .. name)
        table.insert(clauses, ("[%s] %s"):format(cond, name))
    end

    return "/cast " .. table.concat(clauses, "; ")
end