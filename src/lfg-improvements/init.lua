local addonName, ItruliaQoL = ...
local moduleName = "LFGImprovements"

local LFGImprovements = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame.groupName = nil

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

frame:RegisterEvent("GROUP_LEFT")
frame:RegisterEvent("LFG_LIST_JOINED_GROUP")
frame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")

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
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
    end
end

function LFGImprovements:OnEnable()
    LFDRoleCheckPopupAcceptButton:SetScript("OnShow", function()
        if self.db.autoAcceptRole.enabled then
            LFDRoleCheckPopupAcceptButton:Click()
        end
    end)

    self:RefreshConfig()
end

function LFGImprovements:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
    end)
end
