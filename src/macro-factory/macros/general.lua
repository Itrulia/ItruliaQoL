local addonName, ItruliaQoL = ...
local moduleName = "MacroFactory"
local MacroFactory = ItruliaQoL:GetModule(moduleName)

-- Extra Action Button
MacroFactory:RegisterMacro({
    group = "General",
    name = "Extra Action Button",
    icon = [[Interface\ICONS\INV_Misc_QuestionMark]],
    create = function(name)
        local body = table.concat({
            "/click ExtraActionButton1",
            "/click ExtraActionButton2",
        }, "\n")

        MacroFactory:CreateOrUpdateMacro(name, body, false)
    end
})

-- Focus Kick
MacroFactory:RegisterMacro({
    group = "All Classes",
    name = "Focus Kick",
    desc = "Macro that kicks your focus target if it's set and else tab targets to the next casting mob, kicks and then tabs back",
    icon = function() 
        return ItruliaQoL:GetInterruptSpell() 
    end,
    create = function(name)
        local focusCast = MacroFactory:BuildInterruptCast("@focus,harm")
        local tabCast = MacroFactory:BuildInterruptCast()

        if not focusCast then
            return
        end

        local body = table.concat({
            "#showtooltip",
            focusCast,
            "/stopmacro [@focus,exists]",
            "/cleartarget",
            "/targetenemy",
            tabCast,
            "/targetlasttarget",
        }, "\n")

        MacroFactory:CreateOrUpdateMacro(name, body, true)
    end
})

-- Tab Kick
MacroFactory:RegisterMacro({
    group = "All Classes",
    name = "Tab Kick",
    desc = "Macro that tab targets to the next casting mob, kicks and then tabs back",
    icon = function()
        return ItruliaQoL:GetInterruptSpell() 
    end,
    create = function(name)
        local tabCast = MacroFactory:BuildInterruptCast()

        if not tabCast then
            return
        end

        local body = table.concat({
            "#showtooltip",
            "/cleartarget",
            "/targetenemy",
            tabCast,
            "/targetlasttarget",
        }, "\n")

        MacroFactory:CreateOrUpdateMacro(name, body, true)
    end
})

-- Battle Rez
MacroFactory:RegisterMacro({
    group = "All Classes",
    name = "Battle Rez",
    icon = function() return ItruliaQoL:GetBattleRezSpell() end,
    create = function(name)
        local spellId = ItruliaQoL:GetBattleRezSpell()
        local spell = spellId and C_Spell.GetSpellName(spellId)

        if not spell then
            return
        end

        local body = table.concat({
            "#showtooltip",
            "/cast [@mouseover, dead, help][] " .. spell,
        }, "\n")

        MacroFactory:CreateOrUpdateMacro(name, body, true)
    end
})
