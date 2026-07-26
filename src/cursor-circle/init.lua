local addonName, ItruliaQoL = ...
local moduleName = "CursorCircle"
local E = ItruliaQoL.E

local CursorCircle = ItruliaQoL:NewModule(moduleName)

CursorCircle.CursorTextures = {
    ["Interface\\AddOns\\ItruliaQoL\\media\\textures\\ItruliaCircleThin.tga"] = "Thin",
    ["Interface\\AddOns\\ItruliaQoL\\media\\textures\\ItruliaCircleMedium.tga"] = "Medium",
    ["Interface\\AddOns\\ItruliaQoL\\media\\textures\\ItruliaCircleThick.tga"] = "Thick",
}

local function OnUpdate(self)
    if CursorCircle.db.onlyDuringCombat and not PlayerIsInCombat() then
        self:SetAlpha(0)
        return
    end

    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x, y = floor(x / scale + 0.5), floor(y / scale + 0.5)

    if x ~= self.previousX or y ~= self.previousY then
        self.previousX = x
        self.previousY = y
        self:SetAlpha(1)
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    end
end

function CursorCircle:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)
    f:SetPoint("CENTER")
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:Hide()

    f.texture = f:CreateTexture("$parent_Texture", "OVERLAY")
    f.texture:SetAllPoints(f)

    function f:UpdateStyles()
        self:SetSize(CursorCircle.db.size, CursorCircle.db.size)
        self.texture:SetTexture(CursorCircle.db.displayTexture)
        self.texture:SetVertexColor(CursorCircle.db.color.r, CursorCircle.db.color.g, CursorCircle.db.color.b, CursorCircle.db.color.a)
    end

    return f
end

function CursorCircle:EnsureFrame()
    if self.frame then
        return self.frame
    end

    self.frame = self:GenerateFrame(addonName .. moduleName)

    return self.frame
end

function CursorCircle:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile[moduleName] = profile[moduleName] or self:GetDefaults()
    self.db = profile[moduleName]
end

function CursorCircle:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile[moduleName] = profile[moduleName] or self:GetDefaults()
    self.db = profile[moduleName]

    if self.db.enabled then
        local f = self:EnsureFrame()

        f:Show()
        f:UpdateStyles()
        f:SetScript("OnUpdate", OnUpdate)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
        self.frame:SetScript("OnUpdate", nil)
        self.frame:Hide()
    end
end

function CursorCircle:OnEnable()
    self:RefreshConfig()
end

function CursorCircle:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
        end

        ItruliaQoL:RefreshPreview(self)
    end)
end
