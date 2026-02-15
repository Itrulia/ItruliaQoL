local addonName, ItruliaQoL = ...
local moduleName = "FocusTargetMarker"
local LSM = ItruliaQoL.LSM

local FocusTargetMarker = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)

frame.targetMarkerText = {
    [1] = 'Star',
    [2] = 'Circle',
    [3] = 'Diamond',
    [4] = 'Triangle',
    [5] = 'Moon',
    [6] = 'Square',
    [7] = 'Cross',
    [8] = 'Skull',
}

function frame:WriteMacro(marker)
    if InCombatLockdown() then
        return
    end

    local macroName = moduleName
    local icon = 132219 -- rogue kick icon
    local content = "/focus [@mouseover, harm, nodead][]\n/tm [@mouseover, harm, nodead][] " .. marker

    local ok, err = pcall(function()
        local slotIndex = GetMacroIndexByName(macroName)
        
        if slotIndex and slotIndex > 0 then
            EditMacro(slotIndex, macroName, icon, content)
        else
            CreateMacro(macroName, icon, content, nil)
        end
    end)
end


local function OnEvent(self, event, ...)
    self:WriteMacro(FocusTargetMarker.db.marker);

    if event == "READY_CHECK" then
        if not FocusTargetMarker.db.announce then
            return
        end

        local inInstance, instanceType = IsInInstance()
        if not inInstance or instanceType ~= "party" or InCombatLockdown() then
            return
        end

        local markerName = frame.targetMarkerText[FocusTargetMarker.db.marker]
        local message = ("My kick marker is {%s}"):format(markerName)

        C_ChatInfo.SendChatMessage(message, "PARTY")
    end;
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("READY_CHECK")

function FocusTargetMarker:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.FocusTargetMarker = profile.FocusTargetMarker or self:GetDefaults()
    self.db = profile.FocusTargetMarker
end

function FocusTargetMarker:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.FocusTargetMarker = profile.FocusTargetMarker or self:GetDefaults()
    self.db = profile.FocusTargetMarker

    if self.db.enabled then
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
    end
end

function FocusTargetMarker:OnEnable()
    if self.db.enabled then
        frame:SetScript("OnEvent", OnEvent)
    end
end

function FocusTargetMarker:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        OnEvent(frame)
    end)
end