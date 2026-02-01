local addonName, ItruliaQoL = ...
local moduleName = "FocusTargetMarker"
local LSM = ItruliaQoL.LSM

local FocusTargetMarker = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", UIParent, 0, 150)
frame:SetSize(28, 28)
frame.active = false
frame.interruptId = nil

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetTextColor(1, 1, 1)
frame.text:SetJustifyH("CENTER")
frame.text:SetText("INTERRUPT")
frame.text:Hide()

local function RaidMarkerString(index)
    local table = {
        [1] = {0.00, 0.25, 0.00, 0.25}, -- Star
        [2] = {0.25, 0.50, 0.00, 0.25}, -- Circle
        [3] = {0.50, 0.75, 0.00, 0.25}, -- Diamond
        [4] = {0.75, 1.00, 0.00, 0.25}, -- Triangle
        [5] = {0.00, 0.25, 0.25, 0.50}, -- Moon
        [6] = {0.25, 0.50, 0.25, 0.50}, -- Square
        [7] = {0.50, 0.75, 0.25, 0.50}, -- Cross
        [8] = {0.75, 1.00, 0.25, 0.50}, -- Skull
    }
    local left, right, top, bottom = unpack(table[index])

    return string.format(
        "|TInterface\\TargetingFrame\\UI-RaidTargetingIcons:16:16:0:0:256:256:%d:%d:%d:%d|t %s",
        left * 256, right * 256, top * 256, bottom * 256,
        _G["RAID_TARGET_" .. index]
    )
end

frame.targetMarkers = {
    [1] = RaidMarkerString(1),
    [2] = RaidMarkerString(2),
    [3] = RaidMarkerString(3),
    [4] = RaidMarkerString(4),
    [5] = RaidMarkerString(5),
    [6] = RaidMarkerString(6),
    [7] = RaidMarkerString(7),
    [8] = RaidMarkerString(8),
}

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

local defaults = {
    enabled = true,
    announce = true,
    marker = 5,
};

function FocusTargetMarker:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.FocusTargetMarker = profile.FocusTargetMarker or defaults
    self.db = profile.FocusTargetMarker
end

function FocusTargetMarker:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.FocusTargetMarker = profile.FocusTargetMarker or defaults
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

local options = {
    type = "group",
    name = "Focus Marker",
    args = {
        description = {
            type = "description",
            name =  "Creates a macro called FocusTargetMarker which automatically marks your mouseover or target with the configured raid marker\n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function() 
                return FocusTargetMarker.db.enabled
            end,
            set = function(_, value)
                FocusTargetMarker.db.enabled = value
                FocusTargetMarker:RefreshConfig()
            end,
        },
        announce = {
            order = 3,
            type = "toggle",
            width = "full",
            name = "Announce on ready check",
            get = function() 
                return FocusTargetMarker.db.announce
            end,
            set = function(_, value)
                FocusTargetMarker.db.announce = value
            end,
        },
         marker = {
            order = 4,
            type = "select",
            name = "Focus Marker",
            values = frame.targetMarkers,
            style = "dropdown",
            get = function()
                return FocusTargetMarker.db.marker
            end,
            set = function(_, value)
                FocusTargetMarker.db.marker = value
                OnEvent(frame);
            end,
        },
    }
}

function FocusTargetMarker:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = options;
end