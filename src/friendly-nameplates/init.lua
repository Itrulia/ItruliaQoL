local addonName, ItruliaQoL = ...
local moduleName = "FriendlyNameplates"
local LSM = ItruliaQoL.LSM

local FriendlyNameplates = ItruliaQoL:NewModule(moduleName)

-- Let the UI frameworks handle this
if ItruliaQoL.EUI or ItruliaQoL.E then
    return
end

local function OnEvent()
    _G.SystemFont_NamePlate:SetFont(LSM:Fetch("font", FriendlyNameplates.db.font.fontFamily), FriendlyNameplates.db.font.fontSize, FriendlyNameplates.db.font.fontOutline)
    _G.SystemFont_NamePlate_Outlined:SetFont(LSM:Fetch("font", FriendlyNameplates.db.font.fontFamily), FriendlyNameplates.db.font.fontSize, FriendlyNameplates.db.font.fontOutline)
    SetCVar("nameplateUseClassColorForFriendlyPlayerUnitNames", 1)
    SetCVar("UnitNameFriendlyPlayerName", 1)
    SetCVar("nameplateShowFriendlyPlayers", 1)
    SetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits", 1)
end

function FriendlyNameplates:GenerateFrame(name, parent)
    return CreateFrame("frame", name, parent or UIParent)
end

function FriendlyNameplates:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("PLAYER_ENTERING_WORLD")

    return f
end

function FriendlyNameplates:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.FriendlyNameplates = profile.FriendlyNameplates or self:GetDefaults()
    self.db = profile.FriendlyNameplates
end

function FriendlyNameplates:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.FriendlyNameplates = profile.FriendlyNameplates or self:GetDefaults()
    self.db = profile.FriendlyNameplates

    if self.db.enabled then
        local f = self:EnsureFrame()

        f:SetScript("OnEvent", OnEvent)
        OnEvent(f)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
    end
end

function FriendlyNameplates:OnEnable()
    self:RefreshConfig()
end

function FriendlyNameplates:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            OnEvent(self.frame)
        end
    end)
end
