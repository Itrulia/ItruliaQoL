local addonName, ItruliaQoL = ...
local moduleName = "FocusTargetMarker"
local LSM = ItruliaQoL.LSM

local FocusTargetMarker = ItruliaQoL:NewModule(moduleName)

local TARGET_MARKER_TEXT = {
    [1] = 'Star',
    [2] = 'Circle',
    [3] = 'Diamond',
    [4] = 'Triangle',
    [5] = 'Moon',
    [6] = 'Square',
    [7] = 'Cross',
    [8] = 'Skull',
}

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

        local markerName = self.targetMarkerText[FocusTargetMarker.db.marker]
        local message = ("My kick marker is {%s}"):format(markerName)

        C_ChatInfo.SendChatMessage(message, "PARTY")
    end;
end

function FocusTargetMarker:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)

    f.targetMarkerText = TARGET_MARKER_TEXT

    function f:WriteMacro(marker)
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

    return f
end

function FocusTargetMarker:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("READY_CHECK")

    return f
end

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
        local f = self:EnsureFrame()

        f:SetScript("OnEvent", OnEvent)
        OnEvent(f)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
    end
end

function FocusTargetMarker:OnEnable()
    self:RefreshConfig()
end

function FocusTargetMarker:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            OnEvent(self.frame)
        end
    end)
end
