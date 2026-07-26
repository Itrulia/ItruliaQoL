local addonName, ItruliaQoL = ...

local moduleName = "DeathAlert"
local DeathAlert = ItruliaQoL:GetModule(moduleName)

function DeathAlert:PreparePreview(f)
    f.text.anim:Stop()

    local name = UnitName("player")
    local _, class = UnitClass("player")
    local classColor = C_ClassColor.GetClassColor(class)

    local displayText = CreateColor(
        self.db.color.r,
        self.db.color.g,
        self.db.color.b,
        self.db.color.a
    ):WrapTextInColorCode(self.db.displayText)

    f.text:SetText(classColor:WrapTextInColorCode(name) .. " " .. displayText)
    f.text:SetAlpha(1)
    f:UpdateStyles()
end
