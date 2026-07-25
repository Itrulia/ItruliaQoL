local addonName, ItruliaQoL = ...
local moduleName = "FriendlyNameplates"
local LSM = ItruliaQoL.LSM

local FriendlyNameplates = ItruliaQoL:NewModule(moduleName)

-- Let the UI frameworks handle this
if ItruliaQoL.EUI or ItruliaQoL.E then
    return
end

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)

local function OnEvent()
    _G.SystemFont_NamePlate:SetFont(LSM:Fetch("font", FriendlyNameplates.db.font.fontFamily), FriendlyNameplates.db.font.fontSize, FriendlyNameplates.db.font.fontOutline)
    _G.SystemFont_NamePlate_Outlined:SetFont(LSM:Fetch("font", FriendlyNameplates.db.font.fontFamily), FriendlyNameplates.db.font.fontSize, FriendlyNameplates.db.font.fontOutline)
    SetCVar("nameplateUseClassColorForFriendlyPlayerUnitNames", 1)
    SetCVar("UnitNameFriendlyPlayerName", 1)
    SetCVar("nameplateShowFriendlyPlayers", 1)
    SetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits", 1)
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")

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
        frame:SetScript("OnEvent", OnEvent)
        OnEvent(frame)
    else
        frame:SetScript("OnEvent", nil)
    end
end

function FriendlyNameplates:OnEnable()
    if self.db.enabled then
        frame:SetScript("OnEvent", OnEvent)
    end
end

function FriendlyNameplates:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        OnEvent(frame)
    end)
end