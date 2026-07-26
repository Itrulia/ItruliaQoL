local addonName, ItruliaQoL = ...

local moduleName = "FlyingBar"
local FlyingBar = ItruliaQoL:GetModule(moduleName)

function FlyingBar:PreparePreview(f)
    f:SetAlpha(1)
    f:Show()

    for index, bar in ipairs(f.vigor) do
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(index < #f.vigor and 1 or 0.35)
    end

    for index, bar in ipairs(f.secondWind) do
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(index < #f.secondWind and 1 or 0)
    end

    f.speed:SetValue(select(2, f.speed:GetMinMaxValues()) / 2)
end
