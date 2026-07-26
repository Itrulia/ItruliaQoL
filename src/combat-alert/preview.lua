local addonName, ItruliaQoL = ...

local moduleName = "CombatAlert"
local CombatAlert = ItruliaQoL:GetModule(moduleName)

function CombatAlert:PreparePreview(f)
    f.text.anim:Stop()
    f.text:SetText(self.db.combatStartsText)
    f.text:SetTextColor(self.db.combatStartsColor.r, self.db.combatStartsColor.g, self.db.combatStartsColor.b, self.db.combatStartsColor.a)
    f.text:SetAlpha(1)
    f:UpdateStyles()
end
