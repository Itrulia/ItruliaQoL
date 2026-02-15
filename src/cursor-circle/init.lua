local addonName, ItruliaQoL = ...
local moduleName = "CursorCircle"
local E = ItruliaQoL.E

local CursorCircle = ItruliaQoL:NewModule(moduleName)

CursorCircle.CursorTextures = {
    ["Interface\\AddOns\\ItruliaQoL\\media\\textures\\ItruliaCircleThin.tga"] = "Thin",
    ["Interface\\AddOns\\ItruliaQoL\\media\\textures\\ItruliaCircleMedium.tga"] = "Medium",
    ["Interface\\AddOns\\ItruliaQoL\\media\\textures\\ItruliaCircleThick.tga"] = "Thick",
}

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER")
frame:SetFrameStrata("TOOLTIP")
frame:SetFrameLevel(100)
frame:SetClampedToScreen(true)
frame:Hide()

frame.texture = frame:CreateTexture("$parent_Texture", "OVERLAY")
frame.texture:SetAllPoints(frame)

function frame:UpdateStyles()
    self:SetSize(CursorCircle.db.size, CursorCircle.db.size)
    self.texture:SetTexture(CursorCircle.db.displayTexture)
    self.texture:SetVertexColor(CursorCircle.db.color.r, CursorCircle.db.color.g, CursorCircle.db.color.b, CursorCircle.db.color.a)
end

local previousX, previousY
local function OnUpdate(self)
    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x, y = floor(x / scale + 0.5), floor(y / scale + 0.5)

    if x ~= previousX or y ~= previousY then
        previousX = x
        previousY = y
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    end
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
        frame:Show()
        frame:UpdateStyles()
        frame:SetScript("OnUpdate", OnUpdate)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
    end
end

function CursorCircle:OnEnable()
    if self.db.enabled then 
        frame:Show()
        frame:UpdateStyles()
        frame:SetScript("OnUpdate", OnUpdate)
    end
end

function CursorCircle:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end)
end