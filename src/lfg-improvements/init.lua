local addonName, ItruliaQoL = ...
local moduleName = "LFGImprovements"

local LFGImprovements = ItruliaQoL:NewModule(moduleName)

-- The live frame hangs off the module as LFGImprovements.frame, so anything holding the
-- module can reach it. Nil until the module is first enabled; see EnsureFrame.

local function OnEvent(self, event, ...)
    if LFGImprovements.db.groupJoinedReminder.enabled then
        if event == "GROUP_LEFT" then
            self.groupName = nil
        end

        if event == "LFG_LIST_JOINED_GROUP" then
            local _, groupName = ...
            self.groupName = groupName
        end

        if event == "LFG_LIST_JOINED_GROUP" or event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
            local created = ...
            if not created then
                return
            end

            local entryData = C_LFGList.GetActiveEntryInfo()
            if not entryData then
                return
            end

            local activityId = nil
            for _, id in ipairs(entryData.activityIDs) do
                activityId = id
                break;
            end

            if not activityId then
                return
            end

            local activityInfo = C_LFGList.GetActivityInfoTable(activityId)
            if not activityInfo or (not activityInfo.isMythicPlusActivity and not activityInfo.isMythicActivity) then
                return
            end

            local fullName = activityInfo.fullName .. " " .. (self.groupName or "")
            ItruliaQoL:Print("Joined: " .. fullName)
        end
    end
end

-- Builds the module's frame.
--
-- This module draws nothing -- the frame is purely an event listener for the group
-- joined reminder -- but it is still built here rather than at file scope so nothing
-- exists until the module is actually enabled (see RefreshConfig).
--
-- Deliberately registers no events; those belong to the live instance only, and are
-- wired in EnsureFrame.
function LFGImprovements:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)
    f.groupName = nil

    return f
end

-- Returns the live instance, building it on the first call and reusing it after that.
function LFGImprovements:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("GROUP_LEFT")
    f:RegisterEvent("LFG_LIST_JOINED_GROUP")
    f:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")

    return f
end

function LFGImprovements:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.LFGImprovements = profile.LFGImprovements or self:GetDefaults()
    self.db = profile.LFGImprovements
end

function LFGImprovements:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.LFGImprovements = profile.LFGImprovements or self:GetDefaults()
    self.db = profile.LFGImprovements

    if self.db.enabled then
        self:EnsureFrame():SetScript("OnEvent", OnEvent)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
    end
end

function LFGImprovements:OnEnable()
    -- Stays wired regardless of the module's state: this is a script on a Blizzard
    -- button, not on our frame, so there is nothing to create lazily. It checks
    -- db.enabled itself -- without that the role check would still auto-accept with
    -- the whole module switched off.
    LFDRoleCheckPopupAcceptButton:SetScript("OnShow", function()
        if self.db.enabled and self.db.autoAcceptRole.enabled then
            LFDRoleCheckPopupAcceptButton:Click()
        end
    end)

    self:RefreshConfig()
end

function LFGImprovements:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
    end)
end
